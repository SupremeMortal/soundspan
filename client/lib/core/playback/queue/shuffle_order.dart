// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math';

/// Shuffles [values] in place with Fisher-Yates using [random].
void fisherYates(List<int> values, Random random) {
  for (var i = values.length - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final swap = values[i];
    values[i] = values[j];
    values[j] = swap;
  }
}

/// The identity order of [length] indices with everything after [keep]
/// shuffled: indices `0..keep` stay in place.
List<int> shuffleAfter(int length, int keep, Random random) {
  final tail = List<int>.generate(length - keep - 1, (i) => keep + 1 + i);
  fisherYates(tail, random);
  return [for (var i = 0; i <= keep; i++) i, ...tail];
}

/// [first] followed by every other index below [length], shuffled.
List<int> shuffleStartingAt(int length, int first, Random random) {
  final rest = [
    for (var i = 0; i < length; i++)
      if (i != first) i,
  ];
  fisherYates(rest, random);
  return [first, ...rest];
}

/// [order] after [count] canonical entries were inserted at canonical index
/// [at]: indices at or above [at] move up by [count]. The new indices are
/// not added.
List<int> renumberForInsert(List<int> order, int at, int count) => [
  for (final index in order)
    if (index >= at) index + count else index,
];

/// [order] without its entry at play index [playIndex], with the canonical
/// indices above the removed one moved down by one.
List<int> removeFromOrder(List<int> order, int playIndex) {
  final removed = order[playIndex];
  return [
    for (var i = 0; i < order.length; i++)
      if (i != playIndex)
        if (order[i] > removed) order[i] - 1 else order[i],
  ];
}
