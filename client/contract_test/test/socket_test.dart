// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Contract group "Realtime" of doc 08: two `SocketClient`s of the seeded
/// listener, one with a JWT session and one with an API key, join one
/// Listen Together group on the real server; a queue addition by
/// `playbackId` from one arrives on the other.
@Tags(['contract'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

// The socket client is free of Flutter; this package cannot depend on the
// app, so it is imported by path.
// ignore: avoid_relative_lib_imports
import '../../lib/core/realtime/socket_client.dart';
import 'support.dart';

/// Creates an API key for the session of [token] with one plain
/// `POST /api/api-keys` (test set-up only; that operation is not client
/// surface).
Future<String> _createApiKey(Uri baseUrl, String token) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(baseUrl.resolve('/api/api-keys'));
    request.headers
      ..contentType = ContentType.json
      ..set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.write(jsonEncode({'deviceName': 'contract socket test'}));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 201) {
      fail('POST /api/api-keys answered ${response.statusCode}: $body');
    }
    return (jsonDecode(body) as Map<String, Object?>)['apiKey']! as String;
  } finally {
    client.close(force: true);
  }
}

/// A connected [SocketClient] for [credential], disposed after the test.
Future<SocketClient> _connect(Uri baseUrl, Credentials credential) async {
  final client = SocketClient(
    baseUrl: baseUrl,
    credentials: () async => credential,
    refreshCredentials: () async => credential,
    onUnauthenticated: (reason) => fail('socket rejected: $reason'),
    confirmCredential: () async {},
  );
  addTearDown(client.dispose);
  final connected = client.connectionStates.firstWhere(
    (state) => state == SocketConnectionState.connected,
  );
  client.acquire('contract');
  await connected.timeout(const Duration(seconds: 10));
  return client;
}

void main() {
  late ContractCredentials credentials;

  setUpAll(() {
    credentials = ContractCredentials.load();
  });

  test('a JWT socket and an API-key socket of one user share a group; a '
      'queue add by playbackId reaches the other; ping returns the server '
      'clock', () async {
    final login = await logIn(credentials, credentials.listener);
    final jwt = JwtCredentials(
      accessToken: login.token,
      refreshToken: login.refreshToken,
    );
    final key = ApiKeyCredentials(
      apiKey: await _createApiKey(credentials.baseUrl, login.token),
    );
    final jwtApi = credentialedApi(
      credentials,
      InMemoryCredentialProvider(jwt),
    );
    final keyApi = credentialedApi(
      credentials,
      InMemoryCredentialProvider(key),
    );
    final track = (await jwtApi.send(
      (rest) => rest.library2.listTracks(limit: 1, offset: 0),
    )).tracks.single;
    final playbackId = track.playbackId!;

    final group = (await jwtApi.send(
      (rest) => rest.listenTogether.createListenGroup(
        body: const CreateListenGroupRequest(name: 'Contract socket'),
      ),
    ))!;
    addTearDown(
      () => jwtApi.send(
        (rest) => rest.listenTogether.endListenGroup(groupId: group.id),
      ),
    );
    final joined = await keyApi.send(
      (rest) => rest.listenTogether.joinListenGroup(
        body: JoinListenGroupRequest(joinCode: group.joinCode),
      ),
    );
    expect(joined?.id, group.id);

    final jwtSocket = await _connect(credentials.baseUrl, jwt);
    final keySocket = await _connect(credentials.baseUrl, key);
    expect((await jwtSocket.joinGroup(group.id)).ok, isTrue);
    expect((await keySocket.joinGroup(group.id)).ok, isTrue);

    final delta = jwtSocket.queueDelta.firstWhere(
      (delta) => delta.queue.any((entry) => entry.playbackId == playbackId),
    );
    final ack = await keySocket.queue(
      QueueAction.add,
      tracks: [PlaybackRef(playbackId: playbackId)],
    );
    expect(ack.ok, isTrue);
    expect(ack.acceptedCount, 1);
    final received = await delta.timeout(const Duration(seconds: 10));
    expect(
      received.queue.where((entry) => entry.playbackId == playbackId),
      hasLength(1),
    );

    final serverTime = await keySocket.ping();
    final local = DateTime.now().millisecondsSinceEpoch;
    expect((serverTime - local).abs(), lessThan(5000));
  });
}
