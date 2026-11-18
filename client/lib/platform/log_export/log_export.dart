// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The log export seam (doc 02, Logging).
///
/// `createLogExporter` returns, on native targets, an exporter that zips the
/// rolling log files and hands the zip to the share sheet (Android, iOS) or
/// a save dialog (Windows, macOS, Linux); on web, one that downloads the
/// in-memory ring as text. Entries were redacted when they were logged; the
/// bundle holds nothing else.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/platform/log_export/log_export_web.dart'
    if (dart.library.io) 'package:soundspan/platform/log_export/log_export_io.dart';
import 'package:soundspan/shared/clock.dart';

export 'log_export_web.dart'
    if (dart.library.io) 'log_export_io.dart'
    show createLogExporter;

/// Result of an export the user started.
enum LogExportResult {
  /// The logs were shared, saved or downloaded.
  done,

  /// The user dismissed the share sheet or the save dialog.
  cancelled,

  /// There were no logs.
  nothingToExport,

  /// The export failed; the failure is logged.
  failed,
}

/// Hands the device's logs to the user. One implementation per platform family.
abstract interface class LogExporter {
  /// Exports the logs; never throws.
  Future<LogExportResult> export();
}

/// The persistent sink start-up created (`createPersistentLogSink`), or
/// null when there is none. Bootstrap overrides it.
final Provider<LogSink?> persistentLogSinkProvider = Provider<LogSink?>(
  (ref) => null,
);

/// The app's [LogExporter]; tests override it.
final Provider<LogExporter> logExporterProvider = Provider<LogExporter>(
  (ref) => createLogExporter(
    sink: ref.watch(persistentLogSinkProvider),
    paths: ref.watch(appPathsProvider),
    clock: ref.watch(clockProvider),
  ),
);
