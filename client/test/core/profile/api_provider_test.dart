// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/misc.dart' show ProviderBase;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/sync/sync_providers.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan_api/soundspan_api.dart';

import 'profile_harness.dart';

void main() {
  test('the API and the playback repositories exist only inside a profile '
      'scope', () async {
    final harness = await ProfileHarness.create();

    for (final provider in <ProviderBase<Object?>>[
      soundspanApiProvider,
      playbackInfoRepositoryProvider,
      playsRepositoryProvider,
      playbackStateRepositoryProvider,
      sourceResolverProvider,
      streamQualityPolicyProvider,
    ]) {
      expect(() => harness.root.read(provider), throwsA(anything));
    }
  });

  test('the API is built from the profile config; switching profile yields '
      'a new API and new repositories', () async {
    final harness = await ProfileHarness.create();
    final runtime = harness.root.read(profileRuntimeProvider);
    addTearDown(runtime.dispose);

    await runtime.switchTo(harness.a);
    final a = runtime.container!;
    final api = a.read(soundspanApiProvider);
    expect(api.config, same(a.read(apiConfigProvider)));
    final repositories = [
      a.read(playbackInfoRepositoryProvider),
      a.read(playsRepositoryProvider),
      a.read(playbackStateRepositoryProvider),
    ];
    expect(a.read(playsRepositoryProvider), same(repositories[1]));

    await runtime.switchTo(harness.b);
    final b = runtime.container!;

    expect(b.read(soundspanApiProvider), isNot(same(api)));
    expect(
      b.read(soundspanApiProvider).config.baseUrl,
      Uri.parse('https://b.example.com'),
    );
    expect(
      b.read(playbackInfoRepositoryProvider),
      isNot(same(repositories[0])),
    );
    expect(b.read(playsRepositoryProvider), isNot(same(repositories[1])));
    expect(
      b.read(playbackStateRepositoryProvider),
      isNot(same(repositories[2])),
    );
  });

  test('the source resolver streams from the profile server with its '
      'credential', () async {
    final harness = await ProfileHarness.create();
    final runtime = harness.root.read(profileRuntimeProvider);
    addTearDown(runtime.dispose);

    await runtime.switchTo(harness.b);
    final scope = runtime.container!;
    final source = await scope
        .read(sourceResolverProvider)
        .resolve(
          const QueueItem.track(
            queueItemId: 'q1',
            track: Track(
              meta: TrackMeta(
                title: 'Song',
                artist: 'Artist',
                album: 'Album',
                durationSec: 200,
              ),
              playbackId: PlaybackId('p1'),
            ),
            context: QueueContext(kind: QueueContextKind.single),
          ),
        );
    expect(source.uri.host, 'b.example.com');
    expect(source.uri.path, '/api/playback/stream/p1');
    expect(
      source.headers,
      authHeaders(scope.read(sessionControllerProvider).current!),
    );
  });
}
