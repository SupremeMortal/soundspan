// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/media_controls/browse/browse_tree.dart';
import 'package:soundspan/core/playback/media_controls/browse/media_browse_source.dart';
import 'package:soundspan/core/playback/media_controls/media_controls.dart';
import 'package:soundspan/core/playback/media_controls/media_session_mapper.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan/shared/util/uuid.dart';

/// Gives the OS an artwork URI for a cover value; see `ArtworkPinner.pin`.
typedef ArtworkPin = Future<Uri?> Function(String? artworkRef);

/// Likes [track] when [liked] is true and removes its like otherwise; see
/// `PreferenceRepository.setTrackLiked`.
typedef LikeTrack = Future<void> Function(Track track, {required bool liked});

/// Connects one [PlaybackController] to the OS media surface in both
/// directions (doc 06, OS Media Controls).
///
/// It sends the mapped snapshot to the [MediaControls] when anything but
/// the position changes, or when the position departs by more than
/// [positionTolerance] from where the last state sent would be by now (a
/// seek or a stall). Steady playback sends nothing: the OS extrapolates.
///
/// When the current item changes, the new state is sent at once without
/// artwork, then, for an item with a cover, again with the pinned artwork
/// once it is ready, unless the current item has changed meanwhile.
///
/// As a [MediaCommandHandler] it dispatches the surface's buttons to the
/// controller. Like goes to [_like]: the current item is shown with the
/// new liked flag at once, until another item becomes current. A
/// [PlayRequest] of Android Auto replaces the queue, each track a fresh
/// entry.
class MediaControlsBinder implements MediaCommandHandler {
  /// Starts rendering [_controller]'s snapshots on [_controls]; artwork is
  /// pinned by [_pin], elapsed time read from [_clock], and likes stored
  /// through `like` (without it, Like does nothing). Android Auto browses
  /// [browseSource] and [browseDownloads].
  new({
    required this._controller,
    required this._controls,
    required this._pin,
    required this._clock,
    this._like,
    this.browseSource,
    this.browseDownloads,
  }) {
    _subscription = _controller.snapshots.listen(_onSnapshot);
  }

  /// How far the position may drift from its extrapolation before the state
  /// is sent again.
  static const Duration positionTolerance = Duration(milliseconds: 1500);

  static final AppLogger _log = AppLogger.scope('MediaControls');

  final PlaybackController _controller;
  final MediaControls _controls;
  final ArtworkPin _pin;
  final Clock _clock;
  final LikeTrack? _like;

  @override
  final MediaBrowseSource? browseSource;

  @override
  final DownloadsBrowse? browseDownloads;

  late final StreamSubscription<PlaybackSnapshot> _subscription;
  bool _started = false;
  bool _disposed = false;
  String? _currentId;
  Uri? _artworkUri;
  bool? _liked;
  MediaSessionState? _sent;
  DateTime? _sentAt;

  void _onSnapshot(PlaybackSnapshot snapshot) {
    final id = snapshot.current?.queueItemId;
    if (!_started || id != _currentId) {
      _started = true;
      _currentId = id;
      _artworkUri = null;
      _liked = null;
      _send(_map(snapshot));
      if (snapshot.current case final item?) {
        if (artworkRefOf(item) case final ref?) {
          unawaited(_pinArtwork(item.queueItemId, ref));
        }
      }
      return;
    }
    final state = _map(snapshot);
    if (_differs(state)) _send(state);
  }

  MediaSessionState _map(PlaybackSnapshot snapshot) =>
      mapSnapshot(snapshot, artworkUri: _artworkUri, liked: _liked);

  bool _differs(MediaSessionState state) {
    final sent = _sent;
    final sentAt = _sentAt;
    if (sent == null || sentAt == null) return true;
    if (state.copyWith(position: sent.position) != sent) return true;
    final elapsed = sent.playing && !sent.buffering
        ? _clock.now().difference(sentAt) * sent.speed
        : Duration.zero;
    final drift = state.position - (sent.position + elapsed);
    return drift.abs() > positionTolerance;
  }

