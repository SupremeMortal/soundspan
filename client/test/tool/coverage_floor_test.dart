// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';

import '../../tool/coverage_floor.dart';

/// Builds an lcov record for [path] with [hit] of [total] lines covered.
String record(String path, {required int hit, required int total}) {
  final buffer = StringBuffer('SF:$path\n');
  for (var line = 1; line <= total; line++) {
    buffer.writeln('DA:$line,${line <= hit ? 1 : 0}');
  }
  buffer
    ..writeln('LF:$total')
    ..writeln('LH:$hit')
    ..writeln('end_of_record');
  return buffer.toString();
}

const _floors = CoverageFloors(core: 80, api: 80, overall: 60);

CoverageReport _evaluate({
  String app = '',
  String api = '',
  String exclusions = '',
  List<String> files = const [],
}) {
  return evaluateCoverage(
    appLcov: app,
    apiLcov: api,
    floors: _floors,
    exclusions: exclusions,
    clientFiles: files,
  );
}

void main() {
  group('evaluateCoverage', () {
    test('core at 79.9 % fails and at 80.0 % passes', () {
      final failing = _evaluate(
        app: record('lib/core/a.dart', hit: 799, total: 1000),
      );
      expect(failing.ok, isFalse);
      expect(failing.lines.first, startsWith('FAIL core'));

      final passing = _evaluate(
        app: record('lib/core/a.dart', hit: 800, total: 1000),
      );
      expect(passing.ok, isTrue);
    });

    test('api below 80 % fails', () {
      final report = _evaluate(
        api: record('lib/src/transport.dart', hit: 7, total: 10),
      );
      expect(report.ok, isFalse);
      expect(report.lines, contains(startsWith('FAIL api')));
    });

    test('reads api paths that are absolute or relative to the package', () {
      final report = _evaluate(
        api:
            record(
              '/w/client/packages/soundspan_api/lib/a.dart',
              hit: 10,
              total: 10,
            ) +
            record('lib/b.dart', hit: 0, total: 10),
      );
      expect(report.lines, contains(startsWith('FAIL api: 50.0 %')));
    });

    test('overall below 60 % fails when both groups pass', () {
      final report = _evaluate(
        app:
            record('lib/core/a.dart', hit: 10, total: 10) +
            record('lib/features/b.dart', hit: 0, total: 30),
        api: record('lib/a.dart', hit: 10, total: 10),
      );
      expect(report.lines, contains(startsWith('ok   core')));
      expect(report.lines, contains(startsWith('ok   api')));
      expect(report.lines, contains(startsWith('FAIL overall')));
      expect(report.ok, isFalse);
    });

    test('generated files are not counted', () {
      final report = _evaluate(
        app:
            record('lib/core/a.dart', hit: 10, total: 10) +
            record('lib/core/a.g.dart', hit: 0, total: 100) +
            record('lib/core/a.freezed.dart', hit: 0, total: 100) +
            record('lib/core/generated/y.dart', hit: 0, total: 100),
        api: record('lib/src/generated/y.dart', hit: 0, total: 100),
      );
      expect(report.ok, isTrue);
    });

    test('a group with no instrumented lines passes', () {
      final report = _evaluate();
      expect(report.ok, isTrue);
      expect(report.lines, hasLength(3));
    });

    test('a file on the exclusion list is not counted', () {
      final report = _evaluate(
        app:
            record('lib/core/a.dart', hit: 10, total: 10) +
            record(
              'lib/core/playback/engines/x_engine.dart',
              hit: 0,
              total: 100,
            ),
        exclusions:
            '# header\n'
            'lib/core/playback/engines/*_engine.dart # plugin-bound adapter\n',
        files: const [
          'lib/core/a.dart',
          'lib/core/playback/engines/x_engine.dart',
        ],
      );
      expect(report.ok, isTrue);
    });

    test('an exclusion entry without a reason fails', () {
      final report = _evaluate(
        exclusions: 'lib/core/a.dart\n',
        files: const ['lib/core/a.dart'],
      );
      expect(report.ok, isFalse);
      expect(report.lines, contains(contains('no reason')));
    });

    test('an exclusion entry that matches no file fails', () {
      final report = _evaluate(
        exclusions: 'lib/core/missing.dart # gone\n',
        files: const ['lib/core/a.dart'],
      );
      expect(report.ok, isFalse);
      expect(report.lines, contains(contains('matches no file')));
    });

    test('exceeding a floor by 5 points prints a notice and passes', () {
      final report = _evaluate(
        app: record('lib/core/a.dart', hit: 93, total: 100),
      );
      expect(report.ok, isTrue);
      expect(
        report.lines,
        contains(
          'notice: core is 93.0 %, 5 or more points over its floor '
          'of 80 %; commit a floor of 93',
        ),
      );
    });
  });
}
