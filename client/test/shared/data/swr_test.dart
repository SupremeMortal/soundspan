// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/cached.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_reachability.dart';

const _key = 'blob:test';
const _ttl = Duration(minutes: 5);

/// A remote that answers [value] or throws [error], counting calls; each
/// call waits for [gate] when it is set.
class _FakeRemote {
  String value = 'fresh';
  Exception? error;
  Completer<void>? gate;
  int calls = 0;

  Future<String> fetch() async {
    calls++;
    await gate?.future;
    if (error case final error?) throw error;
    return value;
  }
}

void main() {
  late CacheDatabase db;
  late FakeClock clock;
  late FakeReachability reachability;
  late CacheStore store;
  late Swr swr;
  late _FakeRemote remote;

  setUp(() {
    db = CacheDatabase(NativeDatabase.memory());
    clock = FakeClock();
    reachability = FakeReachability();
    store = CacheStore(db, clock);
    swr = Swr(clock: clock, reachability: reachability);
    remote = _FakeRemote();
  });

  tearDown(() => db.close());

  Stream<Cached<String>> watch() => swr.watch<String>(
    key: _key,
    ttl: _ttl,
    cache: () => store.watchBlob(_key, (json) => json! as String),
    fetch: () async {
      await store.putBlob(_key, await remote.fetch());
    },
  );

  Future<DateTime> seed(String value, {Duration age = Duration.zero}) async {
    final fetchedAt = clock.now();
    await store.putBlob(_key, value);
    clock.advance(age);
    return fetchedAt;
  }

  Future<List<Cached<String>>> collect(
    Stream<Cached<String>> stream, {
    List<Object>? errors,
  }) async {
    final values = <Cached<String>>[];
    final subscription = stream.listen(
      values.add,
      onError: (Object e) => errors?.add(e),
    );
    addTearDown(subscription.cancel);
    await pumpEventQueue();
    return values;
  }

  test('ttlOf chooses the TTL of each cached value', () async {
    Stream<Cached<String>> watchShort() => swr.watch<String>(
      key: _key,
      ttl: _ttl,
      ttlOf: (value) => value == 'short' ? const Duration(minutes: 1) : _ttl,
      cache: () => store.watchBlob(_key, (json) => json! as String),
      fetch: () async {
        await store.putBlob(_key, await remote.fetch());
      },
    );

    await seed('long', age: const Duration(minutes: 2));
    await collect(watchShort());
    expect(remote.calls, 0);

    await seed('short', age: const Duration(minutes: 2));
    final values = await collect(watchShort());
    expect(remote.calls, 1);
    expect(values.last.value, 'fresh');
  });

  test(
    'cache hit: a fresh value is emitted once and nothing is fetched',
    () async {
      final fetchedAt = await seed('cached', age: const Duration(minutes: 4));

      final values = await collect(watch());

      expect(values, [Cached(value: 'cached', fetchedAt: fetchedAt)]);
      expect(remote.calls, 0);
    },
  );

  test('stale: the cached value is emitted refreshing, then the new value, '
      'after exactly one fetch', () async {
    final fetchedAt = await seed('cached', age: const Duration(minutes: 6));

    final values = await collect(watch());

    expect(values, [
      Cached(value: 'cached', fetchedAt: fetchedAt, refreshing: true),
      Cached(value: 'fresh', fetchedAt: clock.now()),
    ]);
    expect(remote.calls, 1);
  });

  test(
    'refresh failure: the cached value is re-emitted with refreshError',
    () async {
      final fetchedAt = await seed('cached', age: const Duration(minutes: 6));
      remote.error = const ServerError(status: 500);

      final errors = <Object>[];
      final values = await collect(watch(), errors: errors);

      expect(values, [
        Cached(value: 'cached', fetchedAt: fetchedAt, refreshing: true),
        Cached(
          value: 'cached',
          fetchedAt: fetchedAt,
          refreshError: const ServerError(status: 500),
        ),
      ]);
      expect(errors, isEmpty);
    },
  );

  test('offline: a stale value is emitted and nothing is fetched', () async {
    final fetchedAt = await seed('cached', age: const Duration(days: 3));
    reachability.set(Reachability.serverUnreachable);

    final values = await collect(watch());

    expect(values, [Cached(value: 'cached', fetchedAt: fetchedAt)]);
    expect(remote.calls, 0);
  });

  test('an empty cache fetches, then emits', () async {
    final values = await collect(watch());

    expect(values, [Cached(value: 'fresh', fetchedAt: clock.now())]);
    expect(remote.calls, 1);
  });

  test('an empty cache and a failed fetch error the stream', () async {
    remote.error = const NotFound(status: 404);

    final errors = <Object>[];
    final values = await collect(watch(), errors: errors);

    expect(values, isEmpty);
    expect(errors, [isA<NotFound>()]);
  });

  test('offline with an empty cache errors with Offline', () async {
    reachability.set(Reachability.noNetwork);

    final errors = <Object>[];
    final values = await collect(watch(), errors: errors);

    expect(values, isEmpty);
    expect(errors, [isA<Offline>()]);
    expect(remote.calls, 0);
  });

  test('two listeners share one fetch', () async {
    remote.gate = Completer<void>();

    final first = <Cached<String>>[];
    final second = <Cached<String>>[];
    final a = watch().listen(first.add);
    final b = watch().listen(second.add);
    addTearDown(a.cancel);
    addTearDown(b.cancel);
    await pumpEventQueue();
    remote.gate!.complete();
    await pumpEventQueue();

    expect(remote.calls, 1);
    expect(first, [Cached(value: 'fresh', fetchedAt: clock.now())]);
    expect(second, first);
  });

  test('an undecodable cached blob is a miss and its row is deleted', () async {
    await db
        .into(db.blobs)
        .insert(
          BlobsCompanion.insert(
            key: _key,
            json: '{not json',
            fetchedAt: clock.now(),
          ),
        );
    reachability.set(Reachability.serverUnreachable);

    final errors = <Object>[];
    final values = await collect(watch(), errors: errors);

    expect(values, isEmpty);
    expect(errors, [isA<Offline>()]);
    expect(await db.select(db.blobs).get(), isEmpty);
  });

  test('a blob of the wrong shape is a miss too', () async {
    await db
        .into(db.blobs)
        .insertOnConflictUpdate(
          BlobsCompanion(
            key: const Value(_key),
            json: const Value('42'),
            fetchedAt: Value(clock.now()),
          ),
        );

    final values = await collect(watch());

    expect(values, [Cached(value: 'fresh', fetchedAt: clock.now())]);
    expect(remote.calls, 1);
  });

  test('fetch outcomes are reported to reachability', () async {
    await collect(watch());
    expect(reachability.outcomes, [true]);

    clock.advance(const Duration(minutes: 6));
    remote.error = const ServerError(status: 503);
    await collect(watch());
    expect(reachability.outcomes, [true, true]);

    remote.error = const Offline();
    await expectLater(swr.refresh(_key, remote.fetch), throwsA(isA<Offline>()));
    expect(reachability.outcomes, [true, true, false]);
  });

  test('refresh fetches whatever the age, and refuses while offline', () async {
    await seed('cached');
    final values = await collect(watch());
    expect(remote.calls, 0);

    remote.value = 'newer';
    clock.advance(const Duration(seconds: 1));
    await swr.refresh(_key, () async {
      await store.putBlob(_key, await remote.fetch());
    });
    await pumpEventQueue();

    expect(remote.calls, 1);
    expect(values.last, Cached(value: 'newer', fetchedAt: clock.now()));

    reachability.set(Reachability.forcedOffline);
    await expectLater(swr.refresh(_key, remote.fetch), throwsA(isA<Offline>()));
    expect(remote.calls, 1);
  });
}
