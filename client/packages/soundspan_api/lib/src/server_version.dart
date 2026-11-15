// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Reads the server's version from `GET /api/docs.json` without holding the
/// document in memory (doc 04, Capability Discovery and Version Gate).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:soundspan_api/src/errors.dart';
import 'package:soundspan_api/src/generated/soundspan_rest_client.dart';
import 'package:soundspan_api/src/transport/error_mapper.dart';

/// The version of the server behind [dio], or null when it does not say.
///
/// Requests `/api/docs.json` as a byte stream and stops reading, cancelling
/// the request, as soon as `info.version` has been read. A 401, 403 or 404
/// there (documentation disabled by a proxy) falls back to `GET /api/health`
/// through [rest]. A missing value and the literal `unknown` give null.
/// Every other failure propagates as an [ApiException].
@internal
Future<String?> fetchServerVersionWith(
  Dio dio,
  SoundspanRestClient rest,
) async {
  final cancel = CancelToken();
  final Response<ResponseBody> response;
  try {
    response = await dio.get<ResponseBody>(
      '/api/docs.json',
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'application/json'},
      ),
      cancelToken: cancel,
    );
  } on ApiException catch (error) {
    if (error.status case 401 || 403 || 404) {
      final health = await guardDecode(() => rest.session.getHealth());
      return _known(health.version);
    }
    rethrow;
  }
  final scanner = InfoVersionScanner();
  try {
    final body = response.data;
    if (body != null) {
      await for (final chunk in body.stream) {
        if (scanner.add(chunk)) break;
      }
    }
  } on DioException catch (error) {
    throw mapDioException(error);
  } finally {
    cancel.cancel();
  }
  return _known(scanner.version);
}

String? _known(String? version) =>
    version == null || version.isEmpty || version == 'unknown' ? null : version;

/// Finds `info.version` in a JSON document fed to it in byte chunks.
///
/// It tracks strings (with their escapes) and the nesting of objects and
/// arrays, and keeps only the keys of the top-level object and of `info`,
/// so memory does not grow with the document.
@internal
class InfoVersionScanner {
  final List<bool> _containers = []; // true for an object, false for an array
  bool _inString = false;
  bool _escape = false;
  _Role _role = _Role.skip;
  BytesBuilder? _captured;
  bool _expectKey = false;
  bool _awaitingValue = false;
  String? _key;
  int _infoDepth = -1;
  bool _done = false;

  /// The value of `info.version` once found; null before that and when the
  /// document has none or it is not a string.
  String? version;

  /// Whether the scan has finished: the version was found, or `info` ended
  /// without one.
  bool get done => _done;

  /// Scans [bytes]; returns [done].
  bool add(List<int> bytes) {
    for (final byte in bytes) {
      if (_done) break;
      if (_inString) {
        _string(byte);
      } else {
        _structure(byte);
      }
    }
    return _done;
  }

  void _string(int byte) {
    if (_escape) {
      _escape = false;
      _captured?.addByte(byte);
      return;
    }
    if (byte == _backslash) {
      _escape = true;
      _captured?.addByte(byte);
      return;
    }
    if (byte != _quote) {
      _captured?.addByte(byte);
      return;
    }
    _inString = false;
    final captured = _captured;
    _captured = null;
    final text = captured == null ? null : _decode(captured.takeBytes());
    switch (_role) {
      case _Role.key:
        _key = text;
        _awaitingValue = true;
      case _Role.version:
        version = text;
        _done = true;
      case _Role.skip:
        break;
    }
    _role = _Role.skip;
  }

  void _structure(int byte) {
    switch (byte) {
      case _space || _tab || _newline || _return:
        return;
      case _quote:
        if (_inObject && _expectKey) {
          _expectKey = false;
          _inString = true;
          _role = _Role.key;
          final depth = _containers.length;
          _captured = depth == 1 || depth == _infoDepth ? BytesBuilder() : null;
        } else {
          _valueStart(_Value.string);
          _inString = true;
        }
      case _openBrace:
        _valueStart(_Value.object);
        _containers.add(true);
        _expectKey = true;
      case _openBracket:
        _valueStart(_Value.other);
        _containers.add(false);
      case _closeBrace || _closeBracket:
        if (_containers.length == _infoDepth) {
          _done = true;
          return;
        }
        if (_containers.isNotEmpty) _containers.removeLast();
        _expectKey = false;
      case _colon:
        _expectKey = false;
      case _comma:
        _expectKey = _inObject;
        _awaitingValue = false;
        _key = null;
      default:
        if (_awaitingValue) _valueStart(_Value.other);
    }
  }

  bool get _inObject => _containers.isNotEmpty && _containers.last;

  /// A value begins in the current container, for the pending key if any.
  void _valueStart(_Value kind) {
    final key = _awaitingValue ? _key : null;
    _awaitingValue = false;
    _key = null;
    final depth = _containers.length;
    if (depth == 1 && key == 'info' && kind == _Value.object) {
      _infoDepth = 2;
    } else if (depth == _infoDepth && key == 'version') {
      if (kind == _Value.string) {
        _role = _Role.version;
        _captured = BytesBuilder();
      } else {
        _done = true;
      }
    }
  }

  static String? _decode(Uint8List raw) {
    try {
      return jsonDecode('"${utf8.decode(raw)}"') as String;
    } on FormatException {
      return null;
    }
  }

  static const _quote = 0x22;
  static const _backslash = 0x5C;
  static const _openBrace = 0x7B;
  static const _closeBrace = 0x7D;
  static const _openBracket = 0x5B;
  static const _closeBracket = 0x5D;
  static const _colon = 0x3A;
  static const _comma = 0x2C;
  static const _space = 0x20;
  static const _tab = 0x09;
  static const _newline = 0x0A;
  static const _return = 0x0D;
}

enum _Role { skip, key, version }

enum _Value { string, object, other }
