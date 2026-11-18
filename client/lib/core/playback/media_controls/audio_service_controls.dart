// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The `audio_service` adapter of the OS media controls (doc 06, OS Media
/// Controls): the Android notification and lock screen, Now Playing on iOS
/// and macOS, the Media Session API on the web and MPRIS on Linux.
///
/// It translates [MediaSessionState] into what `audio_service` shows and
/// its buttons into [MediaCommandHandler] calls; it holds no playback state
/// and owns no engine (Spike S3 finding). The plugin itself is started
/// through an [AudioServiceStarter], so everything here runs without it.
library;

import 'dart:async';

import 'package:audio_service/audio_service.dart' as svc;
import 'package:soundspan/core/playback/media_controls/browse/browse_tree.dart';
import 'package:soundspan/core/playback/media_controls/media_controls.dart';
import 'package:soundspan/shared/clock.dart';

/// The Android notification channel of playback (doc 10, Playback
/// service).
const String playbackChannelId = 'io.soundspan.app.playback';

/// The MPRIS bus name prefix on Linux. `audio_service_mpris` requests
/// `<prefix>.instance<pid>`, built from the channel id it is given.
const String mprisBusNamePrefix = 'org.mpris.MediaPlayer2.$_mprisName';

/// The MPRIS player name: the channel id and the identity
/// `audio_service_mpris` derives from the config on Linux.
const String _mprisName = 'soundspan';

/// The skip interval the OS controls step by when they skip on their own.
const Duration _skipInterval = Duration(seconds: 15);

/// The name of the custom Like action of the Android notification.
const String likeActionName = 'like';

/// The custom action `audio_service_mpris` sends when an MPRIS client sets
/// the volume, with the volume (0.0–1.0) as its `value` extra.
const String mprisVolumeActionName = 'dbusVolume';

/// Shows the user volume where the surface has one (MPRIS on Linux).
typedef VolumePublisher = void Function(double volume);

/// How long playback may stay paused before the handler stops it, which
/// ends the Android playback service and removes its notification (doc
/// 06, Background Behaviour by Platform).
const Duration pausedServiceTimeout = Duration(minutes: 10);

/// The label of the Like action: what pressing it does, for an item shown
/// [liked] or not.
typedef LikeLabel = String Function(bool liked);

/// The localized titles of the Android Auto browse root, read each time
/// the root is listed.
typedef BrowseTitles = BrowseRootTitles Function();

/// Starts `audio_service` with the handler [builder] makes and [config],
/// returning that handler. Called once per process.
typedef AudioServiceStarter = Future<SoundspanAudioHandler> Function(
  SoundspanAudioHandler Function() builder,
  svc.AudioServiceConfig config,
);

/// The `audio_service` configuration of [operatingSystem] (a value of
/// `Platform.operatingSystem`, or `web`).
///
/// [channelName] is the localized name of the Android notification channel.
/// On Linux `audio_service_mpris` derives the bus name from the channel id
/// and the MPRIS identity from the channel name, so both are `soundspan`
/// there.
svc.AudioServiceConfig audioServiceConfigFor({
  required String operatingSystem,
  required String channelName,
}) {
  final linux = operatingSystem == 'linux';
  return svc.AudioServiceConfig(
    androidNotificationChannelId: linux ? _mprisName : playbackChannelId,
    androidNotificationChannelName: linux ? _mprisName : channelName,
    // androidStopForegroundOnPause keeps its default, true, which an
    // ongoing notification requires.
    androidNotificationOngoing: true,
    androidNotificationIcon: 'drawable/ic_stat_soundspan',
    fastForwardInterval: _skipInterval,
    rewindInterval: _skipInterval,
  );
}

