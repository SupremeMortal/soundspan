// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Shared helpers of the contract suite: the seeded credentials, the
/// response-validation guard and the `SoundspanApi` instances tests use.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

/// The `code` the server answers with when one of its own responses does not
/// match the client-surface spec (`OPENAPI_VALIDATE_RESPONSES=1`).
const schemaMismatchCode = 'RESPONSE_SCHEMA_MISMATCH';

/// Where `seed.ts` writes the credentials, relative to this package.
const credentialsPath = '.seed/credentials.json';

/// One account the seed created.
final class ContractAccount {
  /// Creates an account.
  const new({required this.username, required this.password});

  /// Reads an account object of `credentials.json`.
  factory fromJson(Object? json, String field) {
    if (json is! Map<String, Object?> ||
        json['username'] is! String ||
        json['password'] is! String) {
      throw FormatException('$credentialsPath: "$field" is not an account');
    }
    return ContractAccount(
      username: json['username']! as String,
      password: json['password']! as String,
    );
  }

  /// The username.
  final String username;

  /// The password.
  final String password;
}

/// The contents of `credentials.json`, written by `seed.ts`.
final class ContractCredentials {
  /// Creates credentials.
  const new({
    required this.baseUrl,
    required this.admin,
    required this.listener,
    required this.twofa,
    required this.totpSecret,
    required this.playlistId,
    required this.unavailablePlaybackId,
  });

  /// Parses the JSON object of `credentials.json`; throws [FormatException]
  /// naming the first missing or mistyped field.
  factory fromJson(Map<String, Object?> json) {
    String string(String field) => switch (json[field]) {
      final String value => value,
      _ => throw FormatException('$credentialsPath: "$field" is not a string'),
    };
    if (!json.containsKey('unavailablePlaybackId') ||
        json['unavailablePlaybackId'] is! String?) {
      throw const FormatException(
        '$credentialsPath: "unavailablePlaybackId" is not a string or null',
      );
    }
    return ContractCredentials(
      baseUrl: Uri.parse(string('baseUrl')),
      admin: ContractAccount.fromJson(json['admin'], 'admin'),
      listener: ContractAccount.fromJson(json['listener'], 'listener'),
      twofa: ContractAccount.fromJson(json['twofa'], 'twofa'),
      totpSecret: string('totpSecret'),
      playlistId: string('playlistId'),
      unavailablePlaybackId: json['unavailablePlaybackId'] as String?,
    );
  }

  /// Loads [path]; fails with a message naming `run.sh` when the seed has
  /// not run.
  factory load([String path = credentialsPath]) {
    final file = File(path);
    if (!file.existsSync()) {
      fail(
        '$path is missing: start the contract server and run seed.ts first '
        '(client/contract_test/run.sh does both).',
      );
    }
    return ContractCredentials.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, Object?>,
    );
  }

  /// The server's address, without a trailing slash.
  final Uri baseUrl;

  /// The first account: the admin.
  final ContractAccount admin;

  /// A user without 2FA, owner of [playlistId].
  final ContractAccount listener;

  /// A user with 2FA enabled.
  final ContractAccount twofa;

  /// The base32 TOTP secret of [twofa].
  final String totpSecret;

  /// A playlist of [listener] holding five tracks.
  final String playlistId;

  /// A `playbackId` the server answers with `SOURCE_UNAVAILABLE`, or null
  /// when the seed found none.
  final String? unavailablePlaybackId;
}

/// Wraps the HTTP adapter and records every JSON response that carries
/// `RESPONSE_SCHEMA_MISMATCH`; [verify] fails the test when one was seen.
final class SchemaMismatchGuard implements HttpClientAdapter {
  /// Wraps the adapter that sends the requests.
  new(this._inner);

