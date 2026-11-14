// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:soundspan/core/logging/app_logger.dart';

/// The native log sink: a [RollingFileLogSink] in [directory].
LogSink createPersistentLogSink({String? directory}) {
  if (directory == null) {
    throw ArgumentError.notNull('directory');
  }
  return RollingFileLogSink(directory);
}

/// Writes one JSON object per line to `<directory>/app.0.log`.
///
/// When a write would grow `app.0.log` beyond [maxBytes], the files rotate
/// (`app.0.log` → `app.1.log` … `app.3.log` → `app.4.log`) and the oldest is
/// deleted, so at most [maxFiles] files exist. Writes are serialised through
/// one queue; [close] waits for it.
class RollingFileLogSink implements LogSink {
  /// Creates a sink writing into [directory].
  new(this.directory);

  /// The size at which `app.0.log` rotates.
  static const int maxBytes = 1024 * 1024;

  /// The number of files kept.
  static const int maxFiles = 5;

  /// The directory holding the log files.
  final String directory;

  Future<void> _queue = Future.value();
  int? _size;

  File _file(int n) => File(p.join(directory, 'app.$n.log'));

  @override
  void write(LogEntry entry) {
    final line = utf8.encode(
      '${jsonEncode(entry.toJson(), toEncodable: _text)}\n',
    );
    _queue = _queue.then((_) => _append(line)).catchError(_report);
  }

  @override
  Future<void> close() => _queue;

  Future<void> _append(List<int> line) async {
    final current = _file(0);
    if (_size == null) {
      await Directory(directory).create(recursive: true);
      _size = current.existsSync() ? current.lengthSync() : 0;
    }
    if (_size! > 0 && _size! + line.length > maxBytes) {
      _rotate();
      _size = 0;
    }
    await current.writeAsBytes(line, mode: FileMode.append, flush: true);
    _size = _size! + line.length;
  }

  void _rotate() {
    final oldest = _file(maxFiles - 1);
    if (oldest.existsSync()) oldest.deleteSync();
    for (var n = maxFiles - 2; n >= 0; n--) {
      final file = _file(n);
      if (file.existsSync()) file.renameSync(_file(n + 1).path);
    }
  }

  static Object? _text(Object? value) => value.toString();

  void _report(Object error, StackTrace stackTrace) {
    _size = null; // Re-read the file length on the next write.
    developer.log(
      'log file write failed',
      name: 'RollingFileLogSink',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