/// The `audio_service` handler: every button is forwarded to [commands].
///
/// It holds no playback state; what it shows is published to it through
/// [show] by [AudioServiceControls.update]. `click` keeps its default,
/// which pauses or plays from the last published playing flag. The Like
/// action asks for the opposite of the liked flag last shown, and an MPRIS
/// volume change sets the user volume.
///
/// After [pausedServiceTimeout] continuously paused it calls [stop]. [stop]
/// shows the idle state, which ends the Android service and removes the
/// notification; paused states are not shown again until one is playing.
///
/// With [browseTitles] (Android) it serves the Android Auto browse tree
/// over [MediaCommandHandler.browseSource] and, for its Downloads root,
/// [MediaCommandHandler.browseDownloads] (doc 10, Android Auto): only
/// downloads carry artwork, a playable id or a voice search plays through
/// [MediaCommandHandler.playRequest], and an id or search with nothing to
/// play leaves playback unchanged. Without a source the tree is empty.
class SoundspanAudioHandler extends svc.BaseAudioHandler
    with svc.QueueHandler, svc.SeekHandler {
  /// Creates a handler forwarding to [commands]; [browseTitles] titles
  /// the Android Auto browse root.
  new(this.commands, {this.browseTitles});

  /// Where the buttons go.
  final MediaCommandHandler commands;

  /// The titles of the Android Auto browse root; null serves no tree.
  final BrowseTitles? browseTitles;

  Timer? _pausedTimer;
  bool _ended = false;
  bool? _liked;

  /// Shows [item] and [state]; [liked] is the liked flag the Like action,
  /// if any, shows.
  void show(svc.MediaItem? item, svc.PlaybackState state, {bool? liked}) {
    if (_ended && !state.playing) return;
    _ended = false;
    _liked = liked;
    mediaItem.add(item);
    playbackState.add(state);
    if (item != null && !state.playing) {
      _pausedTimer ??= Timer(pausedServiceTimeout, () {
        _pausedTimer = null;
        unawaited(stop());
      });
    } else {
      _cancelPausedTimer();
    }
  }

  void _cancelPausedTimer() {
    _pausedTimer?.cancel();
    _pausedTimer = null;
  }

  @override
  Future<void> play() {
    _cancelPausedTimer();
    return commands.play();
  }

  @override
  Future<void> pause() => commands.pause();

  @override
  Future<void> stop() async {
    _cancelPausedTimer();
    _ended = true;
    await commands.stop();
    mediaItem.add(null);
    playbackState.add(
      svc.PlaybackState(updateTime: playbackState.value.updateTime),
    );
  }

  @override
  Future<void> seek(Duration position) => commands.seek(position);

  @override
  Future<void> skipToNext() => commands.next();

  @override
  Future<void> skipToPrevious() => commands.previous();

  @override
  Future<void> fastForward() => commands.skipForward();

  @override
  Future<void> rewind() => commands.skipBackward();

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    if (name == mprisVolumeActionName) {
      if (extras?['value'] case final num volume) {
        await commands.setVolume(volume.toDouble());
      }
      return;
    }
    final liked = _liked;
    if (name != likeActionName || liked == null) return;
    await commands.setLiked(!liked);
  }

  BrowseTree? _tree() {
    final titles = browseTitles;
    final source = commands.browseSource;
    if (titles == null || source == null) return null;
    return BrowseTree(
      source: source,
      titles: titles(),
      downloads: commands.browseDownloads,
    );
  }

  @override
  Future<List<svc.MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async => _itemsOf(await _tree()?.children(parentMediaId));

  @override
  Future<List<svc.MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) async => _itemsOf(await _tree()?.searchResults(query));

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) => _play(_tree()?.resolve(mediaId));

  @override
  Future<void> playFromSearch(String query, [Map<String, dynamic>? extras]) =>
      _play(_tree()?.search(query));

  Future<void> _play(Future<PlayRequest?>? pending) async {
    final request = await pending;
    if (request == null) return;
    _cancelPausedTimer();
    await commands.playRequest(request);
  }

  static List<svc.MediaItem> _itemsOf(List<BrowseNode>? nodes) => [
    for (final node in nodes ?? const <BrowseNode>[])
      svc.MediaItem(
        id: node.id,
        title: node.title,
        artist: node.subtitle,
        album: node.album,
        duration: node.duration,
        artUri: node.artUri,
        playable: node.playable,
      ),
  ];
}

