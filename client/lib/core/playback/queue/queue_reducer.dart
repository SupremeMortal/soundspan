// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math';

import 'package:soundspan/core/playback/queue/queue_command.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/playback/queue/shuffle_order.dart';
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
  const new(this.state, this.effect, {this.dropped = 0});

  /// The queue after the command.
  final QueueState state;

  /// What the controller does with the engine.
  final QueueEffect effect;

  /// How many of the command's items were left out because the queue holds
  /// at most [QueueReducer.maxItems].
  final int dropped;
}

/// The pure queue rules of doc 06 (Queue Model): turns a [QueueCommand] into
/// the next [QueueState] and a [QueueEffect].
///
/// A command that changes nothing returns the identical input instance, and
/// `revision` increases by one exactly when the state changes. Commands
/// naming an unknown `queueItemId` change nothing. Adding a `queueItemId`
/// that is already queued throws [ArgumentError].
///
/// Shuffling draws from the injected [Random], so the reducer is
/// deterministic for a given seed and call sequence.
class QueueReducer {
  /// Creates the reducer. Tests pass a seeded `random`; production passes
  /// nothing and shuffles with a fresh `Random()`.
  const new({this._random});

  /// The most items the queue holds.
  static const int maxItems = 5000;

  /// [Previous] restarts the current entry once it has played for longer
  /// than this, and moves back otherwise.
  static const Duration previousRestartThreshold = Duration(seconds: 3);

  static final Random _defaultRandom = Random();

  final Random? _random;

  Random get _rng => _random ?? _defaultRandom;

  /// Applies [command] to [state].
  QueueTransition reduce(QueueState state, QueueCommand command) =>
      switch (command) {
        ReplaceAll(:final items, :final startIndex, :final context) =>
          _replaceAll(state, items, startIndex, context),
        PlayNext(:final items) => _playNext(state, items),
        Append(:final items) => _append(state, items),
        InsertAt(:final items, :final playOrderIndex) => _insertAt(
          state,
          items,
          playOrderIndex,
        ),
        RemoveAt(:final queueItemId) => _removeAt(state, queueItemId),
        Move(:final queueItemId, :final toPlayIndex) => _move(
          state,
          queueItemId,
          toPlayIndex,
        ),
        JumpTo(:final queueItemId) => _jumpTo(state, queueItemId),
        Next() => _next(state),
        Previous(:final position) => _previous(state, position),
        SetShuffle(:final enabled) => _setShuffle(state, enabled),
        SetRepeat(:final mode) => _setRepeat(state, mode),
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
    var start = startIndex.clamp(0, items.length - 1);
    var window = items;
    if (items.length > maxItems) {
      // The first maxItems, slid forward only as far as keeping the start
      // item needs.
      final from = max(0, start - (maxItems - 1));
      window = items.sublist(from, from + maxItems);
      start -= from;
    }
    _checkUnique(const [], window);
    final shuffled = state.isShuffled;
    return _step(
      state,
      QueueState(
        items: window,
        shuffleOrder: shuffled
            ? shuffleStartingAt(window.length, start, _rng)
            : null,
        cursor: shuffled ? 0 : start,
        repeat: state.repeat,
        context: context,
        revision: state.revision,
      ),
      QueueEffect.loadCurrent,
      dropped: items.length - window.length,
    );
  }

  QueueTransition _playNext(QueueState state, List<QueueItem> items) {
    final cursor = state.cursor;
    if (cursor == null || state.items.isEmpty) {
      return _replaceAll(state, items, 0, null);
    }
    final added = _fitting(state, items);
    final dropped = items.length - added.length;
    if (added.isEmpty) return _none(state, dropped: dropped);
    _checkUnique(state.items, added);
    final order = state.playOrder;
    final insertAt = order[cursor] + 1;
    final shuffleOrder = state.shuffleOrder == null
        ? null
        : (renumberForInsert(order, insertAt, added.length)..insertAll(
            cursor + 1,
            List<int>.generate(added.length, (i) => insertAt + i),
          ));
    return _step(
      state,
      state.copyWith(
        items: [...state.items]..insertAll(insertAt, added),
        shuffleOrder: shuffleOrder,
      ),
      QueueEffect.none,
      dropped: dropped,
    );
  }

