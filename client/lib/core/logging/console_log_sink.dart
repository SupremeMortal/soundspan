// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:developer' as developer;

import 'package:soundspan/core/logging/app_logger.dart';

/// Writes entries to the debug console; installed only in debug builds.
class ConsoleLogSink implements LogSink {
  @override
  void write(LogEntry entry) {
    final fields = entry.fields.isEmpty ? '' : ' ${entry.fields}';
    developer.log(
      '${entry.level.toUpperCase()} ${entry.message}$fields',
      time: entry.time,
      name: entry.scope,
      error: entry.error,
      stackTrace: entry.stackTrace == null
          ? null
          : StackTrace.fromString(entry.stackTrace!),
    );
  }

  @override
  Future<void> close() async {}
}
