// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

/// The path of the budgets file, relative to `client/`.
const String budgetsPath = 'tool/perf/budgets.json';

/// The frame build-time limits of one scroll summary.
class FrameBudget {
  /// A budget of [buildP90Ms] and [buildP99Ms] milliseconds.
  const new({required this.buildP90Ms, required this.buildP99Ms});

  /// The most the 90th-percentile frame build time may be, in ms.
  final double buildP90Ms;

  /// The most the 99th-percentile frame build time may be, in ms.
  final double buildP99Ms;
}

/// The performance budgets of `tool/perf/budgets.json`, the one file every
/// performance check reads its thresholds from (doc 11, CI Workflows).
class PerfBudgets {
  new _(this._json);

  /// Parses the budgets in [source].
  factory fromJson(String source) {
    final json = jsonDecode(source);
    if (json is! Map<String, Object?>) {
      throw const FormatException('the budgets file is not a JSON object');
    }
    return PerfBudgets._(json);
  }

  /// Reads [path], `tool/perf/budgets.json` by default.
  factory load([String path = budgetsPath]) =>
      PerfBudgets.fromJson(File(path).readAsStringSync());

  final Map<String, Object?> _json;

  /// The frame budget of the summary reported under [key].
  FrameBudget frames(String key) {
    final entry = _json[key];
    if (entry is! Map<String, Object?>) {
      throw FormatException('no frame budget "$key" in $budgetsPath');
    }
    return FrameBudget(
      buildP90Ms: _number(entry, 'build_p90_ms', key),
      buildP99Ms: _number(entry, 'build_p99_ms', key),
    );
  }

  /// The most the web build's initial load may be, gzip-compressed.
  int get webInitialLoadGzipBytes =>
      _number(_json, 'web_initial_load_gzip_bytes', 'budgets').toInt();

  /// The most the median Android cold start may be, in ms.
  int get coldStartMedianMs =>
      _number(_json, 'cold_start_median_ms', 'budgets').toInt();

  static double _number(Map<String, Object?> json, String name, String key) {
    final value = json[name];
    if (value is! num) {
      throw FormatException('"$key" has no number "$name" in $budgetsPath');
    }
    return value.toDouble();
  }
}
