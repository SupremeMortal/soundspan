// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/platform/log_export/log_export.dart';

/// A [LogExporter] that answers [result], or waits for [pending] when set.
class FakeLogExporter implements LogExporter {
  /// Creates an exporter that answers [result].
  new({this.result = LogExportResult.done});

  /// What [export] answers.
  LogExportResult result;

  /// When set, [export] completes with this completer's future instead.
  Completer<LogExportResult>? pending;

  /// How many times [export] was called.
  int calls = 0;

  @override
  Future<LogExportResult> export() {
    calls++;
    return pending?.future ?? Future.value(result);
  }
}
