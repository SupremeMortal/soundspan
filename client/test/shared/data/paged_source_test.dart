// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/paged_source_impl.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' show ServerError;

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_reachability.dart';

Artist _artist(int index) => Artist(id: 'ar-$index', name: 'Artist $index');

/// A server of [total] artists that records every page request. A page in
/// [held] waits for its completer; a page in [failing] throws.
class _Server {
  new({this.total = 1000, this.sendTotal = true, this.cursors = false});

  int total;
  final bool sendTotal;
  final bool cursors;
  final List<PageRequest> requests = [];
  final Map<int, Completer<void>> held = {};
  final Set<int> failing = {};

  List<int> get pages => [for (final request in requests) request.index];

  Future<FetchedPage<Artist>> fetch(PageRequest request) async {
    requests.add(request);
    if (held[request.index] case final completer?) await completer.future;
    if (failing.contains(request.index)) throw const ServerError();
    final end = (request.offset + request.limit).clamp(0, total);
    final items = [
      for (var index = request.offset; index < end; index++) _artist(index),
    ];
    final hasMore = end < total;
    return FetchedPage(
      items: items,
      hasMore: hasMore,
      total: sendTotal ? total : null,
      nextCursor: cursors && hasMore ? 'after-${request.index}' : null,
    );
  }
}

