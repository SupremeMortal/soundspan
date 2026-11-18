// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/playback/source_resolver.dart';
import 'package:soundspan/core/playback/stream_quality_info.dart';
import 'package:soundspan/core/playback/stream_quality_policy.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan/platform/stream_auth/stream_auth_io.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_reachability.dart';
import '../../helpers/fakes/fake_media_files.dart';
import 'controller/controller_harness.dart';
import 'queue/queue_test_items.dart';

final DateTime _start = DateTime.utc(2026, 5, 1, 12);

/// A [DownloadStore] that records every `touchLastPlayed` call.
class _RecordingStore extends DownloadStore {
  new(super._db, {super.paths});

  final List<DownloadItemKey> touched = [];

  @override
  Future<void> touchLastPlayed(DownloadItemKey key, DateTime at) {
    touched.add(key);
    return super.touchLastPlayed(key, at);
  }
}

void main() {
  late Directory dir;
  late StateDatabase db;
  late DownloadPaths paths;
  late _RecordingStore store;
  late FakeReachability reachability;
  late FakeClock clock;
  late ControllerHarness h;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('playback_offline');
    db = StateDatabase(NativeDatabase.memory());
    paths = DownloadPaths(
      ProfilePaths.derive(
        appSupport: p.join(dir.path, 'support'),
        appCache: p.join(dir.path, 'cache'),
        profileId: 'p1',
      ),
    );
    store = _RecordingStore(db, paths: paths);
    reachability = FakeReachability();
    clock = FakeClock(start: _start);
    h = ControllerHarness(
      clock: clock,
      playAny: true,
      sourceResolver: SourceResolver(
        ensureFresh: ({required minRemaining}) async =>
            const api.JwtCredentials(accessToken: 'a', refreshToken: 'r'),
        urls: api.StreamUrls(Uri.parse('https://music.example.com')),
        quality: StreamQualityPolicy(DeviceSettingsDao(db), reachability),
        auth: const HeaderStreamAuth(),
        downloads: store,
        files: FakeMediaFiles(),
        reachability: reachability,
        clock: clock,
      ),
    );
  });
  tearDown(() async {
    await h.controller.dispose();
    await db.close();
    dir.deleteSync(recursive: true);
  });

  /// Downloads the track of entry [id] (`pb-<id>`) at `high` quality.
  Future<String> download(String id) async {
    final key = TrackItemKey('pb-$id');
    final relative = paths.relativeFinalFile(itemKeyHash(key), 'audio/flac');
    await store.upsertItem(
      key,
      DownloadItemsCompanion(
        metaJson: const Value('{}'),
        status: const Value(DownloadStatus.completed),
        quality: const Value('high'),
        sizeBytes: const Value(4),
        relativePath: Value(relative),
        requestedAt: Value(_start),
        completedAt: Value(_start),
      ),
    );
    final absolute = paths.resolve(relative);
    File(absolute)
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3, 4]);
    return absolute;
  }

  /// The entries the engine opened, in order.
  List<String> opened() => [
    for (final source in h.fake.requested) source.queueItemId,
  ];

  bool stoppedFor(PlaybackErrorKind kind) =>
      h.notices.any((n) => n is PlaybackStopped && n.kind == kind);

  test('offline, only the downloaded items of the queue play', () async {
    await download('b');
    await download('d');
    reachability.set(Reachability.forcedOffline);

    await h.controller.playItems(trackItems(['a', 'b', 'c', 'd', 'e']));
    await h.settle();

    expect(h.controller.snapshot.current?.queueItemId, 'b');
    expect(h.controller.snapshot.playing, isTrue);

    await h.play(trackLength + const Duration(seconds: 1));
    expect(h.controller.snapshot.current?.queueItemId, 'd');
    expect(h.controller.snapshot.playing, isTrue);

    await h.play(trackLength + const Duration(seconds: 1));
    final snapshot = h.controller.snapshot;
    expect(opened(), ['b', 'd']);
    expect(snapshot.current?.queueItemId, 'd');
    expect(snapshot.playing, isFalse);
    expect(stoppedFor(PlaybackErrorKind.serverUnreachable), isFalse);
    expect(h.timers.created, isEmpty, reason: 'no 1 s retry offline');
  });

  for (final repeat in [RepeatMode.off, RepeatMode.all]) {
    test('with nothing downloaded playback stops with "Not available '
        'offline" (repeat ${repeat.name})', () async {
      reachability.set(Reachability.forcedOffline);
      await h.controller.setRepeat(repeat);

      await h.controller.playItems(trackItems(['a', 'b', 'c', 'd', 'e']));
      await h.settle();

      final snapshot = h.controller.snapshot;
      expect(opened(), isEmpty);
      expect(snapshot.playing, isFalse);
      expect(snapshot.queue.cursor, 0);
      expect(snapshot.error?.kind, PlaybackErrorKind.notAvailableOffline);
      expect(stoppedFor(PlaybackErrorKind.notAvailableOffline), isTrue);
      expect(stoppedFor(PlaybackErrorKind.serverUnreachable), isFalse);
      expect(h.timers.created, isEmpty);
    });
  }

  test('isLocalFile follows the current item', () async {
    await download('a');

    await h.controller.playItems(trackItems(['a', 'b']));
    await h.settle();
    expect(h.controller.snapshot.isLocalFile, isTrue);
    expect(h.fake.requested.first.uri.isScheme('file'), isTrue);

    await h.play(trackLength + const Duration(seconds: 1));
    expect(h.controller.snapshot.current?.queueItemId, 'b');
    expect(h.controller.snapshot.isLocalFile, isFalse);
  });

  test('a downloaded item shows the downloaded quality without asking the '
      'server', () async {
    await download('a');

    await h.controller.playItems(trackItems(['a']));
    await h.settle();

    expect(
      h.controller.snapshot.quality,
      StreamQualityInfo.downloaded(quality: 'high'),
    );
    expect(h.infoRequests, isEmpty);
  });

  test('lastPlayedAt is written once per started item', () async {
    await download('a');
    await download('b');

    await h.controller.playItems(trackItems(['a', 'b']));
    await h.play(const Duration(seconds: 2));
    await h.controller.pause();
    await h.controller.play();
    await h.controller.seek(const Duration(seconds: 5));
    await h.play(trackLength);
    await h.settle();

    expect(h.controller.snapshot.current?.queueItemId, 'b');
    expect(store.touched, const [TrackItemKey('pb-a'), TrackItemKey('pb-b')]);
    final a = await store.item(const TrackItemKey('pb-a'));
    expect(a?.lastPlayedAt, _start);
  });

  test('a downloaded file that cannot be decoded is queued again and the '
      'item streams from the same position', () async {
    await download('a');

    await h.controller.playItems(trackItems(['a', 'b']));
    await h.play(const Duration(seconds: 3));
    h.fake.failCurrent(const EngineError(EngineErrorKind.decode));
    await h.settle();

    final row = await store.item(const TrackItemKey('pb-a'));
    expect(row?.status, DownloadStatus.queued);
    final last = h.fake.requested.lastWhere((s) => s.queueItemId == 'a');
    expect(h.fake.requested.where((s) => s.queueItemId == 'a'), hasLength(2));
    expect(last.uri.isScheme('https'), isTrue);
    expect(last.startAt, const Duration(seconds: 3));
    expect(h.controller.snapshot.current?.queueItemId, 'a');
    expect(h.controller.snapshot.isLocalFile, isFalse);
  });

  test(
    'offline, a downloaded file that cannot be decoded is skipped',
    () async {
      await download('a');
      await download('b');
      reachability.set(Reachability.forcedOffline);

      await h.controller.playItems(trackItems(['a', 'b']));
      await h.play(const Duration(seconds: 3));
      h.fake.failCurrent(const EngineError(EngineErrorKind.decode));
      await h.settle();

      expect(h.controller.snapshot.current?.queueItemId, 'b');
      expect(h.controller.snapshot.isLocalFile, isTrue);
      expect(h.timers.created, isEmpty);
    },
  );
}
