// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/queue/queue_command.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/shared/domain/queue_item.dart';

/// What the playback controller does with the engine after a reducer step.
enum QueueEffect {
  /// Nothing; the current item is unchanged.
  none,

  /// Load and play the new current item.
  loadCurrent,

  /// Play the current item again from the start.
  restartCurrent,

  /// Stop playback.
  stop,
}

/// The result of one reducer step: the next [state] and the [effect] the
/// controller applies to the engine.
class QueueTransition {
  /// Creates a transition.
  const new(this.state, this.effect);

  /// The queue after the command.
  final QueueState state;

  /// What the controller does with the engine.
  final QueueEffect effect;
}

/// The pure queue rules of doc 06 (Queue Model): turns a [QueueCommand] into
/// the next [QueueState] and a [QueueEffect].
///
/// A command that changes nothing returns the identical input instance, and
/// `revision` increases by one exactly when the state changes. Commands
/// naming an unknown `queueItemId` change nothing. Adding a `queueItemId`
/// that is already queued throws [ArgumentError].
class QueueReducer {
  /// Creates the reducer.
  const new();

  /// Applies [command] to [state].
  QueueTransition reduce(QueueState state, QueueCommand command) =>
      switch (command) {
        ReplaceAll(:final items, :final startIndex, :final context) =>
          _replaceAll(state, items, startIndex, context),
        PlayNext(:final items) => _playNext(state, items),
        Append(:final items) => _append(state, items),
        RemoveAt(:final queueItemId) => _removeAt(state, queueItemId),
        Move(:final queueItemId, :final toPlayIndex) => _move(
          state,
          queueItemId,
          toPlayIndex,
        ),
        JumpTo(:final queueItemId) => _jumpTo(state, queueItemId),
        Next() => _next(state),
        Clear() => _clear(state),
        ItemFinished(:final queueItemId) => _itemFinished(state, queueItemId),
      };

  QueueTransition _replaceAll(
    QueueState state,
    List<QueueItem> items,
    int startIndex,
    QueueContext? context,
  ) {
    if (items.isEmpty) return _clear(state);
    _checkUnique(const [], items);
    return _step(
      state,
      QueueState(
        items: items,
        cursor: startIndex.clamp(0, items.length - 1),
        repeat: state.repeat,
        context: context,
        revision: state.revision,
      ),
      QueueEffect.loadCurrent,
    );
  }

  QueueTransition _playNext(QueueState state, List<QueueItem> items) {
    final cursor = state.cursor;
    if (cursor == null || state.items.isEmpty) {
      return _replaceAll(state, items, 0, null);
    }
    _checkUnique(state.items, items);
    final insertAt = state.playOrder[cursor] + 1;
    return _step(
      state,
      state.copyWith(items: [...state.items]..insertAll(insertAt, items)),
      QueueEffect.none,
    );
  }

  QueueTransition _append(QueueState state, List<QueueItem> items) {
    if (state.cursor == null || state.items.isEmpty) {
      return _playNext(state, items);
    }
    _checkUnique(state.items, items);
    return _step(
      state,
      state.copyWith(items: [...state.items, ...items]),
      QueueEffect.none,
    );
  }

  QueueTransition _removeAt(QueueState state, String queueItemId) {
    final index = _playIndexOf(state, queueItemId);
    final cursor = state.cursor;
    if (index == null || cursor == null) return _none(state);
    if (state.items.length == 1) return _clear(state);

    final items = [...state.items]..removeAt(state.playOrder[index]);
    if (index != cursor) {
      final next = index < cursor ? cursor - 1 : cursor;
      return _step(
        state,
        state.copyWith(items: items, cursor: next),
        QueueEffect.none,
      );
    }
    // Removing the current entry advances to the following one first; when
    // it was the last, the new last entry becomes current and playback stops.
    final wasLast = cursor == state.items.length - 1;
    return _step(
      state,
      state.copyWith(items: items, cursor: wasLast ? cursor - 1 : cursor),
      wasLast ? QueueEffect.stop : QueueEffect.loadCurrent,
    );
  }

  QueueTransition _move(QueueState state, String queueItemId, int toIndex) {
    final index = _playIndexOf(state, queueItemId);
    final current = state.current;
    if (index == null || current == null) return _none(state);

    final items = [...state.items];
    final moved = items.removeAt(index);
    items.insert(toIndex.clamp(0, items.length), moved);
    final cursor = items.indexWhere(
      (item) => item.queueItemId == current.queueItemId,
    );
    return _step(
      state,
      state.copyWith(items: items, cursor: cursor),
      QueueEffect.none,
    );
  }

  QueueTransition _jumpTo(QueueState state, String queueItemId) {
    final index = _playIndexOf(state, queueItemId);
    if (index == null) return _none(state);
    if (index == state.cursor) {
      return QueueTransition(state, QueueEffect.restartCurrent);
    }
    return _step(state, state.copyWith(cursor: index), QueueEffect.loadCurrent);
  }

  QueueTransition _next(QueueState state) {
    final cursor = state.cursor;
    if (cursor == null || cursor >= state.items.length - 1) {
      return _none(state);
    }
    return _step(
      state,
      state.copyWith(cursor: cursor + 1),
      QueueEffect.loadCurrent,
    );
  }

  QueueTransition _clear(QueueState state) => _step(
    state,
    QueueState(repeat: state.repeat, revision: state.revision),
    QueueEffect.stop,
  );

  QueueTransition _itemFinished(QueueState state, String queueItemId) {
    final cursor = state.cursor;
    if (cursor == null || state.current?.queueItemId != queueItemId) {
      return _none(state);
    }
    // End of the queue with repeat off: stop, the cursor stays on the last
    // item.
    if (cursor >= state.items.length - 1) {
      return QueueTransition(state, QueueEffect.stop);
    }
    return _step(
      state,
      state.copyWith(cursor: cursor + 1),
      QueueEffect.loadCurrent,
    );
  }

  /// Returns [state] itself when [next] equals it, else [next] with the
  /// revision increased by one. [next] carries [state]'s revision.
  QueueTransition _step(QueueState state, QueueState next, QueueEffect effect) {
    if (next == state) return QueueTransition(state, effect);
    return QueueTransition(next.copyWith(revision: state.revision + 1), effect);
  }

  QueueTransition _none(QueueState state) =>
      QueueTransition(state, QueueEffect.none);

  /// The play index of the entry [queueItemId], or null when it is not
  /// queued.
  int? _playIndexOf(QueueState state, String queueItemId) {
    final order = state.playOrder;
    for (var i = 0; i < order.length; i++) {
      if (state.items[order[i]].queueItemId == queueItemId) return i;
    }
    return null;
  }

  /// Throws [ArgumentError] when [added] repeats a `queueItemId` of
  /// [existing] or of itself.
  void _checkUnique(List<QueueItem> existing, List<QueueItem> added) {
    final seen = {for (final item in existing) item.queueItemId};
    for (final item in added) {
      if (!seen.add(item.queueItemId)) {
        throw ArgumentError.value(
          item.queueItemId,
          'queueItemId',
          'is already in the queue',
        );
      }
    }
  }
}
