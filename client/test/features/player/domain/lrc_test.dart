// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/features/player/domain/lrc.dart';

LyricLine _line(int ms, String text) => LyricLine(
  time: Duration(milliseconds: ms),
  text: text,
);

void main() {
  group('parseLrc', () {
    final cases = <({String name, String source, List<LyricLine> lines})>[
      (
        name: 'two-digit fraction',
        source: '[00:12.34]Hello',
        lines: [_line(12340, 'Hello')],
      ),
      (
        name: 'three-digit fraction',
        source: '[01:02.345]Hello',
        lines: [_line(62345, 'Hello')],
      ),
      (
        name: 'one-digit fraction',
        source: '[00:01.5]Hello',
        lines: [_line(1500, 'Hello')],
      ),
      (
        name: 'colon as the fraction separator',
        source: '[00:01:25]Hello',
        lines: [_line(1250, 'Hello')],
      ),
      (
        name: 'no fraction',
        source: '[00:07]Hello',
        lines: [_line(7000, 'Hello')],
      ),
      (
        name: 'minutes above 59',
        source: '[75:00.00]Late',
        lines: [_line(75 * 60 * 1000, 'Late')],
      ),
      (
        name: 'several timestamps on one line',
        source: '[00:01.00][00:05.00]Chorus',
        lines: [_line(1000, 'Chorus'), _line(5000, 'Chorus')],
      ),
      (
        name: 'empty text is kept',
        source: '[00:01.00]One\n[00:02.00]\n[00:03.00]Three',
        lines: [_line(1000, 'One'), _line(2000, ''), _line(3000, 'Three')],
      ),
      (
        name: 'untimed line dropped',
        source: 'Just words\n[00:01.00]One',
        lines: [_line(1000, 'One')],
      ),
      (
        name: 'malformed timestamp dropped',
        source: '[00:xx.00]Bad\n[0a:01]Bad\n[00:61.00]Bad\n[00:01.00]Good',
        lines: [_line(1000, 'Good')],
      ),
      (
        name: 'tags ignored and offset not applied',
        source: '[ar:Artist]\n[ti:Title]\n[offset:500]\n[00:01.00]One',
        lines: [_line(1000, 'One')],
      ),
      (
        name: 'unsorted input sorted',
        source: '[00:03.00]Three\n[00:01.00]One\n[00:02.00]Two',
        lines: [_line(1000, 'One'), _line(2000, 'Two'), _line(3000, 'Three')],
      ),
      (
        name: 'CRLF and BOM',
        source: '﻿[00:01.00]One\r\n[00:02.00]Two\r\n',
        lines: [_line(1000, 'One'), _line(2000, 'Two')],
      ),
      (name: 'empty input', source: '', lines: []),
    ];

    for (final c in cases) {
      test(c.name, () => expect(parseLrc(c.source), c.lines));
    }

    test('text is trimmed', () {
      expect(parseLrc('[00:01.00]  spaced  '), [_line(1000, 'spaced')]);
    });
  });

  group('currentLineIndex', () {
    final lines = [_line(1000, 'One'), _line(2000, 'Two'), _line(3000, 'T')];

    final cases = <({String name, int ms, int? index})>[
      (name: 'before the first line', ms: 999, index: null),
      (name: 'exactly on a line', ms: 2000, index: 1),
      (name: 'between lines', ms: 2500, index: 1),
      (name: 'on the first line', ms: 1000, index: 0),
      (name: 'after the last line', ms: 60000, index: 2),
    ];

    for (final c in cases) {
      test(
        c.name,
        () => expect(
          currentLineIndex(lines, Duration(milliseconds: c.ms)),
          c.index,
        ),
      );
    }

    test('no lines', () {
      expect(currentLineIndex(const [], Duration.zero), isNull);
    });
  });
}
