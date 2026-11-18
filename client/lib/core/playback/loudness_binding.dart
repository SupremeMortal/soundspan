// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/core/playback/loudness.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/profile/settings/user_settings.dart';
import 'package:soundspan/shared/domain/queue_item.dart';

/// The [PlaybackController] volume factor the loudness gain is set as.
const String loudnessVolumeFactor = 'loudness';

/// Applies the loudness gain of each item as it becomes current (doc 06,
/// Loudness).
///
/// Whenever the controller's current entry changes (playing a list, a
/// jump, a skip, a gapless advance) the gain of the new entry is computed
/// with the levelling mode and loudness target of that moment and set as the
/// [loudnessVolumeFactor]. The gain never changes while an entry stays
/// current. Episodes and an empty queue get a factor of 1.0.
class LoudnessBinding {
  /// Starts following the snapshots of `controller`; `mode` and
  /// `targetLufs` are read whenever an item becomes current.
  new({
    required this._controller,
    required this._mode,
    required this._targetLufs,
  }) {
    _subscription = _controller.snapshots.listen(_onSnapshot);
  }

  final PlaybackController _controller;
  final LoudnessMode Function() _mode;
  final double Function() _targetLufs;
  late final StreamSubscription<PlaybackSnapshot> _subscription;

  bool _started = false;
  String? _currentId;

  void _onSnapshot(PlaybackSnapshot snapshot) {
    final item = snapshot.current;
    final id = item?.queueItemId;
    if (_started && id == _currentId) return;
    _started = true;
    _currentId = id;
    final gainDb = switch (item) {
      TrackQueueItem(:final track, :final context) => loudnessGainDb(
        mode: _mode(),
        loudness: track.loudness,
        contextKind: context.kind,
        targetLufs: _targetLufs(),
      ),
      EpisodeQueueItem() || null => 0.0,
    };
    _controller.setVolumeFactor(loudnessVolumeFactor, gainToLinear(gainDb));
  }

  /// Stops following the controller.
  Future<void> dispose() => _subscription.cancel();
}