  QueueTransition _append(QueueState state, List<QueueItem> items) {
    final cursor = state.cursor;
    if (cursor == null || state.items.isEmpty) {
      return _playNext(state, items);
    }
    final added = _fitting(state, items);
    final dropped = items.length - added.length;
    if (added.isEmpty) return _none(state, dropped: dropped);
    _checkUnique(state.items, added);
    List<int>? shuffleOrder;
    final current = state.shuffleOrder;
    if (current != null) {
      // Each new index lands at a random play position after the cursor.
      shuffleOrder = [...current];
      for (var i = 0; i < added.length; i++) {
        final position =
            cursor + 1 + _rng.nextInt(shuffleOrder.length - cursor);
        shuffleOrder.insert(position, state.items.length + i);
      }
    }
    return _step(
      state,
      state.copyWith(
        items: [...state.items, ...added],
        shuffleOrder: shuffleOrder,
      ),
      QueueEffect.none,
      dropped: dropped,
    );
  }

  QueueTransition _insertAt(
    QueueState state,
    List<QueueItem> items,
    int playOrderIndex,
  ) {
    final cursor = state.cursor;
    if (cursor == null || state.items.isEmpty) {
      return _playNext(state, items);
    }
    final added = _fitting(state, items);
    final dropped = items.length - added.length;
    if (added.isEmpty) return _none(state, dropped: dropped);
    _checkUnique(state.items, added);
    final at = playOrderIndex.clamp(0, state.items.length);
    // The current entry keeps playing: an insert at or before it moves it.
    final next = at <= cursor ? cursor + added.length : cursor;
    final current = state.shuffleOrder;
    if (current == null) {
      return _step(
        state,
        state.copyWith(
          items: [...state.items]..insertAll(at, added),
          cursor: next,
        ),
        QueueEffect.none,
        dropped: dropped,
      );
    }
    return _step(
      state,
      state.copyWith(
        items: [...state.items, ...added],
        shuffleOrder: [...current]
          ..insertAll(
            at,
            List<int>.generate(added.length, (i) => state.items.length + i),
          ),
        cursor: next,
      ),
      QueueEffect.none,
      dropped: dropped,
    );
  }

  QueueTransition _removeAt(QueueState state, String queueItemId) {
    final index = _playIndexOf(state, queueItemId);
    final cursor = state.cursor;
    if (index == null || cursor == null) return _none(state);
    if (state.items.length == 1) return _clear(state);

    final order = state.playOrder;
    final items = [...state.items]..removeAt(order[index]);
    final shuffleOrder = state.isShuffled
        ? removeFromOrder(order, index)
        : null;
    if (index != cursor) {
      final next = index < cursor ? cursor - 1 : cursor;
      return _step(
        state,
        state.copyWith(items: items, shuffleOrder: shuffleOrder, cursor: next),
        QueueEffect.none,
      );
    }
    // Removing the current entry advances to the following one first. When
    // it was the last, repeat all wraps to the first entry; otherwise the
    // new last entry becomes current and playback stops.
    final wasLast = cursor == state.items.length - 1;
    final wraps = wasLast && state.repeat == RepeatMode.all;
    return _step(
      state,
      state.copyWith(
        items: items,
        shuffleOrder: shuffleOrder,
        cursor: wraps ? 0 : (wasLast ? cursor - 1 : cursor),
      ),
      wasLast && !wraps ? QueueEffect.stop : QueueEffect.loadCurrent,
    );
  }

