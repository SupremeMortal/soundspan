// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/playback_command.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/platform/audio_session/audio_session_gateway.dart';
import 'package:soundspan/shared/domain/queue_item.dart';

final AppLogger _log = AppLogger.scope('AudioFocus');

/// The audio-focus rules of one [PlaybackController] (doc 06, Audio Focus
/// and Interruptions): it asks the OS for focus before playback starts,
/// pauses for interruptions and resumes when that is right, ducks for a
/// transient request, pauses when the output becomes noisy, and gives
/// focus up when playback stops.
class AudioFocusController {
  /// Applies the rules to [_controller] over [_session] until [dispose].
  new(this._controller, this._session) {
    _controller.beforePlay = _requestFocus;
    _events = _session.events.listen(_onEvent);
    _snapshots = _controller.snapshots.listen(_onSnapshot);
  }

  /// The volume factor while ducked, where the OS does not duck itself.
  static const double duckFactor = 0.3;

  static const String _duckKey = 'duck';

  final PlaybackController _controller;
  final AudioSessionGateway _session;
  late final StreamSubscription<AudioSessionEvent> _events;
  late final StreamSubscription<PlaybackSnapshot> _snapshots;

  AudioFocusProfile? _profile;
  bool _active = false;
  bool _wasPlaying = false;
  bool _disposed = false;

  Future<bool> _requestFocus() async {
    final granted = await _session.setActive(true);
    _active = granted;
    return granted;
  }

  void _onEvent(AudioSessionEvent event) {
    if (_disposed) return;
    switch (event) {
      case InterruptionBegan():
        _wasPlaying = _controller.snapshot.playing;
        if (_wasPlaying) _pause();
      case InterruptionEnded(:final shouldResume):
        final resume =
            shouldResume &&
            _wasPlaying &&
            _controller.pauseOrigin == PauseOrigin.focus;
        _wasPlaying = false;
        if (resume) unawaited(_controller.play());
      case DuckBegan():
        if (!_session.osDucksItself) {
          _controller.setVolumeFactor(_duckKey, duckFactor);
        }
      case DuckEnded():
        _controller.setVolumeFactor(_duckKey, 1);
      case BecameNoisy():
        _wasPlaying = false;
        if (_controller.snapshot.playing) _pause();
    }
  }

  void _pause() => unawaited(_controller.pause(origin: PauseOrigin.focus));

  void _onSnapshot(PlaybackSnapshot _) {
    if (_disposed) return;
    // Snapshots arrive after the fact; the latest one decides, so an old
    // stopped snapshot delivered after a play never gives focus up.
    final snapshot = _controller.snapshot;
    final profile = switch (snapshot.current) {
      TrackQueueItem() => AudioFocusProfile.music,
      EpisodeQueueItem() => AudioFocusProfile.speech,
      null => null,
    };
    if (profile != null && profile != _profile) {
      _profile = profile;
      unawaited(_call(() => _session.configure(profile)));
    }
    final stopped =
        snapshot.current == null || snapshot.status == EngineStatus.idle;
    if (_active && !snapshot.playing && stopped) {
      _active = false;
      unawaited(_call(() => _session.setActive(false)));
    }
  }

  Future<void> _call(Future<Object?> Function() call) async {
    try {
      await call();
    } on Object catch (error, stackTrace) {
      _log.warning('An audio-session call failed', const {}, error, stackTrace);
    }
  }

  /// Stops applying the rules and removes the controller's focus hook.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_controller.beforePlay == _requestFocus) _controller.beforePlay = null;
    unawaited(_events.cancel());
    unawaited(_snapshots.cancel());
  }
}
