// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Contract group "Listen Together" of doc 08: the REST operations the
/// client's `ListenTogetherRepository` calls, through the generated client
/// against the real server. The admin creates a public group whose queue
/// is given by `playbackId`; `mine` and `discover` list it; the 2FA user
/// joins by code and leaves; the admin ends it. Then the two join one
/// group over sockets: a `play` from the host reaches the follower, and
/// both compute the same expected position. The listener is left out
/// because the socket group, which may run at the same time, uses it and a
/// user is in one group at a time.
@Tags(['contract'])
library;

import 'dart:async';

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

// These files are free of Flutter; this package cannot depend on the app,
// so they are imported by path.
// ignore: avoid_relative_lib_imports
import '../../lib/core/realtime/clock_sync.dart';
// Free of Flutter, imported by path as above.
// ignore: avoid_relative_lib_imports
import '../../lib/core/realtime/socket_client.dart';
// Free of Flutter, imported by path as above.
// ignore: avoid_relative_lib_imports
import '../../lib/features/listen_together/group_sync.dart';
import 'support.dart';
import 'support/totp.dart';

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

/// The first start [socket] receives: a playing `group:playback-delta` or
/// a `group:play-at`, as the position at a server time.
Future<({int positionMs, int serverTime})> _started(SocketClient socket) {
  final started = Completer<({int positionMs, int serverTime})>();
  void found(int positionMs, int serverTime) {
    if (!started.isCompleted) {
      started.complete((positionMs: positionMs, serverTime: serverTime));
    }
  }

  final subscriptions = [
    socket.playbackDelta.listen((delta) {
      if (delta.isPlaying) found(delta.positionMs, delta.serverTime);
    }),
    socket.playAt.listen((event) => found(event.positionMs, event.serverTime)),
  ];
  return started.future.timeout(const Duration(seconds: 10)).whenComplete(
    () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    },
  );
}

/// The JWT credential of a session.
JwtCredentials _jwt(LoginTokenResponse login) =>
    JwtCredentials(accessToken: login.token, refreshToken: login.refreshToken);

void main() {
  late ContractCredentials credentials;

  setUpAll(() {
    credentials = ContractCredentials.load();
  });

  test('create with queueTracks by playbackId, mine and discover list it, a '
      'second user joins by code and leaves, the host ends it', () async {
    final host = await signedInApi(credentials, credentials.admin);
    final guest = await signedInApi(
      credentials,
      credentials.twofa,
      totp: totp(credentials.totpSecret),
    );
    final tracks = (await host.send(
      (rest) => rest.library2.listTracks(limit: 2, offset: 0),
    )).tracks;
    expect(tracks, hasLength(2));

    final created = (await host.send(
      (rest) => rest.listenTogether.createListenGroup(
        body: CreateListenGroupRequest(
          name: 'Contract Listen Together',
          visibility: CreateListenGroupRequestVisibility.public,
          queueTracks: [
            for (final track in tracks)
              // Library tracks need no metadata (doc 03, Wire Models).
              ListenQueueTrackInput(playbackId: track.playbackId!),
          ],
          currentTimeMs: 1500,
          isPlaying: false,
        ),
      ),
    ))!;
    var ended = false;
    addTearDown(() async {
      if (ended) return;
      await host.send(
        (rest) => rest.listenTogether.endListenGroup(groupId: created.id),
      );
    });
    expect(created.playback.queue.map((entry) => entry.playbackId), [
      for (final track in tracks) track.playbackId,
    ]);
    expect(created.playback.currentIndex, 0);
    expect(created.hostUserId, isNotEmpty);

    final mine = await host.send(
      (rest) => rest.listenTogether.getMyListenGroup(),
    );
    expect(mine?.id, created.id);

    final discovered = await guest.send(
      (rest) => rest.listenTogether.discoverListenGroups(),
    );
    expect(discovered.map((group) => group.id), contains(created.id));

    final joined = await guest.send(
      (rest) => rest.listenTogether.joinListenGroup(
        body: JoinListenGroupRequest(joinCode: created.joinCode),
      ),
    );
    expect(joined?.id, created.id);
    expect(joined?.members.map((member) => member.isHost), contains(false));

    await guest.send(
      (rest) => rest.listenTogether.leaveListenGroup(groupId: created.id),
    );
    expect(
      await guest.send((rest) => rest.listenTogether.getMyListenGroup()),
      isNull,
    );

    await host.send(
      (rest) => rest.listenTogether.endListenGroup(groupId: created.id),
    );
    ended = true;
    expect(
      await host.send((rest) => rest.listenTogether.getMyListenGroup()),
      isNull,
    );
  });

  test('a play from the host reaches the follower as playback-delta or '
      'play-at, and both expected positions agree within 500 ms', () async {
    final hostJwt = _jwt(await logIn(credentials, credentials.admin));
    final guestJwt = _jwt(
      await logIn(
        credentials,
        credentials.twofa,
        totp: totp(credentials.totpSecret),
      ),
    );
    final host = credentialedApi(
      credentials,
      InMemoryCredentialProvider(hostJwt),
    );
    final guest = credentialedApi(
      credentials,
      InMemoryCredentialProvider(guestJwt),
    );
    final tracks = (await host.send(
      (rest) => rest.library2.listTracks(limit: 2, offset: 0),
    )).tracks;
    final group = (await host.send(
      (rest) => rest.listenTogether.createListenGroup(
        body: CreateListenGroupRequest(
          name: 'Contract Listen Together sync',
          queueTracks: [
            for (final track in tracks)
              ListenQueueTrackInput(playbackId: track.playbackId!),
          ],
          currentTimeMs: 0,
          isPlaying: false,
        ),
      ),
    ))!;
    addTearDown(
      () => host.send(
        (rest) => rest.listenTogether.endListenGroup(groupId: group.id),
      ),
    );
    await guest.send(
      (rest) => rest.listenTogether.joinListenGroup(
        body: JoinListenGroupRequest(joinCode: group.joinCode),
      ),
    );

    final hostSocket = await _connect(credentials.baseUrl, hostJwt);
    final guestSocket = await _connect(credentials.baseUrl, guestJwt);
    expect((await hostSocket.joinGroup(group.id)).ok, isTrue);
    expect((await guestSocket.joinGroup(group.id)).ok, isTrue);
    final hostClock = ClockSync(
      ping: hostSocket.ping,
      clock: StopwatchMonotonicClock(),
    );
    final guestClock = ClockSync(
      ping: guestSocket.ping,
      clock: StopwatchMonotonicClock(),
    );
    await Future.wait([hostClock.sync(), guestClock.sync()]);
    expect(hostClock.offsetMs, isNotNull);
    expect(guestClock.offsetMs, isNotNull);

    final hostStart = _started(hostSocket);
    final guestStart = _started(guestSocket);
    expect((await hostSocket.playback(PlaybackAction.play)).ok, isTrue);
    final hostPosition = await hostStart;
    final guestPosition = await guestStart;

    final hostExpected = expectedPositionMs(
      isPlaying: true,
      positionMs: hostPosition.positionMs,
      serverTime: hostPosition.serverTime,
      serverNow: hostClock.serverNow(),
    );
    final guestExpected = expectedPositionMs(
      isPlaying: true,
      positionMs: guestPosition.positionMs,
      serverTime: guestPosition.serverTime,
      serverNow: guestClock.serverNow(),
    );
    expect((hostExpected - guestExpected).abs(), lessThan(500));
  });
}
