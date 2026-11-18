// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/shared/clock.dart';

/// Publishes [PlaybackSnapshot]s to listeners: every change at once, except
/// that changes of the position alone reach listeners at most once per
/// [positionInterval] (doc 06, Controller Behaviour).
class SnapshotPublisher {
  /// Creates a publisher that times position updates with [_clock].
  new(this._clock);

  /// The shortest time between two position-only updates: four a second.
  static const Duration positionInterval = Duration(milliseconds: 250);

  final Clock _clock;
  final StreamController<PlaybackSnapshot> _changes =
      StreamController<PlaybackSnapshot>.broadcast();

  PlaybackSnapshot _latest = PlaybackSnapshot.initial;
  PlaybackSnapshot _emitted = PlaybackSnapshot.initial;
  DateTime? _emittedAt;
  Timer? _trailing;

  /// The latest snapshot, including a position not yet emitted.
  PlaybackSnapshot get latest => _latest;

  /// The snapshots; a new listener receives [latest] first.
  Stream<PlaybackSnapshot> get stream =>
      Stream<PlaybackSnapshot>.multi((listener) {
        if (_changes.isClosed) {
          unawaited(listener.close());
          return;
        }
        listener.add(_latest);
        final subscription = _changes.stream.listen(
          listener.add,
          onDone: listener.close,
        );
        listener.onCancel = subscription.cancel;
      });

  /// Makes [next] the latest snapshot and emits it, now or, when only its
  /// position changed, once [positionInterval] has passed since the last
  /// emission.
  void publish(PlaybackSnapshot next) {
    if (_changes.isClosed) return;
    _latest = next;
    final emittedAt = _emittedAt;
    if (emittedAt == null || !next.differsOnlyInPosition(_emitted)) {
      _emit();
      return;
    }
    if (next.position == _emitted.position &&
        next.buffered == _emitted.buffered) {
      return;
    }
    final since = _clock.now().difference(emittedAt);
    if (since >= positionInterval) {
      _emit();
    } else {
      _trailing ??= Timer(positionInterval - since, _emitTrailing);
    }
  }

  /// Stops emitting and closes [stream].
  Future<void> close() async {
    _trailing?.cancel();
    _trailing = null;
    await _changes.close();
  }

  void _emitTrailing() {
    _trailing = null;
    if (!identical(_latest, _emitted)) _emit();
  }

  void _emit() {
    _trailing?.cancel();
    _trailing = null;
    _emitted = _latest;
    _emittedAt = _clock.now();
    _changes.add(_latest);
  }
}
