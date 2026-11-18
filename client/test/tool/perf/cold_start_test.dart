// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/perf/cold_start.dart';

/// The output of `adb shell am start -W` on API 34 with [totalMs].
String amStart(int totalMs, {String status = 'ok'}) =>
    '''
Starting: Intent { cmp=io.soundspan.app/.MainActivity }
Status: $status
LaunchState: COLD
Activity: io.soundspan.app/.MainActivity
TotalTime: $totalMs
WaitTime: ${totalMs + 9}
Complete
''';

/// The output of `am start -W` on older releases, with `ThisTime`.
String amStartLegacy(int totalMs) =>
    '''
Starting: Intent { cmp=io.soundspan.app/.MainActivity }
Status: ok
Activity: io.soundspan.app/.MainActivity
ThisTime: ${totalMs - 3}
TotalTime: $totalMs
WaitTime: ${totalMs + 20}
Complete
''';

void main() {
  group('parseTotalTime', () {
    test('reads TotalTime from am start -W output', () {
      expect(parseTotalTime(amStart(1834)), 1834);
      expect(parseTotalTime(amStartLegacy(912)), 912);
    });

    test('accepts CRLF line endings from adb shell', () {
      expect(parseTotalTime(amStart(700).replaceAll('\n', '\r\n')), 700);
    });

    test('a run without Status: ok fails', () {
      expect(
        () => parseTotalTime(amStart(900, status: 'timeout')),
        throwsFormatException,
      );
      expect(
        () => parseTotalTime(amStart(900).replaceFirst('Status: ok\n', '')),
        throwsFormatException,
      );
    });

    test('a run without TotalTime fails', () {
      expect(
        () => parseTotalTime(
          amStart(900).replaceFirst(RegExp(r'TotalTime: \d+\n'), ''),
        ),
        throwsFormatException,
      );
    });
  });

  group('checkColdStart', () {
    test('takes the median of five runs', () {
      final report = checkColdStart([
        amStart(2900),
        amStart(1200),
        amStart(4000),
        amStart(1500),
        amStart(1300),
      ], budgetMs: 3000);
      expect(report.medianMs, 1500);
      expect(report.ok, isTrue);
    });

    test('over budget fails', () {
      final report = checkColdStart([
        for (final ms in [3100, 3200, 2900, 3050, 3300]) amStart(ms),
      ], budgetMs: 3000);
      expect(report.medianMs, 3100);
      expect(report.ok, isFalse);
      expect(report.lines.join('\n'), contains('3100 ms'));
    });

    test('a run with Status: ok missing fails', () {
      final report = checkColdStart([
        amStart(1000),
        amStart(1000, status: 'timeout'),
        amStart(1000),
      ], budgetMs: 3000);
      expect(report.ok, isFalse);
      expect(report.lines.join('\n'), contains('run 2'));
    });

    test('no runs fail', () {
      expect(checkColdStart([], budgetMs: 3000).ok, isFalse);
    });
  });

  group('the command', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('cold_start'));
    tearDown(() => dir.deleteSync(recursive: true));

    List<String> write(List<int> times) => [
      for (var i = 0; i < times.length; i++)
        (File(
          '${dir.path}/run-$i.txt',
        )..writeAsStringSync(amStart(times[i]))).path,
    ];

    test('reads the budget from budgets.json', () {
      expect(
        runColdStart(write([2000, 2100, 2200, 2300, 2400]), out: (_) {}),
        0,
      );
      expect(
        runColdStart(write([3000, 3001, 3002, 3003, 3004]), out: (_) {}),
        1,
      );
    });

    test('exits 2 without files', () {
      expect(runColdStart([], out: (_) {}), 2);
    });
  });
}
