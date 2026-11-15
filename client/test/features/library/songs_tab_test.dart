// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/features/library/ui/library_controls.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan/shared/widgets/track_row.dart';
import 'package:soundspan_api/soundspan_api.dart' show ServerError;

import '../../helpers/fake_repositories.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';
import 'library_harness.dart';

void main() {
  FakeLibraryRepository library(int count, {Set<int> unplayable = const {}}) =>
      FakeLibraryRepository()
        ..trackList = tracks(count, unplayable: unplayable);

  Finder row(String title) =>
      find.ancestor(of: find.text(title), matching: find.byType(TrackRow));

  testWidgets('loaded rows show title, artist, duration and a thumbnail', (
    tester,
  ) async {
    await tester.pumpLibrary(tab: LibraryTab.songs, library: library(20));
    expect(find.text('Song 0'), findsOneWidget);
    expect(
      find.descendant(of: row('Song 0'), matching: find.text('Artist 0')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row('Song 0'), matching: find.text('3:20')),
      findsOneWidget,
    );
    final leading = tester.widget<TrackRow>(row('Song 0')).leading;
    expect(leading, isA<TrackRowThumbnail>());
    expect((leading as TrackRowThumbnail).artworkRef, 'cover-0');
    expect(
      find.descendant(of: row('Song 0'), matching: find.byType(Artwork)),
      findsOneWidget,
    );
  });

  testWidgets('album column only on expanded', (tester) async {
    await tester.pumpLibrary(tab: LibraryTab.songs, library: library(20));
    expect(tester.widget<TrackRow>(row('Song 0')).showAlbumColumn, isFalse);
    expect(find.text('Album 0'), findsNothing);

    await tester.pumpLibrary(
      tab: LibraryTab.songs,
      library: library(20),
      size: TestSizes.medium,
    );
    expect(tester.widget<TrackRow>(row('Song 0')).showAlbumColumn, isFalse);

    await tester.pumpLibrary(
      tab: LibraryTab.songs,
      library: library(20),
      size: TestSizes.expanded,
    );
    expect(tester.widget<TrackRow>(row('Song 0')).showAlbumColumn, isTrue);
    expect(find.text('Album 0'), findsOneWidget);
  });

  testWidgets('a track without playbackId is disabled with its reason', (
    tester,
  ) async {
    await tester.pumpLibrary(
      tab: LibraryTab.songs,
      library: library(20, unplayable: {1}),
    );
    final disabled = tester.widget<TrackRow>(row('Song 1'));
    expect(disabled.enabled, isFalse);
    expect(disabled.disabledReason, 'Not playable');
    expect(tester.widget<TrackRow>(row('Song 0')).enabled, isTrue);
  });

  testWidgets('rows do nothing on tap', (tester) async {
    final harness = await tester.pumpLibrary(
      tab: LibraryTab.songs,
      library: library(20),
    );
    expect(tester.widget<TrackRow>(row('Song 2')).onTap, isNull);
    await tester.tap(find.text('Song 2'));
    await tester.pumpAndSettle();
    expect(harness.location, '/library/songs');
  });

  testWidgets('empty, error and refresh-error states', (tester) async {
    await tester.pumpLibrary(tab: LibraryTab.songs, library: library(0));
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No songs yet'), findsOneWidget);

    final failing = await tester.pumpLibrary(
      tab: LibraryTab.songs,
      library: _FailingLibrary(tracks(50), {0, 1}),
    );
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.byType(TrackRow), findsNothing);
    failing.sources.single.failingPages.clear();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('Song 0'), findsOneWidget);

    final cached = await tester.pumpLibrary(
      tab: LibraryTab.songs,
      library: library(50),
    );
    final source = cached.sources.single..failingPages.add(0);
    unawaited(source.refresh());
    await tester.pumpAndSettle();
    expect(find.text('Song 0'), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('Couldn’t refresh the list'), findsOneWidget);
  });

  testWidgets('changing sort requests a new source', (tester) async {
    final harness = await tester.pumpLibrary(
      tab: LibraryTab.songs,
      library: library(500),
    );
    await tester.tap(find.byKey(LibrarySortMenu.buttonKey));
    await tester.pumpAndSettle();
    expect(find.text('Name (A-Z)'), findsOneWidget);
    await tester.tap(
      find.ancestor(
        of: find.text('Name (Z-A)'),
        matching: find.byType(CheckedPopupMenuItem<TrackSort>),
      ),
    );
    await tester.pumpAndSettle();

    expect(harness.library.queries, [
      const TrackQuery(),
      const TrackQuery(sortBy: TrackSort.nameDesc),
    ]);
    expect(harness.sources.first.disposed, isTrue);
    expect(harness.sources.last.disposed, isFalse);
  });

  testWidgets('origin chips request the origin while federation is on', (
    tester,
  ) async {
    final harness = await tester.pumpLibrary(
      tab: LibraryTab.songs,
      library: library(20),
      federation: true,
    );
    await tester.tap(find.text('Peers'));
    await tester.pumpAndSettle();
    expect(
      harness.library.queries.last,
      const TrackQuery(origin: LibraryOrigin.peers),
    );
  });

  for (final size in [TestSizes.compact, TestSizes.expanded]) {
    for (final theme in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets(
        'meets the guidelines at ${size.width.toInt()} in ${theme.name}',
        (tester) async {
          await tester.pumpLibrary(
            tab: LibraryTab.songs,
            library: library(100, unplayable: {2}),
            size: size,
            theme: theme,
            federation: true,
          );
          await expectMeetsGuidelines(tester);
        },
      );
    }
  }

  testWidgets('has no overflow at text scale 2.0', (tester) async {
    await tester.pumpLibrary(
      tab: LibraryTab.songs,
      library: library(100),
      textScale: 2,
      federation: true,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Song 0'), findsOneWidget);
  });
}

/// A library whose track sources fail [failingPages].
class _FailingLibrary extends FakeLibraryRepository {
  new(List<Track> items, this.failingPages) {
    trackList = items;
  }

  final Set<int> failingPages;

  @override
  PagedSource<Track> tracks(TrackQuery query) {
    queries.add(query);
    final source = FakePagedSource<Track>(
      items: trackList,
      failingPages: {...failingPages},
      failure: const ServerError(),
    );
    sources.add(source);
    return source;
  }
}
