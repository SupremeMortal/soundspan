// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/playback/stream_quality_info.dart';
import 'package:soundspan/shared/domain/domain.dart';

import 'controller/controller_harness.dart';
import 'queue/queue_test_items.dart';

/// An episode entry with id [queueItemId].
QueueItem _episode(String queueItemId) => QueueItem.episode(
  queueItemId: queueItemId,
  episode: const Episode(
    id: 'e1',
    podcastId: 'pod1',
    title: 'Episode',
    durationSec: 600,
  ),
  podcast: const Podcast(id: 'pod1', title: 'Podcast'),
);

void main() {
  test('quality info is fetched once per current track with the quality the '
      'source used', () async {
    final h = ControllerHarness();
    h.resolver.quality = 'high';

    await h.controller.playItems(trackItems(['a', 'b']));
    await h.settle();

    expect(h.infoRequests, [('pb-a', 'high')]);
    expect(h.controller.snapshot.quality?.quality, 'high');
    expect(h.controller.snapshot.quality?.codec, 'flac');

    await h.play(const Duration(seconds: 2));
    h.fake.failCurrent(const EngineError(EngineErrorKind.network));
    await h.settle();
    await h.timers.fireAll();
    await h.play(const Duration(seconds: 1));
    expect(h.infoRequests, [('pb-a', 'high')]);

    await h.play(trackLength);

    expect(h.controller.snapshot.current?.queueItemId, 'b');
    expect(h.infoRequests, [('pb-a', 'high'), ('pb-b', 'high')]);
    expect(h.controller.snapshot.quality?.quality, 'high');
  });

  test(
    'quality info is cleared on item change and absent for episodes',
    () async {
      final h = ControllerHarness();
      h.resolver.quality = 'low';

      await h.controller.playItems([trackItem('a'), _episode('e')]);
      await h.settle();
      expect(h.controller.snapshot.quality?.quality, 'low');

      await h.controller.next();
      await h.settle();

      expect(h.controller.snapshot.current?.queueItemId, 'e');
      expect(h.controller.snapshot.quality, isNull);
      expect(h.infoRequests, [('pb-a', 'low')]);
    },
  );

  test(
    'a quality-info failure leaves it null and playback continues',
    () async {
      final h = ControllerHarness()..failInfo = true;

      await h.controller.playItems(trackItems(['a', 'b']));
      await h.settle();
      await h.play(const Duration(seconds: 1));

      expect(h.infoRequests, [('pb-a', null)]);
      expect(h.controller.snapshot.quality, isNull);
      expect(h.controller.snapshot.error, isNull);
      expect(h.controller.snapshot.status, EngineStatus.ready);
      expect(h.controller.snapshot.position, const Duration(seconds: 1));
    },
  );

  test('changing the quality setting mid-item causes no load; the next '
      'resolved source uses the new value', () async {
    final h = ControllerHarness();
    h.resolver.quality = 'high';
    await h.controller.playItems(trackItems(['a', 'b', 'c']));
    await h.play(const Duration(seconds: 1));
    h.calls.clear();

    h.resolver.quality = 'low';
    await h.play(const Duration(seconds: 2));

    expect(h.calls.where((c) => c.startsWith('load(')), isEmpty);
    expect(h.controller.snapshot.position, const Duration(seconds: 3));

    await h.controller.next();
    await h.settle();

    expect(h.infoRequests.last, ('pb-b', 'low'));
    expect(h.controller.snapshot.quality?.quality, 'low');
  });

  test('a local file shows the downloaded quality without fetching quality '
      'info', () async {
    final h = ControllerHarness();
    h.resolver.local.add('a');
    h.fake.sources[Uri.parse('file:///music/a.flac')] = const FakeSource(
      duration: trackLength,
    );

    await h.controller.playItems(trackItems(['a']));
    await h.settle();

    expect(h.controller.snapshot.isLocalFile, isTrue);
    expect(h.infoRequests, isEmpty);
    expect(h.controller.snapshot.quality, StreamQualityInfo.downloaded());
  });

  test('repeat one keeps the info of the same entry', () async {
    final h = ControllerHarness();
    await h.controller.setRepeat(RepeatMode.one);
    await h.controller.playItems(trackItems(['a']));
    await h.play(trackLength + const Duration(seconds: 1));

    expect(h.infoRequests, [('pb-a', null)]);
  });
}