void main() {
  late CacheDatabase db;
  late FakeClock clock;
  late FakeReachability reachability;
  late CacheStore store;
  late _Server server;
  final sources = <PagedSource<Object>>[];

  PagedSource<Artist> source({
    String listKey = 'artists',
    int pageSize = 100,
    PagingStyle style = PagingStyle.offset,
  }) {
    final source = PagedSources(store, clock, reachability).create<Artist>(
      listKey: listKey,
      pageSize: pageSize,
      fetchPage: server.fetch,
      style: style,
    );
    sources.add(source);
    return source;
  }

  /// Lets the cache read, fetches and writes run.
  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await pumpEventQueue();
    }
  }

  Future<void> seed(String listKey, int from, int count, {int? total}) =>
      store.writePage(
        listKey,
        offset: from,
        items: [for (var i = from; i < from + count; i++) _artist(i)],
        total: total,
      );

  setUp(() {
    db = CacheDatabase(NativeDatabase.memory());
    clock = FakeClock();
    reachability = FakeReachability();
    store = CacheStore(db, clock);
    server = _Server();
  });

  tearDown(() async {
    for (final source in sources) {
      source.dispose();
    }
    sources.clear();
    await db.close();
  });

  test(
    'the cached total and cached pages are emitted before any fetch',
    () async {
      await seed('artists', 0, 100, total: 250);
      clock.advance(const Duration(minutes: 10));
      server.held[0] = Completer();
      final paged = source();
      final snapshots = <PagedSnapshot<Artist>>[];
      paged.watch().listen(snapshots.add);
      paged.ensureVisible(0, 10);
      await settle();

      expect(snapshots.first.total, 250);
      expect(snapshots.first.itemAt(0), _artist(0));
      expect(snapshots.first.refreshing, isFalse);
      expect(server.pages, [0, 1]);
      expect(snapshots.last.refreshing, isTrue);
      server.held[0]!.complete();
    },
  );

  test(
    'ensureVisible(250, 262) with page size 100 requests pages 2 and 3 only',
    () async {
      source().ensureVisible(250, 262);
      await settle();

      expect(server.pages, unorderedEquals([2, 3]));
      expect(server.requests.map((r) => r.offset), unorderedEquals([200, 300]));
      expect(server.requests.map((r) => r.limit).toSet(), {100});
    },
  );

  test('a range spanning two pages requests both and the one after', () async {
    source().ensureVisible(180, 220);
    await settle();

    expect(server.pages, unorderedEquals([1, 2, 3]));
  });

  test('a page in flight is not requested twice', () async {
    server.held[0] = Completer();
    final paged = source()..ensureVisible(0, 5);
    await settle();
    paged.ensureVisible(0, 10);
    await settle();

    expect(server.pages.where((page) => page == 0), hasLength(1));
    server.held[0]!.complete();
  });

  test('a fresh cached page is not refetched; a stale one is', () async {
    await seed('artists', 0, 200, total: 1000);
    clock.advance(const Duration(minutes: 4));
    source().ensureVisible(0, 150);
    await settle();
    expect(server.pages, [2]);

    server.requests.clear();
    clock.advance(const Duration(minutes: 2));
    source().ensureVisible(0, 150);
    await settle();
    expect(server.pages, unorderedEquals([0, 1]));
  });

  test('a failed page sets refreshError and keeps loaded pages', () async {
    server.failing.add(1);
    final paged = source();
    final snapshots = <PagedSnapshot<Artist>>[];
    paged.watch().listen(snapshots.add);
    paged.ensureVisible(0, 10);
    await settle();

    final last = snapshots.last;
    expect(last.refreshError, isA<ServerError>());
    expect(last.itemAt(0), _artist(0));
    expect(last.itemAt(99), _artist(99));
    expect(last.itemAt(100), isNull);
    expect(last.refreshing, isFalse);
  });

  test(
    'refresh refetches the visible pages and emits a changed total',
    () async {
      final paged = source();
      final snapshots = <PagedSnapshot<Artist>>[];
      paged.watch().listen(snapshots.add);
      paged.ensureVisible(120, 130);
      await settle();
      expect(snapshots.last.total, 1000);

      server
        ..requests.clear()
        ..total = 900;
      await paged.refresh();
      await settle();

      expect(server.pages, [1]);
      expect(snapshots.last.total, 900);
    },
  );

  test('keyset pages load in order with chained cursors', () async {
    server = _Server(total: 350, sendTotal: false, cursors: true);
    final paged = source(listKey: 'liked', style: PagingStyle.keyset);
    final snapshots = <PagedSnapshot<Artist>>[];
    paged.watch().listen(snapshots.add);
    paged.ensureVisible(250, 262);
    await settle();

    expect(server.pages, [0, 1, 2, 3]);
    expect(server.requests.map((r) => r.cursor), [
      null,
      'after-0',
      'after-1',
      'after-2',
    ]);
    expect(snapshots.last.total, 350);
    expect(snapshots.last.itemAt(349), _artist(349));
  });

  test("artists pass the server's nextCursor back", () async {
    server = _Server(cursors: true);
    final paged = source()..ensureVisible(0, 10);
    await settle();
    expect(server.requests.map((r) => r.cursor), everyElement(isNull));

    server.requests.clear();
    paged.ensureVisible(150, 160);
    await settle();

    expect(server.pages, [2]);
    expect(server.requests.single.cursor, 'after-1');
  });

  test('offline serves cached pages and requests nothing', () async {
    await seed('artists', 0, 100, total: 1000);
    clock.advance(const Duration(hours: 1));
    reachability.set(Reachability.serverUnreachable);
    final paged = source();
    final snapshots = <PagedSnapshot<Artist>>[];
    paged.watch().listen(snapshots.add);
    paged.ensureVisible(0, 250);
    await settle();

    expect(server.requests, isEmpty);
    expect(snapshots.last.total, 1000);
    expect(snapshots.last.itemAt(50), _artist(50));
    expect(snapshots.last.itemAt(150), isNull);
  });

  test('different queries use different list keys', () async {
    const queries = [
      AlbumQuery(),
      AlbumQuery(filter: AlbumFilter.owned),
      AlbumQuery(sortBy: AlbumSort.recent),
      AlbumQuery(origin: LibraryOrigin.local),
      AlbumQuery(artistId: 'ar-1'),
    ];
    const artistQueries = [
      ArtistQuery(),
      ArtistQuery(filter: ArtistFilter.owned),
      ArtistQuery(sortBy: ArtistSort.tracks),
      ArtistQuery(origin: LibraryOrigin.remote),
    ];
    const trackQueries = [
      TrackQuery(),
      TrackQuery(albumId: 'al-1'),
      TrackQuery(sortBy: TrackSort.nameDesc),
      TrackQuery(origin: LibraryOrigin.peers),
    ];
    final keys = [
      for (final query in queries) query.listKey,
      for (final query in artistQueries) query.listKey,
      for (final query in trackQueries) query.listKey,
    ];
    expect(keys.toSet(), hasLength(keys.length));
    expect(
      const AlbumQuery(filter: AlbumFilter.owned).listKey,
      const AlbumQuery(filter: AlbumFilter.owned).listKey,
    );

    await seed(queries[0].listKey, 0, 100, total: 100);
    final other = source(listKey: queries[1].listKey);
    final snapshots = <PagedSnapshot<Artist>>[];
    other.watch().listen(snapshots.add);
    await settle();
    expect(snapshots.single.total, isNull);
    expect(snapshots.single.itemAt(0), isNull);
  });

  test('dispose stops emissions', () async {
    server.held[0] = Completer();
    final paged = source();
    final snapshots = <PagedSnapshot<Artist>>[];
    var done = false;
    paged.watch().listen(snapshots.add, onDone: () => done = true);
    paged.ensureVisible(0, 10);
    await settle();
    final count = snapshots.length;

    paged.dispose();
    server.held[0]!.complete();
    await seed('artists', 0, 100, total: 100);
    await settle();

    expect(snapshots, hasLength(count));
    expect(done, isTrue);
  });
}
