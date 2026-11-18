// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/downloaded_library.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/features/search/data/search_history_store.dart';
import 'package:soundspan/features/search/search.dart';
import 'package:soundspan/features/search/search_providers.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/cache.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

import '../../../helpers/fake_clock.dart';
import '../../../helpers/fake_reachability.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/fakes/fake_download_controller.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';

Track _track(String title, String id, {String artist = 'Artist'}) => Track(
  meta: TrackMeta(
    title: title,
    artist: artist,
    album: 'Record',
    durationSec: 200,
  ),
  playbackId: PlaybackId(id),
);

/// Downloaded tracks this device holds.
final class _Downloaded implements DownloadedLibrary {
  const new(this.list);

  final List<Track> list;

  @override
  Future<List<Track>> tracks() async => list;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late FakeRepositories repositories;
  late CacheDatabase cacheDb;
  late CacheStore cache;
  late StateDatabase stateDb;
  late FakeDownloadController downloads;

  setUp(() {
    repositories = FakeRepositories();
    cacheDb = CacheDatabase(NativeDatabase.memory());
    cache = CacheStore(cacheDb, FakeClock());
    stateDb = StateDatabase(NativeDatabase.memory());
    downloads = FakeDownloadController();
  });
  tearDown(() async {
    await cacheDb.close();
    await stateDb.close();
  });

  Future<void> seed(WidgetTester tester) async {
    await tester.runAsync(() async {
      await cache.upsertTracks([
        _track('Moon river', 'cached-1'),
        _track('Moonlight', 'both'),
        _track('100% moon', 'pct'),
        _track('1000 moon', 'thousand'),
      ]);
      await cache.upsertAlbums([
        const Album(
          id: 'al1',
          title: 'Moon album',
          artistName: 'Artist',
          artistId: 'ar1',
        ),
      ]);
    });
    downloads
      ..setItem(const TrackItemKey('both'), itemState(DownloadStatus.completed))
      ..setItem(
        const TrackItemKey('dl-1'),
        itemState(DownloadStatus.completed),
      );
  }

  Future<void> pump(
    WidgetTester tester,
    String query, {
    Reachability state = Reachability.noNetwork,
  }) async {
    await tester.pumpApp(
      WindowClassScope(
        windowClass: WindowClass.compact,
        child: Scaffold(body: SearchScreen(query: query)),
      ),
      size: const Size(390, 2400),
      overrides: [
        ...repositories.overrides,
        ...downloads.overrides(),
        reachabilityProvider.overrideWithValue(
          FakeReachability(initial: state),
        ),
        cacheStoreProvider.overrideWith((ref) async => cache),
        downloadedLibraryProvider.overrideWithValue(
          _Downloaded([
            _track('Moonlight', 'both'),
            _track('Harvest', 'dl-1', artist: 'Moon band'),
          ]),
        ),
        searchHistoryStoreProvider.overrideWithValue(
          SearchHistoryStore(stateDb, FakeClock()),
        ),
        profilesProvider.overrideWith((ref) => Stream.value(const <Profile>[])),
        initialActiveProfileIdProvider.overrideWithValue(null),
      ],
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    }
  }

  List<String> songTitles(WidgetTester tester) => [
    for (final row in tester.widgetList<TrackRow>(find.byType(TrackRow)))
      row.title,
  ];

  testWidgets('offline: results from the cache and downloads, downloads '
      'first, labelled, with no request to the server', (tester) async {
    await seed(tester);
    await pump(tester, 'moon');

    expect(find.text('Results from this device'), findsOneWidget);
    expect(repositories.search.searches, isEmpty);
    expect(repositories.playlists.sources, isEmpty);
    // Downloads first, each track once.
    // The first downloaded match is the top result; the other downloads
    // lead the songs, and the cached copy of a download is not repeated.
    expect(find.text('Top result'), findsOneWidget);
    expect(find.text('Moonlight'), findsOneWidget);
    final titles = songTitles(tester);
    expect(titles.first, 'Harvest');
    expect(titles, isNot(contains('Moonlight')));
    expect(titles, contains('Moon river'));
    expect(find.text('Moon album'), findsWidgets);
    // A cached track without a file is disabled.
    expect(
      find.bySemanticsLabel(RegExp('^Moon river,.*Not available offline')),
      findsOneWidget,
    );
  });

  testWidgets('the Discover and Podcasts chips are hidden offline', (
    tester,
  ) async {
    await seed(tester);
    await pump(tester, 'moon');
    expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Discover'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'Podcasts'), findsNothing);
  });

  testWidgets('a query containing % matches literally', (tester) async {
    await seed(tester);
    await pump(tester, '0%');
    expect(find.text('100% moon'), findsWidgets);
    expect(find.text('1000 moon'), findsNothing);
  });

  testWidgets('online: the server is searched and no label shows', (
    tester,
  ) async {
    await seed(tester);
    await pump(tester, 'moon', state: Reachability.online);
    expect(find.text('Results from this device'), findsNothing);
    expect(repositories.search.searches, isNotEmpty);
    expect(find.widgetWithText(ChoiceChip, 'Discover'), findsOneWidget);
  });

  testWidgets('offline Search meets the accessibility guidelines', (
    tester,
  ) async {
    await seed(tester);
    await pump(tester, 'moon');
    await expectMeetsGuidelines(tester);
  });
}
