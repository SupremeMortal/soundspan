// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:soundspan_api/src/probe.dart';

/// The OS error codes of a refused connection: Linux and Android, macOS and
/// iOS, Windows.
const _refusedCodes = {111, 61, 10061};

/// Classifies a [DioException] that carries no response.
TransportFailure mapTransportError(DioException error) {
  final type = error.type;
  if (type == DioExceptionType.connectionTimeout ||
      type == DioExceptionType.sendTimeout ||
      type == DioExceptionType.receiveTimeout) {
    return TransportFailure.timeout;
  }
  if (type == DioExceptionType.badCertificate) return TransportFailure.tls;
  final cause = error.error;
  if (cause is HandshakeException ||
      cause is CertificateException ||
      cause is TlsException) {
    return TransportFailure.tls;
  }
  if (cause is SocketException) {
    if (cause.message.contains('Failed host lookup')) {
      return TransportFailure.hostLookup;
    }
    final code = cause.osError?.errorCode;
    if ((code != null && _refusedCodes.contains(code)) ||
        cause.message.contains('Connection refused') ||
        (cause.osError?.message.contains('Connection refused') ?? false)) {
      return TransportFailure.connectionRefused;
    }
  }
  return TransportFailure.connection;
}
