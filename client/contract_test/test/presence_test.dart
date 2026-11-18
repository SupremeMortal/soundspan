// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Contract group "Social Presence" of doc 08: the heartbeat and the online
/// roster the client's `PresenceRepository` calls, through the generated
/// client against the real server, and the `social:presence-updated` event
/// a connected socket receives. The listener shares their presence for the
/// test (it is off by default) and sends heartbeats; the admin reads the
/// roster and listens on a socket.
@Tags(['contract'])
library;

import 'dart:async';

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

// Free of Flutter; this package cannot depend on the app, so it is
// imported by path.
// ignore: avoid_relative_lib_imports
import '../../lib/core/realtime/socket_client.dart';
import 'support.dart';

/// Sets whether the user of [api] shares their online presence. The
/// setting is not part of the client's settings request, so it is sent as
/// an additional property.
Future<void> _sharePresence(SoundspanApi api, {required bool share}) =>
    api.send(
      (rest) => rest.session.updateSettings(
        body: UpdateSettingsRequest(
          additionalProperties: {'shareOnlinePresence': share},
        ),
      ),
    );

void main() {
  late ContractCredentials credentials;

  setUpAll(() {
    credentials = ContractCredentials.load();
  });

  test('a heartbeat succeeds for a seeded user', () async {
    final api = await signedInApi(credentials, credentials.admin);

    final beat = await api.send((rest) => rest.social.sendPresenceHeartbeat());

    expect(beat.success, isTrue);
    expect(beat.ttlSeconds, greaterThan(25));
  });

  test(
    "after a second user's heartbeat, online for the first lists the "
    'second, and a connected socket receives social:presence-updated',
    () async {
      final observer = await signedInApi(credentials, credentials.admin);
      final other = await signedInApi(credentials, credentials.listener);
      final otherId = (await other.send(
        (rest) => rest.session.getCurrentUser(),
      )).id;
      await _sharePresence(other, share: true);
      addTearDown(() => _sharePresence(other, share: false));

      final login = await logIn(credentials, credentials.admin);
      final socket = SocketClient(
        baseUrl: credentials.baseUrl,
        credentials: () async => JwtCredentials(
          accessToken: login.token,
          refreshToken: login.refreshToken,
        ),
        refreshCredentials: () async => JwtCredentials(
          accessToken: login.token,
          refreshToken: login.refreshToken,
        ),
        onUnauthenticated: (reason) => fail('socket rejected: $reason'),
        confirmCredential: () async {},
      );
      addTearDown(socket.dispose);
      final connected = socket.connectionStates.firstWhere(
        (state) => state == SocketConnectionState.connected,
      );
      socket.acquire('contract');
      await connected.timeout(const Duration(seconds: 10));
      final updated = socket.presenceUpdated
          .firstWhere((event) => event.userId == otherId)
          .timeout(const Duration(seconds: 5));

      await other.send((rest) => rest.social.sendPresenceHeartbeat());

      expect((await updated).userId, otherId);
      final roster = await observer.send(
        (rest) => rest.social.listOnlineUsers(),
      );
      expect(roster.users.map((user) => user.id), contains(otherId));
    },
  );
}
