// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The pure parts of the log export (doc 02, Logging): the zip of the
/// rolling log files, the text of the in-memory ring and the bundle's name.
library;

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:soundspan/core/logging/app_logger.dart';

/// A zip archive holding each of [files] (name → bytes), in map order.
List<int> zipLogFiles(Map<String, List<int>> files) {
  final archive = Archive();
  for (final MapEntry(:key, :value) in files.entries) {
    archive.addFile(ArchiveFile.bytes(key, value));
  }
  return ZipEncoder().encodeBytes(archive);
}

/// [entries] as the file sink writes them: one JSON object per line, in
/// order, each line ending in a newline. No entries give an empty string.
String ringToText(List<LogEntry> entries) => entries
    .map((entry) => '${jsonEncode(entry.toJson(), toEncodable: _text)}\n')
    .join();

/// `soundspan-logs-<yyyyMMdd-HHmmss>.<extension>`, stamped with [time] as
/// given (the `Clock` seam answers UTC).
String logBundleName(DateTime time, String extension) {
  String two(int n) => n.toString().padLeft(2, '0');
  final date =
      '${time.year.toString().padLeft(4, '0')}'
      '${two(time.month)}${two(time.day)}';
  final clock = '${two(time.hour)}${two(time.minute)}${two(time.second)}';
  return 'soundspan-logs-$date-$clock.$extension';
}

Object? _text(Object? value) => value.toString();
