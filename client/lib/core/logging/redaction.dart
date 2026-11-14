// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/logging/app_logger.dart';

/// The replacement for a secret value.
const redactedValue = '<redacted>';

/// The replacement for the active server's base URL.
const serverPlaceholder = '<server>';

const _secretKeys = {
  'token',
  'refreshtoken',
  'apikey',
  'password',
  'authorization',
  'x-api-key',
};

final _tokenQuery = RegExp('([?&]token=)[^&#\\s"\']*');

/// Returns [entry] with secrets removed.
///
/// Redacts by key name (`token`, `refreshToken`, `apiKey`, `password`,
/// `authorization`, `x-api-key`, any letter case, at any depth of [LogEntry.
/// fields]) and by two patterns in the message, string field values, the
/// error and the stack trace: a `?token=` or `&token=` query value, and
/// [serverBaseUrl] (replaced by `<server>`). Token-shaped free text is not
/// recognised: callers pass secrets as fields or not at all.
LogEntry redact(LogEntry entry, {Uri? serverBaseUrl}) {
  final server = _serverPattern(serverBaseUrl);
  String text(String value) {
    var out = value.replaceAllMapped(
      _tokenQuery,
      (m) => '${m[1]}$redactedValue',
    );
    if (server != null) out = out.replaceAll(server, serverPlaceholder);
    return out;
  }

  Object? value(Object? v) => switch (v) {
    final String s => text(s),
    final Map<Object?, Object?> m => {
      for (final MapEntry(:key, value: inner) in m.entries)
        key: _isSecretKey(key) ? redactedValue : value(inner),
    },
    final Iterable<Object?> l => [for (final inner in l) value(inner)],
    _ => v,
  };

  return LogEntry(
    time: entry.time,
    level: entry.level,
    scope: entry.scope,
    message: text(entry.message),
    fields: {
      for (final MapEntry(:key, value: inner) in entry.fields.entries)
        key: _isSecretKey(key) ? redactedValue : value(inner),
    },
    error: entry.error == null ? null : text(entry.error!),
    stackTrace: entry.stackTrace == null ? null : text(entry.stackTrace!),
  );
}

bool _isSecretKey(Object? key) => _secretKeys.contains('$key'.toLowerCase());

/// Scheme, host, port and path prefix of [baseUrl], matched in any case.
RegExp? _serverPattern(Uri? baseUrl) {
  if (baseUrl == null || baseUrl.host.isEmpty) return null;
  final port = baseUrl.hasPort ? ':${baseUrl.port}' : '';
  var path = baseUrl.path;
  while (path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  final prefix = '${baseUrl.scheme}://${baseUrl.host}$port$path';
  return RegExp(RegExp.escape(prefix), caseSensitive: false);
}
