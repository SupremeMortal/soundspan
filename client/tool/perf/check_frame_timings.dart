// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

import 'budgets.dart';

/// The outcome of [checkFrameTimings].
class FrameTimingReport {
  /// A report that is [ok] or not, printed as [lines].
  const new({required this.ok, required this.lines});

  /// Whether both build-time percentiles are within the budget.
  final bool ok;

  /// One line per figure; a failure starts with `FAIL`.
  final List<String> lines;
}

const _buildP90 = '90th_percentile_frame_build_time_millis';
const _buildP99 = '99th_percentile_frame_build_time_millis';

/// Checks a `watchPerformance` [summary] against [budget].
///
/// Frame build time (UI thread) is gated at the 90th and 99th percentiles.
/// Raster time is printed and not gated: the runner renders in software.
FrameTimingReport checkFrameTimings(
  Map<String, Object?> summary,
  FrameBudget budget,
) {
  final lines = <String>[];
  var ok = true;
  final missing = [
    for (final key in [_buildP90, _buildP99, 'frame_count'])
      if (summary[key] is! num) key,
  ];
  if (missing.isNotEmpty) {
    return FrameTimingReport(
      ok: false,
      lines: ['FAIL the summary has no ${missing.join(', ')}'],
    );
  }
  final frames = (summary['frame_count']! as num).toInt();
  lines.add('frames: $frames');
  if (frames == 0) {
    ok = false;
    lines.add('FAIL the summary has no frames');
  }

  void gate(String label, String key, double limit) {
    final measured = (summary[key]! as num).toDouble();
    final line = '$label: ${_ms(measured)} (budget ${_ms(limit)})';
    if (measured > limit) {
      ok = false;
      lines.add('FAIL $line');
    } else {
      lines.add('ok   $line');
    }
  }

  gate('90th percentile build', _buildP90, budget.buildP90Ms);
  gate('99th percentile build', _buildP99, budget.buildP99Ms);
  for (final (label, key) in [
    ('average build', 'average_frame_build_time_millis'),
    ('worst build', 'worst_frame_build_time_millis'),
    ('average raster', 'average_frame_rasterizer_time_millis'),
    ('90th percentile raster', '90th_percentile_frame_rasterizer_time_millis'),
    ('99th percentile raster', '99th_percentile_frame_rasterizer_time_millis'),
    ('worst raster', 'worst_frame_rasterizer_time_millis'),
  ]) {
    final value = summary[key];
    if (value is num) lines.add('     $label: ${_ms(value.toDouble())}');
  }
  return FrameTimingReport(ok: ok, lines: lines);
}

String _ms(double value) => '${value.toStringAsFixed(2)} ms';

/// Checks the summary file in [args] against the budget named by its base
/// name (`build/perf/scroll_songs.json` is checked against `scroll_songs`
/// of `tool/perf/budgets.json`). Returns 0 within the budget, 1 over it or
/// on a bad summary, 2 on a usage error.
int runCheckFrameTimings(
  List<String> args, {
  required void Function(String line) out,
}) {
  if (args.length != 1) {
    out('usage: dart run tool/perf/check_frame_timings.dart <summary.json>');
    return 2;
  }
  final file = File(args.single);
  final key = file.uri.pathSegments.last.replaceFirst(RegExp(r'\.json$'), '');
  final FrameBudget budget;
  final Object? summary;
  try {
    budget = PerfBudgets.load().frames(key);
    summary = jsonDecode(file.readAsStringSync());
  } on Exception catch (error) {
    out('FAIL $error');
    return 1;
  }
  if (summary is! Map<String, Object?>) {
    out('FAIL ${file.path} is not a JSON object');
    return 1;
  }
  out('Frame timings of $key:');
  final report = checkFrameTimings(summary, budget);
  report.lines.forEach(out);
  return report.ok ? 0 : 1;
}

/// Checks a frame-timing summary; run from `client/`.
void main(List<String> args) {
  exitCode = runCheckFrameTimings(args, out: stdout.writeln);
}
