// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/downloads/offline_repository.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../helpers/fake_api.dart';

const _device = '6f1d6c8e-3a52-4b7e-9c41-0d2b8f6a7e15';

/// The JSON a request body puts on the wire.
Object? _wire(Object body) => jsonDecode(jsonEncode(body));

void main() {
  late FakeOfflineClient server;
  late OfflineRepository repository;

  setUp(() {
    server = FakeApi().offline;
    repository = OfflineRepository(server);
  });

  group('resolve', () {
    test('maps downloadable items and every reason, an unknown one '
        'included', () async {
      server
        ..albums['al-1'] = ['t-ok', 't-gone', 't-src', 't-new']
        ..trackBytes['t-ok'] = 4096
        ..unavailable.addAll({
          't-gone': 'TRACK_UNAVAILABLE',
          't-src': 'SOURCE_UNAVAILABLE',
          't-new': 'SOME_FUTURE_REASON',
        })
        ..cacheLimitBytes = 1 << 20
        ..devices['other'] = {'t-x': (quality: 'low', sizeBytes: 100)};

      final resolution = await repository.resolve(
        CollectionKind.album,
        'al-1',
        deviceId: _device,
      );

      expect(
        resolution,
        const OfflineResolution(
          items: [
            OfflineItem(
              playbackId: PlaybackId('t-ok'),
              downloadable: true,
              downloadUrl:
                  '/api/playback/stream/t-ok?quality=original&report=0',
              expectedBytes: 4096,
              quality: 'original',
              contentType: 'FLAC',
            ),
            OfflineItem(
              playbackId: PlaybackId('t-gone'),
              downloadable: false,
              reason: OfflineUnavailableReason.trackUnavailable,
            ),
            OfflineItem(
              playbackId: PlaybackId('t-src'),
              downloadable: false,
              reason: OfflineUnavailableReason.sourceUnavailable,
            ),
            OfflineItem(
              playbackId: PlaybackId('t-new'),
              downloadable: false,
              reason: OfflineUnavailableReason.unknown,
            ),
          ],
          estimatedTotalBytes: 4096,
          cacheLimitBytes: 1 << 20,
          cacheUsedBytes: 100,
        ),
      );
    });

    test('the admin switch refuses items with downloadsDisabled', () async {
      server
        ..playlists['pl-1'] = ['t-1']
        ..downloadsDisabled = true;

      final resolution = await repository.resolve(
        CollectionKind.playlist,
        'pl-1',
        deviceId: _device,
      );

      expect(resolution.items.single.downloadable, isFalse);
      expect(
        resolution.items.single.reason,
        OfflineUnavailableReason.downloadsDisabled,
      );
    });

    test('omits quality when null and sends it when set', () async {
      await repository.resolve(CollectionKind.track, 't-1', deviceId: _device);
      await repository.resolve(
        CollectionKind.track,
        't-1',
        deviceId: _device,
        quality: 'low',
      );

      expect(server.requests.map(_wire), [
        {'deviceId': _device, 'id': 't-1', 'kind': 'track'},
        {'deviceId': _device, 'id': 't-1', 'kind': 'track', 'quality': 'low'},
      ]);
    });

    test('keeps a null expected size and the item quality verbatim', () async {
      server.trackBytes['t-1'] = null;

      final resolution = await repository.resolve(
        CollectionKind.track,
        't-1',
        deviceId: _device,
        quality: 'medium',
      );

      expect(resolution.items.single.expectedBytes, isNull);
      expect(resolution.items.single.quality, 'medium');
      expect(resolution.estimatedTotalBytes, 0);
    });

    test('surfaces CacheLimitExceeded with the three byte values', () async {
      server
        ..albums['al-1'] = ['t-1', 't-2']
        ..cacheLimitBytes = 1500
        ..devices['other'] = {'t-x': (quality: 'low', sizeBytes: 200)};

      await expectLater(
        repository.resolve(CollectionKind.album, 'al-1', deviceId: _device),
        throwsA(
          isA<api.CacheLimitExceeded>()
              .having((e) => e.limitBytes, 'limitBytes', 1500)
              .having((e) => e.usedBytes, 'usedBytes', 200)
              .having((e) => e.estimatedBytes, 'estimatedBytes', 2000),
        ),
      );
    });

    test('surfaces DownloadsDisabled', () async {
      server
        ..downloadsDisabled = true
        ..rejectWhenDisabled = true;

      await expectLater(
        repository.resolve(CollectionKind.track, 't-1', deviceId: _device),
        throwsA(isA<api.DownloadsDisabled>()),
      );
    });
  });

  test('complete sends the device, track, quality and size', () async {
    await repository.complete(
      deviceId: _device,
      playbackId: const PlaybackId('t-1'),
      quality: 'high',
      sizeBytes: 2048,
    );

    expect(_wire(server.requests.single), {
      'deviceId': _device,
      'playbackId': 't-1',
      'quality': 'high',
      'sizeBytes': 2048,
    });
    expect(server.devices[_device], {
      't-1': (quality: 'high', sizeBytes: 2048),
    });
  });

  test('list sends the device and maps the held items', () async {
    server
      ..devices[_device] = {
        't-1': (quality: 'original', sizeBytes: 10),
        't-2': (quality: 'low', sizeBytes: 20),
      }
      ..unavailable['t-2'] = 'TRACK_UNAVAILABLE';

    final items = await repository.list(deviceId: _device);

    expect(server.requests.single, {'deviceId': _device});
    expect(items, const [
      ServerOfflineItem(
        playbackId: PlaybackId('t-1'),
        quality: 'original',
        sizeBytes: 10,
        revoked: false,
      ),
      ServerOfflineItem(
        playbackId: PlaybackId('t-2'),
        quality: 'low',
        sizeBytes: 20,
        revoked: true,
      ),
    ]);
  });

  test('stats sends the device and maps the totals', () async {
    const mb = FakeOfflineClient.bytesPerMb;
    server
      ..cacheLimitBytes = 100 * mb
      ..devices[_device] = {'t-1': (quality: 'low', sizeBytes: 3 * mb)}
      ..devices['other'] = {'t-2': (quality: 'low', sizeBytes: mb)};

    final stats = await repository.stats(deviceId: _device);

    expect(server.requests.single, {'deviceId': _device});
    expect(
      stats,
      const OfflineStats(
        usedMb: 4,
        maxMb: 100,
        deviceUsedMb: 3,
        deviceTrackCount: 1,
      ),
    );
  });

  group('delete', () {
    test('sends the device and the ids and returns deletedCount', () async {
      server.devices[_device] = {
        't-1': (quality: 'low', sizeBytes: 1),
        't-2': (quality: 'low', sizeBytes: 1),
      };

      final deleted = await repository.delete(
        deviceId: _device,
        playbackIds: const [PlaybackId('t-1'), PlaybackId('t-9')],
      );

      expect(deleted, 1);
      expect(_wire(server.requests.single), {
        'deviceId': _device,
        'playbackIds': ['t-1', 't-9'],
      });
      expect(server.devices[_device]!.keys, ['t-2']);
    });

    test('accepts 500 ids and rejects 501 without a request', () async {
      List<PlaybackId> ids(int count) => [
        for (var i = 0; i < count; i++) PlaybackId('t-$i'),
      ];

      expect(
        await repository.delete(deviceId: _device, playbackIds: ids(500)),
        0,
      );
      expect(
        () => repository.delete(deviceId: _device, playbackIds: ids(501)),
        throwsArgumentError,
      );
      expect(server.requests, hasLength(1));
    });
  });
}