  final HttpClientAdapter _inner;
  final _mismatches = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = await _inner.fetch(options, requestStream, cancelFuture);
    final contentType = response.headers[Headers.contentTypeHeader]?.join();
    if (contentType == null || !contentType.contains('json')) {
      return response;
    }
    final bytes = await response.stream.fold<BytesBuilder>(
      BytesBuilder(copy: false),
      (builder, chunk) => builder..add(chunk),
    );
    final body = bytes.takeBytes();
    final message = _mismatchMessage(body);
    if (message != null) {
      _mismatches.add('${options.method} ${options.uri.path}: $message');
    }
    return ResponseBody.fromBytes(
      body,
      response.statusCode,
      headers: response.headers,
      statusMessage: response.statusMessage,
      isRedirect: response.isRedirect,
    )..redirects = response.redirects;
  }

  /// Fails the test when any response carried [schemaMismatchCode].
  void verify() {
    if (_mismatches.isEmpty) return;
    fail(
      'The server answered $schemaMismatchCode: its response does not match '
      'the client-surface spec.\n${_mismatches.join('\n')}',
    );
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);

  static String? _mismatchMessage(List<int> body) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(body));
    } on FormatException {
      return null;
    }
    if (json is! Map<String, Object?> || json['code'] != schemaMismatchCode) {
      return null;
    }
    return '${json['error'] ?? json['message'] ?? schemaMismatchCode}';
  }
}

/// Holds one JWT session in memory and records every call the transport
/// makes to it.
final class InMemoryCredentialProvider implements CredentialProvider {
  /// Starts with [current].
  new(this.current);

  @override
  Credentials? current;

  /// Every pair passed to [onTokensRotated], oldest first.
  final rotations = <JwtCredentials>[];

  /// Every reason passed to [onUnauthenticated], oldest first.
  final unauthenticatedReasons = <UnauthenticatedReason>[];

  @override
  Future<void> onTokensRotated(JwtCredentials next) async {
    rotations.add(next);
    current = next;
  }

  @override
  void onUnauthenticated(UnauthenticatedReason reason) {
    unauthenticatedReasons.add(reason);
    current = null;
  }
}

/// The `User-Agent` of every contract-suite request.
const _userAgent = 'soundspan-contract-test';

/// A guarded anonymous API for [credentials]' server, closed and verified
/// when the test ends.
SoundspanApi anonymousApi(ContractCredentials credentials) {
  final guard = SchemaMismatchGuard(platformHttpClientAdapter());
  final api = SoundspanApi.anonymous(
    credentials.baseUrl,
    userAgent: _userAgent,
    adapter: guard,
  );
  addTearDown(() {
    api.close();
    guard.verify();
  });
  return api;
}

/// A guarded API for [credentials]' server that sends the credential of
/// [provider] (and [playbackDeviceId] as `X-Playback-Device-Id` when set),
/// closed and verified when the test ends.
SoundspanApi credentialedApi(
  ContractCredentials credentials,
  CredentialProvider provider, {
  String? playbackDeviceId,
}) {
  final guard = SchemaMismatchGuard(platformHttpClientAdapter());
  final api = SoundspanApi(
    ApiConfig(
      baseUrl: credentials.baseUrl,
      userAgent: _userAgent,
      playbackDeviceId: playbackDeviceId,
    ),
    credentials: provider,
    adapter: guard,
  );
  addTearDown(() {
    api.close();
    guard.verify();
  });
  return api;
}

/// Signs [account] in with its password (and [totp] when it has 2FA)
/// through a guarded anonymous API and returns the session; fails the test
/// when the server answers anything else.
Future<LoginTokenResponse> logIn(
  ContractCredentials credentials,
  ContractAccount account, {
  String? totp,
}) async {
  final login = await anonymousApi(credentials).send(
    (rest) => rest.session.login(
      body: LoginRequest(
        username: account.username,
        password: account.password,
        token: totp,
      ),
    ),
  );
  if (login is! LoginTokenResponse) {
    fail('${account.username} did not receive a session: $login');
  }
  return login;
}

/// Signs [account] in with its password (and [totp] when it has 2FA) and
/// returns a guarded API carrying the session in an
/// [InMemoryCredentialProvider] (and [playbackDeviceId] when set), closed
/// and verified when the test ends.
Future<SoundspanApi> signedInApi(
  ContractCredentials credentials,
  ContractAccount account, {
  String? totp,
  String? playbackDeviceId,
}) async {
  final login = await logIn(credentials, account, totp: totp);
  return credentialedApi(
    credentials,
    InMemoryCredentialProvider(
      JwtCredentials(
        accessToken: login.token,
        refreshToken: login.refreshToken,
      ),
    ),
    playbackDeviceId: playbackDeviceId,
  );
}