  QueueTransition _move(QueueState state, String queueItemId, int toIndex) {
    final index = _playIndexOf(state, queueItemId);
    final cursor = state.cursor;
    if (index == null || cursor == null) return _none(state);

    final shuffleOrder = state.shuffleOrder;
    if (shuffleOrder != null) {
      // Shuffled: only the play order changes.
      final currentIndex = shuffleOrder[cursor];
      final order = [...shuffleOrder];
      final moved = order.removeAt(index);
      order.insert(toIndex.clamp(0, order.length), moved);
      return _step(
        state,
        state.copyWith(
          shuffleOrder: order,
          cursor: order.indexOf(currentIndex),
        ),
        QueueEffect.none,
      );
    }

    final current = state.items[cursor];
    final items = [...state.items];
    final moved = items.removeAt(index);
    items.insert(toIndex.clamp(0, items.length), moved);
    final next = items.indexWhere(
      (item) => item.queueItemId == current.queueItemId,
    );
    return _step(
      state,
      state.copyWith(items: items, cursor: next),
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
    if (cursor == null) return _none(state);
    if (cursor >= state.items.length - 1) {
      return state.repeat == RepeatMode.all ? _wrap(state) : _none(state);
    }
    return _step(
      state,
      state.copyWith(cursor: cursor + 1),
      QueueEffect.loadCurrent,
    );
  }

  QueueTransition _previous(QueueState state, Duration position) {
    final cursor = state.cursor;
    if (cursor == null) return _none(state);
    if (position > previousRestartThreshold) {
      return QueueTransition(state, QueueEffect.restartCurrent);
    }
    if (cursor > 0) {
      return _step(
        state,
        state.copyWith(cursor: cursor - 1),
        QueueEffect.loadCurrent,
      );
    }
    // At the first entry only repeat all wraps, to the last entry.
    if (state.repeat == RepeatMode.all && state.items.length > 1) {
      return _step(
        state,
        state.copyWith(cursor: state.items.length - 1),
        QueueEffect.loadCurrent,
      );
    }
    return QueueTransition(state, QueueEffect.restartCurrent);
  }

  QueueTransition _setShuffle(QueueState state, bool enabled) {
    if (enabled == state.isShuffled) return _none(state);
    final cursor = state.cursor;
    if (enabled) {
      // Unshuffled, the cursor is the canonical index: everything up to it
      // keeps its order and the rest is shuffled.
      return _step(
        state,
        state.copyWith(
          shuffleOrder: cursor == null
              ? const []
              : shuffleAfter(state.items.length, cursor, _rng),
        ),
        QueueEffect.none,
      );
    }
    return _step(
      state,
      state.copyWith(
        shuffleOrder: null,
        cursor: cursor == null ? null : state.playOrder[cursor],
      ),
      QueueEffect.none,
    );
  }

  QueueTransition _setRepeat(QueueState state, RepeatMode mode) =>
      _step(state, state.copyWith(repeat: mode), QueueEffect.none);

  QueueTransition _clear(QueueState state) => _step(
    state,
    QueueState(
      shuffleOrder: state.isShuffled ? const [] : null,
      repeat: state.repeat,
      revision: state.revision,
    ),
    QueueEffect.stop,
  );

  QueueTransition _itemFinished(QueueState state, String queueItemId) {
    final cursor = state.cursor;
    if (cursor == null || state.current?.queueItemId != queueItemId) {
      return _none(state);
    }
    if (state.repeat == RepeatMode.one) {
      return QueueTransition(state, QueueEffect.restartCurrent);
    }
    if (cursor >= state.items.length - 1) {
      // End of the queue: repeat all wraps; repeat off stops with the cursor
      // on the last item.
      return state.repeat == RepeatMode.all
          ? _wrap(state)
          : QueueTransition(state, QueueEffect.stop);
    }
    return _step(
      state,
      state.copyWith(cursor: cursor + 1),
      QueueEffect.loadCurrent,
    );
  }

  /// Wraps from the last entry to play index 0 without reshuffling; a
  /// single entry restarts.
  QueueTransition _wrap(QueueState state) {
    if (state.cursor == 0) {
      return QueueTransition(state, QueueEffect.restartCurrent);
    }
    return _step(state, state.copyWith(cursor: 0), QueueEffect.loadCurrent);
  }

  /// Returns [state] itself when [next] equals it, else [next] with the
  /// revision increased by one. [next] carries [state]'s revision.
  QueueTransition _step(
    QueueState state,
    QueueState next,
    QueueEffect effect, {
    int dropped = 0,
  }) {
    if (next == state) {
      return QueueTransition(state, effect, dropped: dropped);
    }
    return QueueTransition(
      next.copyWith(revision: state.revision + 1),
      effect,
      dropped: dropped,
    );
  }

  QueueTransition _none(QueueState state, {int dropped = 0}) =>
      QueueTransition(state, QueueEffect.none, dropped: dropped);

  /// The leading [items] that still fit under [maxItems].
  List<QueueItem> _fitting(QueueState state, List<QueueItem> items) {
    final room = max(0, maxItems - state.items.length);
    return items.length <= room ? items : items.sublist(0, room);
  }

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