  void _send(MediaSessionState state) {
    _sent = state;
    _sentAt = _clock.now();
    _controls.update(state);
  }

  Future<void> _pinArtwork(String queueItemId, String ref) async {
    Uri? uri;
    try {
      uri = await _pin(ref);
    } on Object catch (error, stackTrace) {
      _log.warning('Artwork was not pinned', const {}, error, stackTrace);
    }
    if (uri == null || _disposed || _currentId != queueItemId) return;
    _artworkUri = uri;
    _send(_map(_controller.snapshot));
  }

  /// Stops rendering the controller; nothing is sent from then on.
  Future<void> dispose() {
    _disposed = true;
    return _subscription.cancel();
  }

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> stop() => _controller.stop();

  @override
  Future<void> next() => _controller.next();

  @override
  Future<void> previous() => _controller.previous();

  @override
  Future<void> seek(Duration position) => _controller.seek(position);

  @override
  Future<void> skipForward() => _controller.skipForward();

  @override
  Future<void> skipBackward() => _controller.skipBackward();

  @override
  Future<void> setLiked(bool liked) async {
    final like = _like;
    final item = _controller.snapshot.current;
    if (like == null ||
        _disposed ||
        item is! TrackQueueItem ||
        item.track.playbackId == null ||
        item.queueItemId != _currentId) {
      return;
    }
    _liked = liked;
    _send(_map(_controller.snapshot));
    try {
      await like(item.track, liked: liked);
    } on Object catch (error, stackTrace) {
      _log.severe('Like not stored', const {}, error, stackTrace);
    }
  }

  @override
  Future<void> playRequest(PlayRequest request) async {
    if (_disposed || request.tracks.isEmpty) return;
    await _controller.playItems(
      [
        for (final track in request.tracks)
          QueueItem.track(
            queueItemId: Uuid.v4(),
            track: track,
            context: request.context,
          ),
      ],
      startIndex: request.startIndex,
      context: request.context,
    );
  }
}

/// The one [MediaCommandHandler] the OS media surface is initialised with,
/// forwarding to the [MediaControlsBinder] of the active profile.
///
/// [bind] replaces the binder when the active profile changes; with none
/// bound the surface shows [MediaSessionState.empty] and its buttons do
/// nothing.
class MediaControlsHost implements MediaCommandHandler {
  /// Creates the host of [_controls].
  new(this._controls);

  final MediaControls _controls;
  MediaControlsBinder? _binder;

  /// The binder buttons are forwarded to, if any.
  MediaControlsBinder? get binder => _binder;

  /// Stops the current binder and makes [binder] the one buttons go to;
  /// null shows [MediaSessionState.empty].
  Future<void> bind(MediaControlsBinder? binder) async {
    final previous = _binder;
    _binder = binder;
    if (binder == null) _controls.update(MediaSessionState.empty);
    await previous?.dispose();
  }

  @override
  Future<void> play() => _binder?.play() ?? Future<void>.value();

  @override
  Future<void> pause() => _binder?.pause() ?? Future<void>.value();

  @override
  Future<void> stop() => _binder?.stop() ?? Future<void>.value();

  @override
  Future<void> next() => _binder?.next() ?? Future<void>.value();

  @override
  Future<void> previous() => _binder?.previous() ?? Future<void>.value();

  @override
  Future<void> seek(Duration position) =>
      _binder?.seek(position) ?? Future<void>.value();

  @override
  Future<void> skipForward() => _binder?.skipForward() ?? Future<void>.value();

  @override
  Future<void> skipBackward() =>
      _binder?.skipBackward() ?? Future<void>.value();

  @override
  Future<void> setLiked(bool liked) =>
      _binder?.setLiked(liked) ?? Future<void>.value();

  @override
  MediaBrowseSource? get browseSource => _binder?.browseSource;

  @override
  DownloadsBrowse? get browseDownloads => _binder?.browseDownloads;

  @override
  Future<void> playRequest(PlayRequest request) =>
      _binder?.playRequest(request) ?? Future<void>.value();
}
