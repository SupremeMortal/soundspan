// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/features/mixes/data/mix_repository.dart';
import 'package:soundspan/features/mixes/mixes.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../../helpers/fake_api.dart';
import '../../../helpers/fake_clock.dart';
import '../../../helpers/fake_reachability.dart';

Map<String, Object?> _track(String id, {String? playbackId}) => {
  'id': id,
  'title': 'Title $id',
  'duration': 200,
  'playbackId': ?playbackId,
  'artist': {'id': 'ar-1', 'name': 'The Artist'},
  'album': {'id': 'al-1', 'title': 'The Album', 'coverArt': 'cover-$id'},
};

api.MixDetail _mix({String name = 'Daily Mix 1'}) => api.MixDetail.fromJson({
  'id': 'm1',
  'type': 'daily',
  'name': name,
  'description': 'Upbeat picks',
  'color': '#123456',
  'coverUrls': ['c1', 'c2', 'c3', 'c4', 'c5'],
  'trackCount': 2,
  'trackIds': ['t1', 't2'],
  'tracks': [_track('t1', playbackId: 'pb-1'), _track('t2')],
});

void main() {
  late CacheDatabase db;
  late FakeClock clock;
  late FakeDiscoveryClient server;
  late CachedMixRepository repository;

  setUp(() {
    db = CacheDatabase(NativeDatabase.memory());
    clock = FakeClock();
    server = FakeApi().discovery..mixes['m1'] = _mix();
    repository = CachedMixRepository(
      server,
      CacheStore(db, clock),
      Swr(clock: clock, reachability: FakeReachability()),
    );
  });

  tearDown(() => db.close());

  Future<(List<Cached<MixDetail>>, List<Object>)> listenOnce(
    Stream<Cached<MixDetail>> stream,
  ) async {
    final values = <Cached<MixDetail>>[];
    final errors = <Object>[];
    final subscription = stream.listen(values.add, onError: errors.add);
    await pumpEventQueue();
    await subscription.cancel();
    return (values, errors);
  }

  int calls() => server.calls['getMix'] ?? 0;

  test('maps the mix and its tracks; a track without a playbackId is not '
      'playable', () async {
    final (values, errors) = await listenOnce(repository.mix('m1'));

    expect(errors, isEmpty);
    final mix = values.single.value;
    expect(mix.id, 'm1');
    expect(mix.name, 'Daily Mix 1');
    expect(mix.description, 'Upbeat picks');
    expect(mix.artworkRefs, ['c1', 'c2', 'c3', 'c4', 'c5']);
    expect(
      [for (final t in mix.tracks) t.meta.title],
      ['Title t1', 'Title t2'],
    );
    final first = mix.tracks.first;
    expect(first.playbackId, const PlaybackId('pb-1'));
    expect(first.meta.artist, 'The Artist');
    expect(first.meta.album, 'The Album');
    expect(first.meta.durationSec, 200);
    expect(first.meta.artworkRef, 'cover-t1');
    expect(mix.tracks.last.playbackId, isNull);
    expect(server.mixIds, ['m1']);
  });

  test('an empty description is null', () async {
    server.mixes['m1'] = api.MixDetail.fromJson({
      ..._mix().toJson(),
      'description': '',
    });

    final (values, _) = await listenOnce(repository.mix('m1'));

    expect(values.single.value.description, isNull);
  });

  test('a cache hit emits first and refreshes only after 10 minutes', () async {
    await listenOnce(repository.mix('m1'));
    server.mixes['m1'] = _mix(name: 'Renamed');

    clock.advance(const Duration(minutes: 10) - const Duration(seconds: 1));
    final (fresh, _) = await listenOnce(repository.mix('m1'));
    expect(calls(), 1);
    expect(fresh.single.value.name, 'Daily Mix 1');

    clock.advance(const Duration(seconds: 2));
    final (stale, _) = await listenOnce(repository.mix('m1'));
    expect(calls(), 2);
    expect(stale.first.refreshing, isTrue);
    expect(stale.first.value.name, 'Daily Mix 1');
    expect(stale.last.refreshing, isFalse);
    expect(stale.last.value.name, 'Renamed');
  });

  test(
    'a failed refresh re-emits the cached value with refreshError',
    () async {
      await listenOnce(repository.mix('m1'));
      server.failures['getMix'] = const api.ServerError(status: 500);

      clock.advance(const Duration(minutes: 11));
      final (values, errors) = await listenOnce(repository.mix('m1'));

      expect(errors, isEmpty);
      expect(values.last.value.name, 'Daily Mix 1');
      expect(values.last.refreshError, isA<api.ServerError>());
    },
  );

  test('refreshMix fetches whatever the age', () async {
    await listenOnce(repository.mix('m1'));

    await repository.refreshMix('m1');

    expect(calls(), 2);
  });

  test('FeatureDisabled with nothing cached errors the stream', () async {
    server.failures['getMix'] = const api.FeatureDisabled(status: 404);

    final (values, errors) = await listenOnce(repository.mix('m1'));

    expect(values, isEmpty);
    expect(errors.single, isA<api.FeatureDisabled>());
  });
}
