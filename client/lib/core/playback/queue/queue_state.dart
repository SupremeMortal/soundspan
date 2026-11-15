// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundspan/shared/domain/queue_item.dart';

part 'queue_state.freezed.dart';

/// How the queue repeats (doc 06, Queue Model).
enum RepeatMode {
  /// Play the queue once and stop at the end.
  off,

  /// Start again from the first item after the last.
  all,

  /// Replay the current item.
  one,
}

/// The play queue: canonical items, optional shuffle permutation and the
/// cursor into play order (doc 06, Queue Model).
@freezed
abstract class QueueState with _$QueueState {
  /// Creates a queue state.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory QueueState({
    /// The entries in canonical (unshuffled) order.
    @Default(<QueueItem>[]) List<QueueItem> items,

    /// A permutation of indices into [items] when shuffle is on.
    List<int>? shuffleOrder,

    /// Index into [playOrder] of the current item; null when empty.
    int? cursor,

    /// The repeat mode.
    @Default(RepeatMode.off) RepeatMode repeat,

    /// What "Play" was pressed on.
    QueueContext? context,

    /// Incremented by one on every change.
    @Default(0) int revision,
  }) = _QueueState;

  // freezed needs a private constructor for the getters below.
  // ignore: unnecessary_type_name_in_constructor
  const QueueState._();

  /// The empty queue.
  factory empty() => const QueueState();

  /// Indices into [items] in the order they play: [shuffleOrder] when set,
  /// else the identity.
  List<int> get playOrder =>
      shuffleOrder ?? List<int>.generate(items.length, (i) => i);

  /// Whether a shuffle order is set.
  bool get isShuffled => shuffleOrder != null;

  /// The item at [cursor], or null when the queue is empty.
  QueueItem? get current => _itemAtPlayIndex(cursor);

  /// The item after [current] in play order, or null at the end or when the
  /// queue is empty.
  QueueItem? get upNext {
    final at = cursor;
    return at == null ? null : _itemAtPlayIndex(at + 1);
  }

  QueueItem? _itemAtPlayIndex(int? playIndex) {
    final order = playOrder;
    if (playIndex == null || playIndex < 0 || playIndex >= order.length) {
      return null;
    }
    return items[order[playIndex]];
  }
}
