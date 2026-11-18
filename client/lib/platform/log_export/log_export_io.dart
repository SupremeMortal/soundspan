// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';
import 'dart:ui' show Rect;

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/logging/log_bundle.dart';
import 'package:soundspan/platform/log_export/log_export.dart';
import 'package:soundspan/platform/log_sink/log_sink_io.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan/shared/clock.dart';

final AppLogger _log = AppLogger.scope('LogExport');

/// Opens the share sheet with the file at a path; true when the user shared
/// it, false when they dismissed the sheet.
typedef ShareLogBundle = Future<bool> Function(String path);

/// Opens a save dialog suggesting a file name; the chosen path, or null when
/// the user dismissed it.
typedef PickSavePath = Future<String?> Function(String suggestedName);

/// The native [LogExporter] of the running app: flushes [sink], shares the
/// zip on Android and iOS and saves it elsewhere.
LogExporter createLogExporter({
  required LogSink? sink,
  required AppPaths paths,
  required Clock clock,
}) => IoLogExporter(
  logsDirectory: paths.logs,
  temporaryDirectory: () async => (await getTemporaryDirectory()).path,
  clock: clock,
  useShareSheet: Platform.isAndroid || Platform.isIOS,
  share: _shareSheet,
  pickSavePath: _saveDialog,
  flush: () async {
    if (sink is RollingFileLogSink) await sink.flush();
  },
);

Future<bool> _shareSheet(String path) async {
  final result = await SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: 'application/zip')],
      // iPad anchors the sheet's popover here; phones ignore it.
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
    ),
  );
  return result.status != ShareResultStatus.dismissed;
}

Future<String?> _saveDialog(String suggestedName) async {
  final location = await getSaveLocation(
    suggestedName: suggestedName,
    acceptedTypeGroups: const [
      XTypeGroup(label: 'zip', extensions: ['zip']),
    ],
  );
  return location?.path;
}

/// Zips every `app.<n>.log` in [logsDirectory] into a temporary
/// `soundspan-logs-<yyyyMMdd-HHmmss>.zip` and hands it to the user through
/// [share] (when [useShareSheet]) or a copy to the path [pickSavePath]
/// answers. The temporary zip is deleted in every outcome.
class IoLogExporter implements LogExporter {
  /// Creates the exporter; every side effect is injected.
  new({
    required this.logsDirectory,
    required this.temporaryDirectory,
    required this.clock,
    required this.useShareSheet,
    required this.share,
    required this.pickSavePath,
    required this.flush,
  });

  /// The directory of the rolling log files.
  final String logsDirectory;

  /// Where the zip is written before it is handed over.
  final Future<String> Function() temporaryDirectory;

  /// Stamps the zip's name.
  final Clock clock;

  /// Whether the zip goes to the share sheet rather than a save dialog.
  final bool useShareSheet;

  /// Opens the share sheet.
  final ShareLogBundle share;

  /// Opens the save dialog.
  final PickSavePath pickSavePath;

  /// Writes buffered entries to the log files.
  final Future<void> Function() flush;

  static final RegExp _logFile = RegExp(r'^app\.\d+\.log$');

  @override
  Future<LogExportResult> export() async {
    File? zip;
    try {
      await flush();
      final files = _readLogFiles();
      if (files.isEmpty) return LogExportResult.nothingToExport;
      final name = logBundleName(clock.now(), 'zip');
      zip = File(p.join(await temporaryDirectory(), name));
      await zip.writeAsBytes(zipLogFiles(files), flush: true);
      if (useShareSheet) {
        return await share(zip.path)
            ? LogExportResult.done
            : LogExportResult.cancelled;
      }
      final target = await pickSavePath(name);
      if (target == null) return LogExportResult.cancelled;
      await zip.copy(target);
      return LogExportResult.done;
    } on Object catch (error, stackTrace) {
      _log.warning('log export failed', const {}, error, stackTrace);
      return LogExportResult.failed;
    } finally {
      if (zip != null && zip.existsSync()) await zip.delete();
    }
  }

  Map<String, List<int>> _readLogFiles() {
    final dir = Directory(logsDirectory);
    if (!dir.existsSync()) return const {};
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((file) => _logFile.hasMatch(p.basename(file.path)))
            .toList()
          ..sort((a, b) => _number(a).compareTo(_number(b)));
    return {
      for (final file in files) p.basename(file.path): file.readAsBytesSync(),
    };
  }

  static int _number(File file) =>
      int.parse(p.basename(file.path).split('.')[1]);
}
