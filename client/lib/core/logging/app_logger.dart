// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The client's only logging entry point.
///
/// Wraps `package:logging`; no other file imports it. Every entry is redacted
/// (see `redaction.dart`) before any [LogSink] sees it. Nothing is sent off
/// the device.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;
import 'package:logging/logging.dart';
import 'package:soundspan/core/logging/redaction.dart';

/// One log record after redaction, as sinks receive it.
class LogEntry {
  /// Creates an entry.
  const new({
    required this.time,
    required this.level,
    required this.scope,
    required this.message,
    this.fields = const {},
    this.error,
    this.stackTrace,
  });

  /// When the record was created.
  final DateTime time;

  /// `fine`, `info`, `warning` or `severe`.
  final String level;

  /// The scope passed to [AppLogger.scope].
  final String scope;

  /// The message, without a scope prefix.
  final String message;

  /// Structured fields; values are JSON-like (maps, lists, scalars).
  final Map<String, Object?> fields;

  /// The error's text, if any.
  final String? error;

  /// The stack trace's text, if any.
  final String? stackTrace;

  /// A JSON-encodable map; values that are not JSON become strings.
  Map<String, Object?> toJson() => {
    'time': time.toUtc().toIso8601String(),
    'level': level,
    'scope': scope,
    'message': message,
    if (fields.isNotEmpty) 'fields': fields,
    if (error != null) 'error': error,
    if (stackTrace != null) 'stackTrace': stackTrace,
  };
}

/// A destination for log entries.
abstract interface class LogSink {
  /// Writes [entry]. Must not block; may buffer.
  void write(LogEntry entry);

  /// Flushes buffered entries and releases resources.
  Future<void> close();
}

/// A logger whose scope is a structured field.
///
/// ```dart
/// final _log = AppLogger.scope('Downloads');
/// _log.info('task finished', {'bytes': size});
/// ```
class AppLogger {
  new _(this._scope);

  /// A logger whose scope is a structured field, not a message prefix.
  // ignore: prefer_constructors_over_static_methods, the specified API.
  static AppLogger scope(String scope) => AppLogger._(scope);

  final String _scope;

  /// Per-request detail; dropped in release mode.
  void fine(String message, [Map<String, Object?> fields = const {}]) =>
      _log(Level.FINE, message, fields, null, null);

  /// Lifecycle events.
  void info(String message, [Map<String, Object?> fields = const {}]) =>
      _log(Level.INFO, message, fields, null, null);

  /// Recovered failures.
  void warning(
    String message, [
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
  ]) => _log(Level.WARNING, message, fields, error, stackTrace);

  /// Unrecovered failures.
  void severe(
    String message, [
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
  ]) => _log(Level.SEVERE, message, fields, error, stackTrace);

  void _log(
    Level level,
    String message,
    Map<String, Object?> fields,
    Object? error,
    StackTrace? stackTrace,
  ) {
    Logger(_scope).log(level, _Payload(message, fields), error, stackTrace);
  }
}

/// The message object carried through `package:logging`.
class _Payload {
  const new(this.message, this.fields);

  final String message;
  final Map<String, Object?> fields;

  @override
  String toString() => message;
}

/// Process-wide logging configuration.
abstract final class AppLogging {
  static StreamSubscription<LogRecord>? _subscription;
  static List<LogSink> _sinks = const [];
  static Uri? _serverBaseUrl;
  static final Set<LogSink> _reportedSinks = Set.identity();

  /// Routes every [AppLogger] to [sinks]; drops `fine` when [releaseMode].
  ///
  /// Called once from start-up code and from tests. A second call replaces
  /// the first configuration.
  static void configure({
    required List<LogSink> sinks,
    required bool releaseMode,
  }) {
    _detach();
    _sinks = List.unmodifiable(sinks);
    Logger.root.level = releaseMode ? Level.INFO : Level.ALL;
    _subscription = Logger.root.onRecord.listen(_deliver);
  }

  /// The active profile's base URL, redacted as `<server>`; null when no
  /// profile is active.
  // ignore: use_setters_to_change_properties, the specified API.
  static void setServerBaseUrl(Uri? baseUrl) => _serverBaseUrl = baseUrl;

  /// Removes every sink and the base URL; for tests.
  static void reset() {
    _detach();
    _sinks = const [];
    _serverBaseUrl = null;
    Logger.root.level = Level.INFO;
  }

  static void _detach() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _reportedSinks.clear();
  }

  static void _deliver(LogRecord record) {
    final payload = record.object;
    final entry = redact(
      LogEntry(
        time: record.time,
        level: record.level.name.toLowerCase(),
        scope: record.loggerName,
        message: payload is _Payload ? payload.message : record.message,
        fields: payload is _Payload ? payload.fields : const {},
        error: record.error?.toString(),
        stackTrace: record.stackTrace?.toString(),
      ),
      serverBaseUrl: _serverBaseUrl,
    );
    for (final sink in _sinks) {
      try {
        sink.write(entry);
      } on Object catch (error, stackTrace) {
        if (_reportedSinks.add(sink)) {
          developer.log(
            'log sink ${sink.runtimeType} failed; further failures are silent',
            name: 'AppLogging',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
    }
  }
}

/// The [AppLogger] factory: `ref.read(appLoggerProvider('Scope'))`.
final ProviderFamily<AppLogger, String> appLoggerProvider =
    Provider.family<AppLogger, String>((ref, scope) => AppLogger.scope(scope));
