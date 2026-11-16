// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/logging/log_bundle.dart';
import 'package:soundspan/core/logging/ring_log_sink.dart';
import 'package:soundspan/platform/log_export/log_export.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:web/web.dart' as web;

final AppLogger _log = AppLogger.scope('LogExport');

/// The web [LogExporter]: downloads the entries of [sink] (the in-memory
/// ring) as `soundspan-logs-<yyyyMMdd-HHmmss>.txt`. [paths] is unused.
LogExporter createLogExporter({
  required LogSink? sink,
  required AppPaths paths,
  required Clock clock,
}) => WebLogExporter(
  entries: () => sink is RingLogSink ? sink.entries : const [],
  clock: clock,
);

/// Downloads the ring's entries, one JSON object per line.
class WebLogExporter implements LogExporter {
  /// Creates the exporter over [entries].
  new({required this.entries, required this.clock});

  /// The entries to export, oldest first.
  final List<LogEntry> Function() entries;

  /// Stamps the file's name.
  final Clock clock;

  @override
  Future<LogExportResult> export() async {
    try {
      final list = entries();
      if (list.isEmpty) return LogExportResult.nothingToExport;
      final bytes = utf8.encode(ringToText(list));
      final blob = web.Blob(
        [bytes.toJS].toJS,
        web.BlobPropertyBag(type: 'text/plain;charset=utf-8'),
      );
      final url = web.URL.createObjectURL(blob);
      (web.HTMLAnchorElement()
            ..href = url
            ..download = logBundleName(clock.now(), 'txt'))
          .click();
      // The browser reads the blob after the click returns.
      unawaited(
        Future<void>.delayed(
          const Duration(seconds: 10),
          () => web.URL.revokeObjectURL(url),
        ),
      );
      return LogExportResult.done;
    } on Object catch (error, stackTrace) {
      _log.warning('log export failed', const {}, error, stackTrace);
      return LogExportResult.failed;
    }
  }
}
