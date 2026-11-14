// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/logging/app_logger.dart';

/// A sink that keeps every entry it receives.
class RecordingSink implements LogSink {
  /// Entries received, oldest first.
  final List<LogEntry> entries = [];

  @override
  void write(LogEntry entry) => entries.add(entry);

  @override
  Future<void> close() async {}
}

/// A sink that throws on every write.
class ThrowingSink implements LogSink {
  @override
  void write(LogEntry entry) => throw StateError('sink failed');

  @override
  Future<void> close() async {}
}

/// An entry with the given content and fixed metadata.
LogEntry entryWith({
  String message = 'm',
  Map<String, Object?> fields = const {},
  String? error,
  String? stackTrace,
}) => LogEntry(
  time: DateTime.utc(2026),
  level: 'info',
  scope: 'Test',
  message: message,
  fields: fields,
  error: error,
  stackTrace: stackTrace,
);
