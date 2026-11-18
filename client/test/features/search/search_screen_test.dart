// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/top_bar.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/features/search/data/search_history_store.dart';
import 'package:soundspan/features/search/search.dart';
import 'package:soundspan/features/search/search_providers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/media_row.dart';
import 'package:soundspan/shared/widgets/track_row.dart';
import 'package:soundspan_api/soundspan_api.dart' show Offline;

import '../../app/shell/shortcuts/selection_harness.dart';
import '../../helpers/fake_clock.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/play_rig.dart';
import '../../helpers/pump_app.dart';

Track _track(String title, {String? playbackId, String artist = 'Miles'}) =>
    Track(
      meta: TrackMeta(
        title: title,
        artist: artist,
        album: 'Kind of Blue',
        durationSec: 545,
      ),
      playbackId: playbackId == null ? null : PlaybackId(playbackId),
    );

SearchResult _result(SearchHit hit, {bool catalogue = false}) => SearchResult(
  hit: hit,
  source: catalogue ? SearchResultSource.catalogue : SearchResultSource.library,
);

SearchResult _song(Track track, {bool catalogue = false}) =>
    _result(SearchHit.track(track: track), catalogue: catalogue);

/// Results for "miles", best first: library items mixed with catalogue
/// items, as the server ranks them.
final List<SearchResult> _miles = [
  _result(
    const SearchHit.artist(
      artist: Artist(id: 'ar1', name: 'Miles Davis'),
    ),
  ),
  _result(
    const SearchHit.album(
      album: Album(
        id: 'al1',
        title: 'Kind of Blue',
        artistName: 'Miles Davis',
        artistId: 'ar1',
      ),
    ),
  ),
  _song(_track('So What', playbackId: 'pb1', artist: 'Miles Davis')),
  _result(
    const SearchHit.playlist(
      playlist: PlaylistSummary(
        id: 'pl1',
        name: 'Miles mix',
        trackCount: 3,
        isOwner: true,
        isPublic: false,
      ),
    ),
  ),
  _result(
    const SearchHit.artist(
      artist: Artist(id: 'mbid-1', name: 'Miles Kane'),
    ),
    catalogue: true,
  ),
  _result(
    const SearchHit.album(
      album: Album(
        id: 'remote-al',
        title: 'Bitches Brew',
        artistName: 'Miles Davis',
        artistId: 'ar1',
      ),
    ),
    catalogue: true,
  ),
  _song(
    _track('Blue in Green', playbackId: 'pb2', artist: 'Miles Davis'),
    catalogue: true,
  ),
  _result(
    const SearchHit.podcast(
      podcast: PodcastSummary(
        id: 'pc1',
        title: 'Miles on Jazz',
        author: 'Host',
      ),
    ),
    catalogue: true,
  ),
];

/// A compact window tall enough to show every row at once.
const Size _tallCompact = Size(390, 2400);

/// Words that would say where a result came from.
const List<String> _sourceWords = [
  'TIDAL',
  'Tidal',
  'YouTube',
  'YT Music',
  'Deezer',
  'Spotify',
  'Last.fm',
  'iTunes',
  'MusicBrainz',
  'remote',
  'Remote',
  'catalogue',
  'Catalogue',
];

