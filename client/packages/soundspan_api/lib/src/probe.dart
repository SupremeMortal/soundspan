// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The raw HTTP client of the server probe, used before the client knows
/// whether a soundspan server answers at an address.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:soundspan_api/src/probe_transport.dart';
import 'package:soundspan_api/src/transport/adapter.dart';

/// Why a probe request received no HTTP response.
enum TransportFailure {
  /// The host name did not resolve.
  hostLookup,

  /// Nothing accepted the connection at that address and port.
  connectionRefused,

  /// Connecting, sending or receiving took longer than allowed.
  timeout,

  /// The TLS handshake failed, for example on an untrusted certificate.
  tls,

  /// Any other failure without a response. On the web every transport
  /// failure is this one.
  connection,
}

/// Thrown by [ProbeClient.get] when no HTTP response arrived.
class ProbeTransportException implements Exception {
  /// Creates an exception for [kind].
  const new(this.kind);

  /// What went wrong.
  final TransportFailure kind;

  @override
  String toString() => 'ProbeTransportException(${kind.name})';
}

/// One HTTP response received by [ProbeClient.get], whatever its status.
class ProbeResponse {
  /// Creates a response.
  const new({
    required this.uri,
    required this.status,
    this.location,
    this.json,
  });

  /// The URL that was requested.
  final Uri uri;

  /// The HTTP status.
  final int status;

  /// The `Location` header resolved against [uri], when present.
  final Uri? location;

  /// The body when it is a JSON object; null otherwise.
  final Map<String, Object?>? json;
}

/// Sends the probe's `GET` requests: redirects are returned rather than
/// followed, every status is a response, and no credential is ever sent.
class ProbeClient {
  /// Creates a client with its own connection pool.
  new({
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 10),
  }) : _dio = Dio(
         BaseOptions(
           connectTimeout: connectTimeout,
           receiveTimeout: receiveTimeout,
           followRedirects: false,
           maxRedirects: 0,
           validateStatus: (_) => true,
           responseType: ResponseType.plain,
         ),
       )..httpClientAdapter = platformHttpClientAdapter();

  final Dio _dio;

  /// Requests [absolute] once.
  ///
  /// Throws a [ProbeTransportException] when no response arrived.
  Future<ProbeResponse> get(Uri absolute) async {
    final Response<String> response;
    try {
      response = await _dio.getUri<String>(absolute);
    } on DioException catch (error) {
      throw ProbeTransportException(mapTransportError(error));
    }
    final location = response.headers.value('location');
    return ProbeResponse(
      uri: absolute,
      status: response.statusCode ?? 0,
      location: location == null ? null : _resolve(absolute, location),
      json: _decodeObject(response.data),
    );
  }

  /// Closes the connection pool.
  void close() => _dio.close(force: true);

  static Uri? _resolve(Uri base, String location) {
    try {
      return base.resolve(location);
    } on FormatException {
      return null;
    }
  }

  static Map<String, Object?>? _decodeObject(String? body) {
    if (body == null || body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
