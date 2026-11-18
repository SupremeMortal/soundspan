// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Contract group for device-link sign-in (doc 03, Connection and session:
/// `POST /device-link/verify`, `GET /api-keys`, `DELETE /api-keys/current`,
/// `GET /auth/me`) against the seeded server.
@Tags(['contract'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

import 'support.dart';

/// One answer of a plain HTTP request.
typedef _Answer = ({int status, Object? json});

/// Sends [method] to [uri] with [headers] through a plain HTTP client and
/// decodes a JSON body.
Future<_Answer> _raw(
  String method,
  Uri uri, [
  Map<String, String> headers = const {},
]) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    headers.forEach(request.headers.set);
    final response = await request.close();
    final bytes = await response.fold<List<int>>(
      <int>[],
      (all, chunk) => all..addAll(chunk),
    );
    final type = response.headers.contentType?.mimeType;
    return (
      status: response.statusCode,
      json: type == 'application/json' && bytes.isNotEmpty
          ? jsonDecode(utf8.decode(bytes))
          : null,
    );
  } finally {
    client.close(force: true);
  }
}

/// A device name no earlier run used.
String _deviceName() =>
    'contract-${DateTime.now().microsecondsSinceEpoch} (soundspan Linux)';

void main() {
  late ContractCredentials credentials;
  late JwtCredentials session;

  setUp(() async {
    credentials = ContractCredentials.load();
    final login = await logIn(credentials, credentials.listener);
    session = JwtCredentials(
      accessToken: login.token,
      refreshToken: login.refreshToken,
    );
  });

  /// Generates a code with the listener's JWT session
  /// (`POST /api/device-link/generate` is not a client operation).
  Future<String> generateCode() async {
    final answer = await _raw(
      'POST',
      credentials.baseUrl.replace(
        path: '${credentials.baseUrl.path}/api/device-link/generate',
      ),
      authHeaders(session),
    );
    expect(answer.status, 200, reason: '${answer.json}');
    return (answer.json! as Map<String, Object?>)['code']! as String;
  }

  /// Verifies [code] as [deviceName] through the generated client.
  Future<DeviceLinkVerifyResponse> verify(String code, String deviceName) =>
      anonymousApi(credentials).send(
        (rest) => rest.session.verifyDeviceLink(
          body: DeviceLinkVerifyRequest(code: code, deviceName: deviceName),
        ),
      );

  /// A guarded API that sends [apiKey] as `X-API-Key`.
  SoundspanApi keyApi(String apiKey) => credentialedApi(
    credentials,
    InMemoryCredentialProvider(ApiKeyCredentials(apiKey: apiKey)),
  );

  /// Links a new device and revokes its key when the test ends.
  Future<({String code, String apiKey, String name})> link() async {
    final name = _deviceName();
    final code = await generateCode();
    final verified = await verify(code, name);
    addTearDown(() async {
      await _raw(
        'DELETE',
        credentials.baseUrl.replace(
          path: '${credentials.baseUrl.path}/api/api-keys/current',
        ),
        {'X-API-Key': verified.apiKey},
      );
    });
    return (code: code, apiKey: verified.apiKey, name: name);
  }

  test('verify returns a 64-hex key for the generating user', () async {
    final name = _deviceName();
    final code = await generateCode();

    final verified = await verify(code.toLowerCase(), name);
    addTearDown(
      () => _raw(
        'DELETE',
        credentials.baseUrl.replace(
          path: '${credentials.baseUrl.path}/api/api-keys/current',
        ),
        {'X-API-Key': verified.apiKey},
      ),
    );

    expect(verified.apiKey, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(verified.username, credentials.listener.username);
  });

  test('the key authenticates /auth/me, a stream and a cover by header; as '
      '?token= it is rejected', () async {
    final linked = await link();
    final api = keyApi(linked.apiKey);
    final key = ApiKeyCredentials(apiKey: linked.apiKey);

    final me = await api.send((rest) => rest.session.getCurrentUser());
    expect(me.username, credentials.listener.username);

    final tracks = await api.send((rest) => rest.library2.listTracks(limit: 1));
    final stream = StreamUrls(credentials.baseUrl)
        .track(tracks.tracks.single.playbackId!);
    final byHeader = await _raw('GET', stream, {
      ...authHeaders(key),
      'Range': 'bytes=0-99',
    });
    expect(byHeader.status, anyOf(200, 206));

    final albums = await api.send(
      (rest) => rest.library2.listAlbums(limit: 100),
    );
    final cover = albums.albums
        .map((album) => album.coverArt)
        .whereType<String>()
        .first;
    final coverUri = ImageUrls(credentials.baseUrl)
        .cover(cover, logicalPx: 100, devicePixelRatio: 1);
    expect((await _raw('GET', coverUri, authHeaders(key))).status, 200);

    final byQuery = stream.replace(
      queryParameters: {...stream.queryParameters, 'token': linked.apiKey},
    );
    expect((await _raw('GET', byQuery)).status, 401);
  });

  test('GET /api-keys lists the key with the submitted name and an '
      'expiresAt', () async {
    final linked = await link();

    final keys = await keyApi(linked.apiKey)
        .send((rest) => rest.session.listApiKeys());

    final mine = keys.apiKeys.where((k) => k.name == linked.name).toList();
    expect(mine, hasLength(1));
    expect(mine.single.expiresAt.isAfter(mine.single.createdAt), isTrue);
  });

  test('an already used code is 400 Code already used', () async {
    final linked = await link();

    await expectLater(
      verify(linked.code, _deviceName()),
      throwsA(
        isA<InvalidRequest>()
            .having((e) => e.status, 'status', 400)
            .having(
              (e) => e.serverMessage,
              'serverMessage',
              'Code already used',
            ),
      ),
    );
  });

  test('DELETE /api-keys/current revokes the key; the next request with it '
      'is 401', () async {
    final linked = await link();
    final api = keyApi(linked.apiKey);

    final revoked = await api.send(
      (rest) => rest.session.revokeCurrentApiKey(),
    );
    expect(revoked.message, isNotEmpty);

    await expectLater(
      keyApi(linked.apiKey).send((rest) => rest.session.getCurrentUser()),
      throwsA(isA<Unauthenticated>().having((e) => e.status, 'status', 401)),
    );
  });

  test(
    'DELETE /api-keys/current with a JWT is 400 NOT_API_KEY_SESSION',
    () async {
      final api = credentialedApi(
        credentials,
        InMemoryCredentialProvider(session),
      );

      await expectLater(
        api.send((rest) => rest.session.revokeCurrentApiKey()),
        throwsA(
          isA<InvalidRequest>()
              .having((e) => e.status, 'status', 400)
              .having((e) => e.code, 'code', 'NOT_API_KEY_SESSION'),
        ),
      );
    },
  );
}