void main() {
  late FakeRepositories repositories;
  late StateDatabase db;
  late SearchHistoryStore history;

  setUp(() {
    repositories = FakeRepositories();
    repositories.search.results['miles'] = _miles;
    db = StateDatabase(NativeDatabase.memory());
    history = SearchHistoryStore(db, FakeClock());
  });
  tearDown(() => db.close());

  FakeSearchRepository search() => repositories.search;

  int searchCount(
    String query, [
    SearchFilter filter = SearchFilter.all,
    int offset = 0,
  ]) => search().searches
      .where((entry) => entry == (query, filter, offset))
      .length;

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  Future<GoRouter> pump(
    WidgetTester tester, {
    String initial = '/search',
    Size size = _tallCompact,
    ThemeMode theme = ThemeMode.dark,
    double textScale = 1.0,
    List<Override> extra = const [],
    bool shellShortcuts = false,
  }) async {
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            if (windowClassOf(size) != WindowClass.expanded) return child;
            final router = GoRouter.of(context);
            final searching = state.uri.path == '/search';
            return Column(
              children: [
                Material(
                  child: TopBar(
                    onBack: null,
                    onForward: null,
                    onSearch: (query) => router.go('/search?q=$query'),
                    onSearchChanged: searching
                        ? (query) => router.go(
                            query.isEmpty ? '/search' : '/search?q=$query',
                          )
                        : null,
                    avatar: const SizedBox.shrink(),
                  ),
                ),
                Expanded(child: child),
              ],
            );
          },
          routes: [
            GoRoute(
              path: '/search',
              builder: (_, state) =>
                  SearchScreen(query: state.uri.queryParameters['q']),
            ),
            GoRoute(
              path: '/:kind/:id',
              builder: (_, state) => Text(
                '${state.pathParameters['kind']} '
                '${state.pathParameters['id']}',
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    final overrides = <Override>[
      ...repositories.overrides,
      searchHistoryStoreProvider.overrideWithValue(history),
      profilesProvider.overrideWith((ref) => Stream.value(const <Profile>[])),
      initialActiveProfileIdProvider.overrideWithValue(null),
      ...extra,
    ];
    await tester.pumpApp(
      WindowClassScope(
        windowClass: windowClassOf(size),
        child: shellShortcuts
            ? underShellShortcuts(Router.withConfig(config: router))
            : Router.withConfig(config: router),
      ),
      size: size,
      theme: theme,
      textScale: textScale,
      overrides: overrides,
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<List<String>> recent(WidgetTester tester) async =>
      (await tester.runAsync(() => history.watchRecent().first))!;

  Future<void> record(WidgetTester tester, String query) async {
    await tester.runAsync(() => history.record(query));
    await tester.pumpAndSettle();
  }

  Finder media(String title) =>
      find.ancestor(of: find.text(title), matching: find.byType(MediaRow));

  Finder row(String title) =>
      find.ancestor(of: find.text(title), matching: find.byType(TrackRow));

  Finder field() => find.byKey(SearchScreen.fieldKey);

  testWidgets('typing waits 300 ms before searching and searches once for a '
      'burst of keystrokes', (tester) async {
    await pump(tester);

    await tester.enterText(field(), 'm');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(field(), 'mil');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(field(), 'miles');
    await tester.pump(const Duration(milliseconds: 299));
    expect(search().searches, isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(search().searches, [('miles', SearchFilter.all, 0)]);
    expect(media('Miles Davis'), findsOneWidget);
  });

  testWidgets('submit searches immediately and records the query', (
    tester,
  ) async {
    final router = await pump(tester);

    await tester.enterText(field(), 'miles');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(searchCount('miles'), 1);
    await tester.pumpAndSettle();
    expect(location(router), '/search?q=miles');
    expect(await recent(tester), ['miles']);
  });

  testWidgets('clear empties the field and shows recent searches', (
    tester,
  ) async {
    await record(tester, 'coltrane');
    final router = await pump(tester, initial: '/search?q=miles');
    expect(find.text('coltrane'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field()).controller!.text, isEmpty);
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('coltrane'), findsOneWidget);
    expect(location(router), '/search');
  });

  testWidgets('tapping a recent search runs it', (tester) async {
    await record(tester, 'miles');
    final router = await pump(tester);

    await tester.tap(find.text('miles'));
    await tester.pumpAndSettle();
    expect(searchCount('miles'), 1);
    expect(location(router), '/search?q=miles');
    expect(tester.widget<TextField>(field()).controller!.text, 'miles');
  });

  testWidgets('removing a recent search deletes it', (tester) async {
    await record(tester, 'miles');
    await record(tester, 'coltrane');
    await pump(tester);

    await tester.tap(find.byTooltip('Remove miles'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(await recent(tester), ['coltrane']);
    expect(find.text('miles'), findsNothing);
  });

  testWidgets('with no recent searches an empty state invites a search', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('opening /search?q=miles fills the field and searches', (
    tester,
  ) async {
    await pump(tester, initial: '/search?q=miles');

    expect(tester.widget<TextField>(field()).controller!.text, 'miles');
    expect(searchCount('miles'), 1);
    expect(media('Kind of Blue'), findsOneWidget);
  });

  testWidgets('at 1440 the screen has no field and typing in the top bar '
      'searches after the debounce', (tester) async {
    final router = await pump(tester, size: TestSizes.expanded);
    expect(field(), findsNothing);

    await tester.enterText(find.byKey(TopBar.searchFieldKey), 'miles');
    await tester.pump(const Duration(milliseconds: 299));
    expect(search().searches, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(location(router), '/search?q=miles');
    expect(searchCount('miles'), 1);
    expect(media('Kind of Blue'), findsOneWidget);
  });

  testWidgets('a stale response is ignored', (tester) async {
    search()
      ..results['slow'] = [
        _result(
          const SearchHit.album(
            album: Album(
              id: 's',
              title: 'Stale',
              artistName: 'X',
              artistId: 'x',
            ),
          ),
        ),
      ]
      ..delays['slow'] = const Duration(seconds: 2);
    await pump(tester);

    await tester.enterText(field(), 'slow');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(field(), 'miles');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Stale'), findsNothing);
    expect(media('Kind of Blue'), findsOneWidget);
  });

  /// The titles of the result rows, top to bottom.
  List<String> rowTitles(WidgetTester tester) {
    final rows = [
      for (final element in find.byType(TrackRow).evaluate())
        (
          tester.getTopLeft(find.byWidget(element.widget)).dy,
          (element.widget as TrackRow).title,
        ),
      for (final element in find.byType(MediaRow).evaluate())
        (
          tester.getTopLeft(find.byWidget(element.widget)).dy,
          (element.widget as MediaRow).title,
        ),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final row in rows) row.$2];
  }

  testWidgets('All lists every kind in server order, each row labelled '
      'with its kind, with no top result card or section headers', (
    tester,
  ) async {
    await pump(tester, initial: '/search?q=miles');

    expect(rowTitles(tester), [
      'Miles Davis',
      'Kind of Blue',
      'So What',
      'Miles mix',
      'Miles Kane',
      'Bitches Brew',
      'Blue in Green',
      'Miles on Jazz',
    ]);
    String? subtitle(String title) =>
        tester.widget<MediaRow>(media(title)).subtitle;
    expect(subtitle('Miles Davis'), 'Artist');
    expect(subtitle('Kind of Blue'), 'Album · Miles Davis');
    expect(subtitle('Miles mix'), 'Playlist · 3 songs');
    expect(subtitle('Miles on Jazz'), 'Podcast · Host');
    expect(
      tester.widget<TrackRow>(row('So What')).artist,
      'Song · Miles Davis',
    );
    expect(find.byType(MediaCard), findsNothing);
    expect(find.text('Top result'), findsNothing);
    expect(find.text('Show all'), findsNothing);
    expect(find.text('Songs'), findsOneWidget, reason: 'only the chip');
  });

  testWidgets('selecting a chip sends its type and lists only that kind', (
    tester,
  ) async {
    await pump(tester, initial: '/search?q=miles');

    for (final (label, filter) in [
      ('Songs', SearchFilter.songs),
      ('Artists', SearchFilter.artists),
      ('Albums', SearchFilter.albums),
      ('Playlists', SearchFilter.playlists),
      ('Podcasts', SearchFilter.podcasts),
    ]) {
      search().searches.clear();
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, label));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pumpAndSettle();
      expect(search().searches, [('miles', filter, 0)]);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
            .selected,
        isTrue,
      );
      final titles = rowTitles(tester);
      final expected = [
        for (final result in _miles)
          if (filter.admits(result.hit)) result.hit,
      ];
      expect(titles, hasLength(expected.length));
    }
    expect(rowTitles(tester), ['Miles on Jazz']);

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Songs'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Songs'));
    await tester.pumpAndSettle();
    expect(rowTitles(tester), ['So What', 'Blue in Green']);
    expect(tester.widget<TrackRow>(row('So What')).artist, 'Miles Davis');
  });

  testWidgets('a single-kind list loads the next page as it scrolls to the '
      'end', (tester) async {
    search().results['blue'] = [
      for (var i = 0; i < 75; i++) _song(_track('Blue $i', playbackId: 'pb$i')),
    ];
    await pump(tester, initial: '/search?q=blue', size: const Size(390, 844));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Songs'));
    await tester.pumpAndSettle();
    expect(searchCount('blue', SearchFilter.songs), 1);
    expect(searchCount('blue', SearchFilter.songs, 30), 0);

    final list = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text('Blue 35'),
      400,
      scrollable: list,
    );
    await tester.pumpAndSettle();
    expect(searchCount('blue', SearchFilter.songs, 30), 1);
    expect(searchCount('blue', SearchFilter.songs, 60), 0);

    await tester.scrollUntilVisible(
      find.text('Blue 74'),
      400,
      scrollable: list,
    );
    await tester.pumpAndSettle();
    expect(searchCount('blue', SearchFilter.songs, 60), 1);
    expect(
      search().searches.where((entry) => entry.$2 == SearchFilter.songs),
      hasLength(3),
    );
    expect(find.byType(TrackRowSkeleton), findsNothing);
  });

  testWidgets('All asks for one page only', (tester) async {
    search().results['blue'] = [
      for (var i = 0; i < 40; i++) _song(_track('Blue $i', playbackId: 'pb$i')),
    ];
    await pump(tester, initial: '/search?q=blue', size: const Size(390, 844));
    await tester.scrollUntilVisible(
      find.text('Blue 39'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(search().searches, [('blue', SearchFilter.all, 0)]);
  });

  testWidgets('a failed next page keeps the earlier results and Retry '
      'loads it', (tester) async {
    search()
      ..results['blue'] = [
        for (var i = 0; i < 31; i++)
          _song(_track('Blue $i', playbackId: 'pb$i')),
      ]
      ..offsetErrors[30] = const Offline();
    await pump(tester, initial: '/search?q=blue');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Songs'));
    await tester.pumpAndSettle();

    expect(rowTitles(tester), hasLength(30));
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('Couldn’t load more results'), findsOneWidget);

    search().offsetErrors.clear();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(rowTitles(tester), hasLength(31));
    expect(rowTitles(tester).last, 'Blue 30');
    expect(find.text('Couldn’t load more results'), findsNothing);
  });

  testWidgets('an album with a library id opens its page and one without is '
      'not a button', (tester) async {
    final router = await pump(
      tester,
      initial: '/search?q=miles',
      size: const Size(1440, 2400),
    );

    expect(tester.widget<MediaRow>(media('Bitches Brew')).onTap, isNull);
    expect(tester.widget<MediaRow>(media('Bitches Brew')).onMenu, isNull);
    expect(tester.widget<MediaRow>(media('Miles Kane')).onTap, isNull);
    await tester.tap(media('Kind of Blue'));
    await tester.pumpAndSettle();
    expect(location(router), '/album/al1');
    expect(await recent(tester), ['miles']);
  });

  void seedBlue() => search().results['blue'] = [
    _song(_track('Blue in Green', playbackId: 'pb1')),
    _result(
      const SearchHit.album(
        album: Album(
          id: 'al9',
          title: 'Blue album',
          artistName: 'Miles',
          artistId: 'ar1',
        ),
      ),
    ),
    _song(_track('Blue Train', playbackId: 'pb2')),
    _song(_track('Blue Moon')),
    _song(_track('Blue Bossa', playbackId: 'pb4')),
  ];

  testWidgets('a song row plays the songs of the list from that song', (
    tester,
  ) async {
    seedBlue();
    final rig = PlayRig();
    await pump(
      tester,
      initial: '/search?q=blue',
      size: const Size(1440, 2400),
      extra: rig.overrides,
    );

    expect(tester.widget<TrackRow>(row('Blue Moon')).enabled, isFalse);
    expect(
      tester.widget<TrackRow>(row('Blue Moon')).disabledReason,
      'Not playable',
    );
    await tester.tap(find.text('Blue Bossa'));
    await rig.settle(tester);

    expect(rig.queued, ['pb1', 'pb2', 'pb4']);
    expect(rig.current, 'pb4');
    expect(rig.context, const QueueContext(kind: QueueContextKind.search));
    await rig.close(tester);
  });

  testWidgets('an unplayable song row does nothing on tap', (tester) async {
    seedBlue();
    final rig = PlayRig();
    await pump(
      tester,
      initial: '/search?q=blue',
      size: const Size(1440, 2400),
      extra: rig.overrides,
    );

    await tester.tap(find.text('Blue Moon'), warnIfMissed: false);
    await rig.settle(tester);

    expect(rig.queued, isEmpty);
    await rig.close(tester);
  });

  testWidgets('a playlist row opens the playlist', (tester) async {
    final router = await pump(tester, initial: '/search?q=miles');

    await tester.tap(media('Miles mix'));
    await tester.pumpAndSettle();
    expect(location(router), '/playlist/pl1');
    expect(await recent(tester), ['miles']);
  });

  testWidgets('no results shows the empty state with the query', (
    tester,
  ) async {
    await pump(tester, initial: '/search?q=zzz');
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No results for “zzz”'), findsOneWidget);
  });

  testWidgets('a failed search shows ErrorView and Retry searches again', (
    tester,
  ) async {
    search().filterErrors[SearchFilter.all] = const Offline();
    await pump(tester, initial: '/search?q=miles');

    expect(find.byType(ErrorView), findsOneWidget);
    search().filterErrors.clear();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(searchCount('miles'), 2);
    expect(find.byType(ErrorView), findsNothing);
    expect(media('Kind of Blue'), findsOneWidget);
  });

  testWidgets('the rendered tree contains no source wording', (tester) async {
    await pump(
      tester,
      initial: '/search?q=miles',
      size: const Size(1440, 2400),
    );
    final handle = tester.ensureSemantics();

    final texts = [
      for (final widget in tester.allWidgets)
        if (widget is Text) widget.data ?? widget.textSpan?.toPlainText() ?? '',
    ];
    final labels = [
      for (final node in find.semantics.byPredicate((_) => true).evaluate())
        node.label,
    ];
    for (final word in _sourceWords) {
      for (final text in [...texts, ...labels]) {
        expect(text, isNot(contains(word)));
      }
    }
    handle.dispose();
  });

  for (final size in [TestSizes.compact, TestSizes.expanded]) {
    for (final theme in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets('meets the guidelines at ${size.width.toInt()} in '
          '${theme.name}', (tester) async {
        await pump(
          tester,
          initial: '/search?q=miles',
          size: size,
          theme: theme,
        );
        await expectMeetsGuidelines(tester);
      });
    }
  }

  testWidgets('recent searches meet the guidelines', (tester) async {
    await record(tester, 'miles');
    await pump(tester);
    await expectMeetsGuidelines(tester);
  });

  for (final size in [TestSizes.compact, TestSizes.expanded]) {
    testWidgets('text scale 2.0 does not overflow at ${size.width.toInt()}', (
      tester,
    ) async {
      await pump(tester, initial: '/search?q=miles', size: size, textScale: 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('song rows select on click, Ctrl+click adds a row, Enter '
      'plays the selection and the menu is the selection menu', (tester) async {
    seedBlue();
    final rig = PlayRig();
    await pump(
      tester,
      initial: '/search?q=blue',
      size: const Size(1440, 2400),
      extra: rig.overrides,
      shellShortcuts: true,
    );

    await click(tester, 'Blue Bossa');
    await rig.settle(tester);
    expect(selectedTitles(tester), ['Blue Bossa']);
    expect(rig.queued, isEmpty);
    await click(tester, 'Blue Train', modifier: LogicalKeyboardKey.controlLeft);
    expect(selectedTitles(tester), ['Blue Train', 'Blue Bossa']);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await rig.settle(tester);

    expect(rig.queued, ['pb2', 'pb4']);
    expect(rig.current, 'pb2');
    expect(rig.context, const QueueContext(kind: QueueContextKind.search));
    await expectSelectionMenu(tester, 'Blue Bossa');
    await rig.close(tester);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
