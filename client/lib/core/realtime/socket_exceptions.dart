// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Failures of the `SocketClient` emitters (doc 08, Typed Events).
///
/// This file imports nothing from Flutter, so the contract suite can use it.
library;

/// Why a `SocketClient` command did not succeed.
sealed class RealtimeException implements Exception {
  const new();
}

/// The command was emitted while the socket was not connected.
final class SocketNotConnected extends RealtimeException {
  /// Creates the failure of [event].
  const new(this.event);

  /// The event that was not sent.
  final String event;

  @override
  String toString() => 'SocketNotConnected($event)';
}

/// The server did not acknowledge the command in time.
final class SocketAckTimeout extends RealtimeException {
  /// Creates the failure of [event] after [timeout].
  const new(this.event, this.timeout);

  /// The event that was not acknowledged.
  final String event;

  /// How long the client waited.
  final Duration timeout;

  @override
  String toString() => 'SocketAckTimeout($event, ${timeout.inMilliseconds} ms)';
}

/// The server acknowledged the command with an `error`.
final class SocketCommandException extends RealtimeException {
  /// Creates the failure from the fields of an error acknowledgement.
  const new({
    required this.message,
    this.code,
    this.transient = false,
    this.retryable = false,
    this.retryAfterMs,
  });

  /// Reads an error acknowledgement `{ error, code?, transient?,
  /// retryable?, retryAfterMs? }`; fields of the wrong type are ignored.
  factory fromAck(Map<String, Object?> ack) => SocketCommandException(
    message: switch (ack['error']) {
      final String message => message,
      final Object? other => '$other',
    },
    code: switch (ack['code']) {
      final String code => code,
      _ => null,
    },
    transient: ack['transient'] == true,
    retryable: ack['retryable'] == true,
    retryAfterMs: switch (ack['retryAfterMs']) {
      final num value => value.toInt(),
      _ => null,
    },
  );

  /// The server's message.
  final String message;

  /// The server's error code, such as `CONFLICT`.
  final String? code;

  /// Whether the failure is temporary.
  final bool transient;

  /// Whether sending the command again may succeed.
  final bool retryable;

  /// How long to wait before sending it again.
  final int? retryAfterMs;

  @override
  String toString() =>
      'SocketCommandException($message${code == null ? '' : ', $code'})';
}
