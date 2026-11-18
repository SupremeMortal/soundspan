// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The Windows adapter of the OS media controls (doc 06, OS Media Controls;
/// Spike S4 finding): the System Media Transport Controls, media keys and
/// the volume flyout, through an [SmtcGateway].
library;

import 'dart:async';

import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/media_controls/media_controls.dart';
import 'package:soundspan/core/playback/media_controls/smtc_gateway.dart';
import 'package:soundspan/shared/clock.dart';

final AppLogger _log = AppLogger.scope('MediaControls');

/// How often the timeline is resent while playing, so the flyout's
/// position stays in step.
const Duration smtcTimelineInterval = Duration(seconds: 5);

/// [MediaControls] over the Windows System Media Transport Controls.
///
/// It holds no playback state of its own: it shows the last
/// [MediaSessionState] it was given and remembers only what it sent, so
/// that metadata goes out when it changes.
final class SmtcControls implements MediaControls {
  /// Creates the controls; the clock places the timeline sent between
  /// updates.
  new({required this._gateway, required this._clock});

  final SmtcGateway _gateway;
  final Clock _clock;
  final List<StreamSubscription<Object>> _subscriptions = [];
  Timer? _timeline;
  bool _ready = false;
  bool _disposed = false;
  (String, String, String, Uri?)? _metadata;

  @override
  Future<void> init(MediaCommandHandler handler) async {
    await _gateway.init();
    if (_disposed) return;
    _subscriptions
      ..add(
        _gateway.buttonPresses.listen(
          (button) => _call(switch (button) {
            SmtcButton.play => handler.play,
            SmtcButton.pause => handler.pause,
            SmtcButton.next => handler.next,
            SmtcButton.previous => handler.previous,
            SmtcButton.stop => handler.stop,
            SmtcButton.fastForward => handler.skipForward,
            SmtcButton.rewind => handler.skipBackward,
          }),
        ),
      )
      ..add(
        _gateway.seekRequests.listen(
          (position) => _call(() => handler.seek(position)),
        ),
      );
    _ready = true;
  }

  @override
  void update(MediaSessionState state) {
    if (!_ready || _disposed) return;
    _timeline?.cancel();
    _timeline = null;
    if (state.queueItemId == null) {
      _metadata = null;
      _send(_gateway.clear());
      _send(_gateway.setStatus(SmtcStatus.closed));
      return;
    }
    _send(_gateway.setEnabledButtons(smtcButtonsFor(state.actions)));
    final metadata = (state.title, state.artist, state.album, state.artworkUri);
    if (metadata != _metadata) {
      _metadata = metadata;
      _send(
        _gateway.setMetadata(
          title: state.title,
          artist: state.artist,
          album: state.album,
          thumbnail: state.artworkUri,
        ),
      );
    }
    _send(
      _gateway.setStatus(
        state.buffering
            ? SmtcStatus.changing
            : state.playing
            ? SmtcStatus.playing
            : SmtcStatus.paused,
      ),
    );
    _send(
      _gateway.setTimeline(position: state.position, duration: state.duration),
    );
    if (state.playing && !state.buffering) {
      final sentAt = _clock.now();
      _timeline = Timer.periodic(smtcTimelineInterval, (_) {
        final elapsed = _clock.now().difference(sentAt) * state.speed;
        var position = state.position + elapsed;
        final duration = state.duration;
        if (duration != null && position > duration) position = duration;
        _send(_gateway.setTimeline(position: position, duration: duration));
      });
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _ready = false;
    _timeline?.cancel();
    _timeline = null;
    // Cancelling takes effect at once; the futures carry no result.
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    await _gateway.dispose();
  }

  void _call(Future<void> Function() command) => _send(command());

  void _send(Future<void> call) {
    unawaited(
      call.catchError((Object error, StackTrace stack) {
        _log.warning('SMTC call failed', const {}, error, stack);
      }),
    );
  }
}

/// The flyout buttons enabled for [actions]: play and pause together when
/// either is offered (the media key toggles between them), next, previous,
/// stop, and fast forward and rewind for the skip actions.
Set<SmtcButton> smtcButtonsFor(Set<MediaAction> actions) => {
  if (actions.contains(MediaAction.play) ||
      actions.contains(MediaAction.pause)) ...[
    SmtcButton.play,
    SmtcButton.pause,
  ],
  if (actions.contains(MediaAction.next)) SmtcButton.next,
  if (actions.contains(MediaAction.previous)) SmtcButton.previous,
  if (actions.contains(MediaAction.stop)) SmtcButton.stop,
  if (actions.contains(MediaAction.skipForward)) SmtcButton.fastForward,
  if (actions.contains(MediaAction.skipBackward)) SmtcButton.rewind,
};
