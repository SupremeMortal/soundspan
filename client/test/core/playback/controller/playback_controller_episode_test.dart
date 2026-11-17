// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/podcast_settings.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../../helpers/memory_device_settings.dart';
import '../queue/queue_test_items.dart';
import 'controller_harness.dart';

const Duration _episodeLength = Duration(minutes: 10);

/// An episode entry [queueItemId] with [progress].
QueueItem episodeItem(String queueItemId, {EpisodeProgress? progress}) =>
    QueueItem.episode(
      queueItemId: queueItemId,
      episode: Episode(
        id: 'ep-$queueItemId',
        podcastId: 'pod-1',
        title: 'Episode $queueItemId',
        durationSec: _episodeLength.inSeconds,
        progress: progress,
      ),
      podcast: const Podcast(id: 'pod-1', title: 'Show'),
    );

void main() {
  late MemoryDeviceSettings settings;
  late ControllerHarness h;

  setUp(() {
    settings = MemoryDeviceSettings();
    h = ControllerHarness(ids: const ['a', 'b'], deviceSettings: settings);
    h.fake.sources[uriOf('e')] = const FakeSource(duration: _episodeLength);
    h.fake.sources[uriOf('f')] = const FakeSource(duration: _episodeLength);
  });

  tearDown(() => h.controller.dispose());

  group('resume', () {
    test('an episode starts at its saved progress', () async {
      await h.controller.playItems([
        episodeItem(
          'e',
          progress: const EpisodeProgress(
            currentTimeSec: 42.5,
            isFinished: false,
          ),
        ),
      ]);
      await h.settle();

      expect(h.calls, contains('load(e, autoPlay: true, at: 0:00:42.500000)'));
    });

    test('a finished episode starts at zero', () async {
      await h.controller.playItems([
        episodeItem(
          'e',
          progress: const EpisodeProgress(
            currentTimeSec: 590,
            isFinished: true,
          ),
        ),
      ]);
      await h.settle();

      expect(h.calls, contains('load(e, autoPlay: true, at: 0:00:00.000000)'));
    });

    test('an episode never played starts at zero', () async {
      await h.controller.playItems([episodeItem('e')]);
      await h.settle();

      expect(h.calls, contains('load(e, autoPlay: true, at: 0:00:00.000000)'));
    });
  });

  group('speed', () {
    test('the stored episode speed is applied when an episode becomes '
        'current, and 1.0 when a track follows', () async {
      settings.values[podcastSpeedKey] = 1.5;
      await h.controller.playItems([episodeItem('e'), trackItem('a')]);
      await h.settle();

      expect(h.calls, contains('setSpeed(1.5)'));
      expect(h.fake.speed, 1.5);
      expect(h.controller.snapshot.speed, 1.5);

      await h.controller.next();
      await h.settle();

      expect(h.calls.last, 'setSpeed(1.0)');
      expect(h.fake.speed, 1.0);
      expect(h.controller.snapshot.speed, 1.0);
    });

    test('a track queue never sets a speed', () async {
      settings.values[podcastSpeedKey] = 2;
      await h.controller.playItems(trackItems(['a', 'b']));
      await h.controller.next();
      await h.settle();

      expect(h.calls.where((c) => c.startsWith('setSpeed')), isEmpty);
    });

    test(
      'setEpisodeSpeed with remember stores and applies the speed',
      () async {
        await h.controller.playItems([episodeItem('e')]);
        await h.settle();

        await h.controller.setEpisodeSpeed(2, remember: true);

        expect(settings.values[podcastSpeedKey], 2.0);
        expect(h.fake.speed, 2.0);
        expect(h.controller.snapshot.speed, 2.0);
      },
    );

    test(
      'setEpisodeSpeed with a track current only stores the speed',
      () async {
        await h.controller.playItems([trackItem('a')]);
        await h.settle();

        await h.controller.setEpisodeSpeed(2, remember: true);

        expect(settings.values[podcastSpeedKey], 2.0);
        expect(h.fake.speed, 1.0);
        expect(h.controller.snapshot.speed, 1.0);
      },
    );
  });

  group('skip', () {
    test('skip forward and back move by the stored interval', () async {
      settings.values[skipSecondsKey] = 30;
      await h.controller.playItems([episodeItem('e')]);
      await h.play(const Duration(seconds: 40));

      await h.controller.skipForward();
      await h.settle();
      expect(h.calls.last, 'seek(0:01:10.000000)');

      await h.controller.skipBackward();
      await h.settle();
      expect(h.calls.last, 'seek(0:00:40.000000)');
      expect(h.controller.snapshot.skipInterval, const Duration(seconds: 30));
    });

    test('skips clamp at the start and the end', () async {
      await h.controller.playItems([episodeItem('e')]);
      await h.play(const Duration(seconds: 5));

      await h.controller.skipBackward();
      await h.settle();
      expect(h.calls.last, 'seek(0:00:00.000000)');

      await h.controller.seek(const Duration(minutes: 9, seconds: 50));
      await h.settle();
      await h.controller.skipForward();
      await h.settle();
      expect(h.calls.last, 'seek(0:10:00.000000)');
    });

    test('the interval defaults to 15 seconds', () async {
      await h.controller.playItems([episodeItem('e')]);
      await h.play(const Duration(seconds: 20));

      await h.controller.skipForward();
      await h.settle();

      expect(h.calls.last, 'seek(0:00:35.000000)');
      expect(h.controller.snapshot.skipInterval, const Duration(seconds: 15));
    });
  });
}
