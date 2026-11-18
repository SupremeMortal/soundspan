// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/perf/budgets.dart';
import '../../../tool/perf/check_frame_timings.dart';

const _budget = FrameBudget(buildP90Ms: 8, buildP99Ms: 16);

/// A `watchPerformance` summary with build times [p90] and [p99].
Map<String, Object?> summary({num p90 = 5, num p99 = 12}) => {
  'average_frame_build_time_millis': 3.2,
  '90th_percentile_frame_build_time_millis': p90,
  '99th_percentile_frame_build_time_millis': p99,
  'worst_frame_build_time_millis': 20.5,
  'missed_frame_build_budget_count': 1,
  'average_frame_rasterizer_time_millis': 9.1,
  '90th_percentile_frame_rasterizer_time_millis': 14.2,
  '99th_percentile_frame_rasterizer_time_millis': 25.0,
  'worst_frame_rasterizer_time_millis': 40.0,
  'frame_count': 600,
};

void main() {
  group('checkFrameTimings', () {
    test('a summary under both limits passes', () {
      final report = checkFrameTimings(summary(), _budget);
      expect(report.ok, isTrue);
      expect(report.lines.join('\n'), contains('90th percentile build'));
    });

    test('a summary at the limits passes', () {
      expect(checkFrameTimings(summary(p90: 8, p99: 16), _budget).ok, isTrue);
    });

    test('over the 90th-percentile limit fails with measured and allowed', () {
      final report = checkFrameTimings(summary(p90: 8.4), _budget);
      expect(report.ok, isFalse);
      final failure = report.lines.singleWhere((l) => l.startsWith('FAIL'));
      expect(failure, contains('90th percentile build'));
      expect(failure, contains('8.40 ms'));
      expect(failure, contains('8.00 ms'));
    });

    test('over the 99th-percentile limit only fails', () {
      final report = checkFrameTimings(summary(p99: 16.1), _budget);
      expect(report.ok, isFalse);
      final failure = report.lines.singleWhere((l) => l.startsWith('FAIL'));
      expect(failure, contains('99th percentile build'));
      expect(failure, contains('16.10 ms'));
      expect(failure, contains('16.00 ms'));
    });

    test('raster times are printed but not gated', () {
      final report = checkFrameTimings({
        ...summary(),
        '90th_percentile_frame_rasterizer_time_millis': 200,
        '99th_percentile_frame_rasterizer_time_millis': 400,
      }, _budget);
      expect(report.ok, isTrue);
      expect(report.lines.join('\n'), contains('200.00 ms'));
    });

    test('a summary without the expected keys fails', () {
      final report = checkFrameTimings({'frame_count': 3}, _budget);
      expect(report.ok, isFalse);
      expect(
        report.lines.join('\n'),
        contains('90th_percentile_frame_build_time_millis'),
      );
    });

    test('a summary without frames fails', () {
      final report = checkFrameTimings({
        ...summary(),
        'frame_count': 0,
      }, _budget);
      expect(report.ok, isFalse);
    });
  });

  group('budgets.json', () {
    test('the scroll budget is read from budgets.json', () {
      final budgets = PerfBudgets.load();
      final budget = budgets.frames('scroll_songs');
      expect(budget.buildP90Ms, 8.0);
      expect(budget.buildP99Ms, 16.0);
      expect(checkFrameTimings(summary(p90: 8), budget).ok, isTrue);
      expect(checkFrameTimings(summary(p90: 8.01), budget).ok, isFalse);
    });

    test('a budget file without the key fails to load the budget', () {
      final budgets = PerfBudgets.fromJson(
        jsonEncode({'other': <String, Object?>{}}),
      );
      expect(() => budgets.frames('scroll_songs'), throwsFormatException);
    });
  });

  group('the command', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('frames'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('reads the budget named by the file and exits 1 over it', () {
      final file = File('${dir.path}/scroll_songs.json')
        ..writeAsStringSync(jsonEncode(summary(p90: 9)));
      final out = StringBuffer();
      final code = runCheckFrameTimings([file.path], out: out.writeln);
      expect(code, 1);
      expect(out.toString(), contains('9.00 ms'));
    });

    test('exits 0 under the budget', () {
      final file = File('${dir.path}/scroll_songs.json')
        ..writeAsStringSync(jsonEncode(summary()));
      expect(runCheckFrameTimings([file.path], out: (_) {}), 0);
    });

    test('exits 2 without an argument', () {
      expect(runCheckFrameTimings([], out: (_) {}), 2);
    });
  });
}
