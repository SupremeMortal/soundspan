// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/features/player/player.dart';

const List<LyricLine> _lines = [
  LyricLine(time: Duration(seconds: 1), text: 'one'),
  LyricLine(time: Duration(seconds: 2), text: 'two'),
  LyricLine(time: Duration(seconds: 4), text: 'three'),
];

void main() {
  test('null before the first line', () {
    expect(currentLineIndex(_lines, Duration.zero), isNull);
    expect(currentLineIndex(_lines, const Duration(milliseconds: 999)), isNull);
  });

  test('a line exactly on its timestamp is current', () {
    expect(currentLineIndex(_lines, const Duration(seconds: 1)), 0);
    expect(currentLineIndex(_lines, const Duration(seconds: 2)), 1);
    expect(currentLineIndex(_lines, const Duration(seconds: 4)), 2);
  });

  test('between lines the earlier one is current', () {
    expect(currentLineIndex(_lines, const Duration(milliseconds: 1500)), 0);
    expect(currentLineIndex(_lines, const Duration(seconds: 3)), 1);
  });

  test('after the last line the last one stays current', () {
    expect(currentLineIndex(_lines, const Duration(minutes: 10)), 2);
  });

  test('of two lines with one timestamp the later is current', () {
    const lines = [
      LyricLine(time: Duration(seconds: 1), text: 'first'),
      LyricLine(time: Duration(seconds: 2), text: 'same a'),
      LyricLine(time: Duration(seconds: 2), text: 'same b'),
      LyricLine(time: Duration(seconds: 3), text: 'last'),
    ];
    expect(currentLineIndex(lines, const Duration(seconds: 2)), 2);
    expect(currentLineIndex(lines, const Duration(milliseconds: 2500)), 2);
  });

  test('an empty list has no current line', () {
    expect(currentLineIndex(const [], Duration.zero), isNull);
    expect(currentLineIndex(const [], const Duration(hours: 1)), isNull);
  });
}