/// What `audio_service` shows for [state]: the media item (null for
/// [MediaSessionState.empty]) and the playback state, positioned at
/// [updateTime].
///
/// The buttons are previous, play or pause, and next; an item with skip
/// actions and no next (a single episode) gets rewind and fast-forward in
/// place of previous and next. With both, the skips sit between them in
/// the expanded notification and previous, play/pause and next stay
/// compact.
///
/// With a [likeLabel] (Android), an item offering [MediaAction.like] also
/// gets the custom Like control after the others, outlined or filled by
/// [MediaSessionState.liked]; it is never compact.
(svc.MediaItem?, svc.PlaybackState) audioServiceStateOf(
  MediaSessionState state, {
  required DateTime updateTime,
  LikeLabel? likeLabel,
}) {
  final id = state.queueItemId;
  if (id == null) {
    return (null, svc.PlaybackState(updateTime: updateTime));
  }
  final actions = state.actions;
  final skips =
      actions.contains(MediaAction.skipForward) ||
      actions.contains(MediaAction.skipBackward);
  final playPause = actions.contains(MediaAction.pause)
      ? svc.MediaControl.pause
      : actions.contains(MediaAction.play)
      ? svc.MediaControl.play
      : null;
  final previous = actions.contains(MediaAction.previous)
      ? svc.MediaControl.skipToPrevious
      : null;
  final next = actions.contains(MediaAction.next)
      ? svc.MediaControl.skipToNext
      : null;
  final rewind = actions.contains(MediaAction.skipBackward)
      ? svc.MediaControl.rewind
      : null;
  final forward = actions.contains(MediaAction.skipForward)
      ? svc.MediaControl.fastForward
      : null;
  final compact = <svc.MediaControl?>[
    if (skips && next == null) rewind else previous,
    playPause,
    if (skips && next == null) forward else next,
  ];
  final like = likeLabel != null && actions.contains(MediaAction.like)
      ? svc.MediaControl.custom(
          androidIcon: state.liked
              ? 'drawable/ic_action_liked'
              : 'drawable/ic_action_like',
          label: likeLabel(state.liked),
          name: likeActionName,
        )
      : null;
  final controls = <svc.MediaControl>[
    ?compact[0],
    if (skips && next != null) ?rewind,
    ?playPause,
    if (skips && next != null) ?forward,
    ?compact[2],
    ?like,
  ];
  final item = svc.MediaItem(
    id: id,
    title: state.title,
    artist: state.artist,
    album: state.album.isEmpty ? null : state.album,
    duration: state.duration,
    artUri: state.artworkUri,
  );
  return (
    item,
    svc.PlaybackState(
      processingState: state.buffering
          ? svc.AudioProcessingState.buffering
          : svc.AudioProcessingState.ready,
      playing: state.playing,
      controls: controls,
      androidCompactActionIndices: [
        for (final c in compact)
          if (c != null) controls.indexOf(c),
      ],
      systemActions: {
        if (actions.contains(MediaAction.seek)) svc.MediaAction.seek,
        if (actions.contains(MediaAction.stop)) svc.MediaAction.stop,
      },
      updatePosition: state.position,
      updateTime: updateTime,
      speed: state.speed,
    ),
  );
}

/// [MediaControls] over `audio_service`.
final class AudioServiceControls implements MediaControls {
  /// Creates the controls; `start` starts the plugin with `config` at
  /// [init], and `clock` stamps every published position. With a
  /// `likeLabel` (Android) the Like action is shown, with `browseTitles`
  /// (Android) the Android Auto browse tree is served, and with
  /// `publishVolume` (Linux) the volume of every state is shown.
  new({
    required this._config,
    required this._start,
    required this._clock,
    this._likeLabel,
    this._browseTitles,
    this._publishVolume,
  });

  final svc.AudioServiceConfig Function() _config;
  final AudioServiceStarter _start;
  final Clock _clock;
  final LikeLabel? _likeLabel;
  final BrowseTitles? _browseTitles;
  final VolumePublisher? _publishVolume;
  SoundspanAudioHandler? _handler;

  @override
  Future<void> init(MediaCommandHandler handler) async {
    _handler = await _start(
      () => SoundspanAudioHandler(handler, browseTitles: _browseTitles),
      _config(),
    );
  }

  @override
  void update(MediaSessionState state) {
    final handler = _handler;
    if (handler == null) return;
    _publish(handler, state);
  }

  @override
  Future<void> dispose() async {
    final handler = _handler;
    _handler = null;
    if (handler != null) _publish(handler, MediaSessionState.empty);
  }

  void _publish(SoundspanAudioHandler handler, MediaSessionState state) {
    final (item, playback) = audioServiceStateOf(
      state,
      updateTime: _clock.now(),
      likeLabel: _likeLabel,
    );
    handler.show(
      item,
      playback,
      liked: playback.controls.any((c) => c.customAction != null)
          ? state.liked
          : null,
    );
    _publishVolume?.call(state.volume);
  }
}
