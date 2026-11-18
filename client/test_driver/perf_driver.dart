// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Drives a performance run by `flutter drive` and writes each summary the
/// test reported (`binding.watchPerformance(reportKey: ...)`) to
/// `build/perf/<key>.json`, where `tool/perf/check_frame_timings.dart`
/// reads it.
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    final dir = Directory('build/perf')..createSync(recursive: true);
    for (final MapEntry(:key, :value) in (data ?? const {}).entries) {
      File('${dir.path}/$key.json')
          .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(value));
    }
  },
);
