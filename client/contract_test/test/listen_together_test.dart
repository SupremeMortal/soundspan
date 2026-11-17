// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Contract group "Listen Together" of doc 08: the REST operations the
/// client's `ListenTogetherRepository` calls, through the generated client
/// against the real server. The admin creates a public group whose queue
/// is given by `playbackId`; `mine` and `discover` list it; the 2FA user
/// joins by code and leaves; the admin ends it. The listener is left out
/// because the socket group, which may run at the same time, uses it and a
/// user is in one group at a time.
@Tags(['contract'])
library;

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

import 'support.dart';
import 'support/totp.dart';

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
}
