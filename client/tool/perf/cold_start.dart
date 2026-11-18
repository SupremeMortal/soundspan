// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'budgets.dart';

/// The `TotalTime` in ms of one `adb shell am start -W` [output].
///
/// Throws a [FormatException] when the output has no `Status: ok` line or
/// no `TotalTime`.
int parseTotalTime(String output) {
  final lines = output.split(RegExp(r'\r?\n')).map((line) => line.trim());
  if (!lines.contains('Status: ok')) {
    throw const FormatException('the launch has no "Status: ok"');
  }
  for (final line in lines) {
    final match = RegExp(r'^TotalTime:\s*(\d+)$').firstMatch(line);
    if (match != null) return int.parse(match.group(1)!);
  }
  throw const FormatException('the launch has no "TotalTime"');
}

/// The outcome of [checkColdStart].
class ColdStartReport {
  /// A report of [medianMs] that is [ok] or not, printed as [lines].
  const new({required this.ok, required this.medianMs, required this.lines});

  /// Whether every run launched and the median is within the budget.
  final bool ok;

  /// The median `TotalTime`; null when a run did not launch.
  final int? medianMs;

  /// One line per run, then the median.
  final List<String> lines;
}

/// Checks the [outputs] of repeated `am start -W` runs: the median
/// `TotalTime` must be at most [budgetMs].
ColdStartReport checkColdStart(List<String> outputs, {required int budgetMs}) {
  final lines = <String>[];
  final times = <int>[];
  var ok = outputs.isNotEmpty;
  if (outputs.isEmpty) lines.add('FAIL no runs');
  for (var i = 0; i < outputs.length; i++) {
    try {
      final time = parseTotalTime(outputs[i]);
      times.add(time);
      lines.add('     run ${i + 1}: $time ms');
    } on FormatException catch (error) {
      ok = false;
      lines.add('FAIL run ${i + 1}: ${error.message}');
    }
  }
  if (!ok) return ColdStartReport(ok: false, medianMs: null, lines: lines);

  final sorted = [...times]..sort();
  final middle = sorted.length ~/ 2;
  final median = sorted.length.isOdd
      ? sorted[middle]
      : ((sorted[middle - 1] + sorted[middle]) / 2).round();
  final line = 'median cold start: $median ms (budget $budgetMs ms)';
  final within = median <= budgetMs;
  lines.add(within ? 'ok   $line' : 'FAIL $line');
  return ColdStartReport(ok: within, medianMs: median, lines: lines);
}

/// Checks the `am start -W` output files in [args] against
/// `cold_start_median_ms` of `tool/perf/budgets.json`. Returns 0 within the
/// budget, 1 over it or when a run did not launch, 2 on a usage error.
int runColdStart(List<String> args, {required void Function(String) out}) {
  if (args.isEmpty) {
    out('usage: dart run tool/perf/cold_start.dart <am-start-output>...');
    return 2;
  }
  final report = checkColdStart([
    for (final path in args) File(path).readAsStringSync(),
  ], budgetMs: PerfBudgets.load().coldStartMedianMs);
  report.lines.forEach(out);
  return report.ok ? 0 : 1;
}

/// Checks Android cold-start runs; run from `client/`.
void main(List<String> args) {
  exitCode = runColdStart(args, out: stdout.writeln);
}
