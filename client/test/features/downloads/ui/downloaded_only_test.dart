// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/features/downloads/downloads.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../../helpers/fake_reachability.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/fakes/fake_download_controller.dart';
import '../../library/library_harness.dart';

/// What the downloaded library lists in these tests.
final Map<DownloadedList, List<Object>> _downloaded = {
  DownloadedList.tracks: [
    const Track(
      meta: TrackMeta(
        title: 'Kept song',
        artist: 'Kept artist',
        album: 'Kept album',
        durationSec: 100,
      ),
      playbackId: PlaybackId('d1'),
    ),
  ],
  DownloadedList.albums: [
    const Album(
      id: 'dal',
      title: 'Kept album',
      artistName: 'Kept artist',
      artistId: 'dar',
    ),
  ],
  DownloadedList.artists: [const Artist(id: 'dar', name: 'Kept artist')],
  DownloadedList.playlists: [
    const PlaylistSummary(
      id: 'dpl',
      name: 'Kept playlist',
      trackCount: 1,
      isOwner: false,
      isPublic: false,
    ),
  ],
};

void main() {
  late FakeDownloadController downloads;

  late StreamController<bool> hasDownloads;

  setUp(() {
    downloads = FakeDownloadController();
    hasDownloads = StreamController<bool>.broadcast();
    addTearDown(() => unawaited(hasDownloads.close()));
  });

  List<Override> overrides({bool canDownload = true}) => [
    ...downloads.overrides(canDownload: canDownload),
    downloadedListProvider.overrideWith(
      (ref, list) => Stream.value(_downloaded[list]!),
    ),
    hasDownloadCollectionsProvider.overrideWith((ref) async* {
      yield false;
      yield* hasDownloads.stream;
    }),
  ];

  FakeLibraryRepository server() => FakeLibraryRepository()
    ..trackList = tracks(3)
    ..albumList = albums(3)
    ..artistList = artists(3);

  FakePlaylistRepository serverPlaylists() =>
      FakePlaylistRepository()..playlistList = playlists(2);

  group('the filter follows reachability', () {
    testWidgets('going offline turns it on, online turns it off, and a '
        'manual toggle holds until the next change', (tester) async {
      final reachability = FakeReachability();
      final harness = await tester.pumpLibrary(
        tab: LibraryTab.songs,
        reachability: reachability,
        overrides: overrides(),
      );
      bool on() => harness.container.read(downloadedOnlyProvider);

      expect(on(), isFalse);
      reachability.set(Reachability.noNetwork);
      await tester.pumpAndSettle();
      expect(on(), isTrue);

      // Another offline state is not a change of online-ness.
      await tester.tap(find.byKey(DownloadedOnlyChip.chipKey));
      await tester.pumpAndSettle();
      expect(on(), isFalse);
      reachability.set(Reachability.serverUnreachable);
      await tester.pumpAndSettle();
      expect(on(), isFalse);

      reachability.set(Reachability.online);
      await tester.pumpAndSettle();
      expect(on(), isFalse);
      reachability.set(Reachability.forcedOffline);
      await tester.pumpAndSettle();
      expect(on(), isTrue);
      reachability.set(Reachability.online);
      await tester.pumpAndSettle();
      expect(on(), isFalse);
    });

    testWidgets('it starts on when the app is already offline', (tester) async {
      final harness = await tester.pumpLibrary(
        tab: LibraryTab.songs,
        reachability: FakeReachability(initial: Reachability.noNetwork),
        overrides: overrides(),
      );
      expect(harness.container.read(downloadedOnlyProvider), isTrue);
    });
  });

  group('chip visibility', () {
    testWidgets('offline: always shown', (tester) async {
      await tester.pumpLibrary(
        reachability: FakeReachability(initial: Reachability.noNetwork),
        overrides: overrides(),
      );
      expect(find.byKey(DownloadedOnlyChip.chipKey), findsOneWidget);
      expect(find.text('Downloaded only'), findsOneWidget);
    });

    testWidgets('online: only while the profile has downloads', (tester) async {
      await tester.pumpLibrary(library: server(), overrides: overrides());
      expect(find.byKey(DownloadedOnlyChip.chipKey), findsNothing);

      hasDownloads.add(true);
      await tester.pumpAndSettle();
      expect(find.byKey(DownloadedOnlyChip.chipKey), findsOneWidget);
      // Online the filter stays off until the user turns it on.
      expect(find.text('Album 0'), findsOneWidget);
    });

    testWidgets('never where the platform does not download', (tester) async {
      await tester.pumpLibrary(
        library: server(),
        reachability: FakeReachability(initial: Reachability.noNetwork),
        overrides: overrides(canDownload: false),
      );
      expect(find.byKey(DownloadedOnlyChip.chipKey), findsNothing);
    });
  });

  group('with the filter on each tab lists only downloaded content', () {
    for (final (tab, shown, hidden) in [
      (LibraryTab.songs, 'Kept song', 'Song 0'),
      (LibraryTab.albums, 'Kept album', 'Album 0'),
      (LibraryTab.artists, 'Kept artist', 'Artist 0'),
      (LibraryTab.playlists, 'Kept playlist', 'Playlist 0'),
    ]) {
      testWidgets(tab.name, (tester) async {
        final library = server();
        final playlists = serverPlaylists();
        await tester.pumpLibrary(
          tab: tab,
          library: library,
          playlists: playlists,
          reachability: FakeReachability(initial: Reachability.noNetwork),
          overrides: overrides(),
        );
        expect(find.text(shown), findsOneWidget);
        expect(find.text(hidden), findsNothing);
        expect(library.sources, isEmpty);
        expect(playlists.sources, isEmpty);
      });
    }

    testWidgets('Liked Songs is left out unless pinned', (tester) async {
      await tester.pumpLibrary(
        tab: LibraryTab.playlists,
        playlists: serverPlaylists(),
        reachability: FakeReachability(initial: Reachability.noNetwork),
        overrides: overrides(),
      );
      expect(find.text('Liked Songs'), findsNothing);
    });

    testWidgets('turning the chip off lists the server library again', (
      tester,
    ) async {
      final library = server();
      await tester.pumpLibrary(
        tab: LibraryTab.songs,
        library: library,
        reachability: FakeReachability(initial: Reachability.noNetwork),
        overrides: overrides(),
      );
      await tester.tap(find.byKey(DownloadedOnlyChip.chipKey));
      await tester.pumpAndSettle();
      expect(find.text('Song 0'), findsOneWidget);
      expect(find.text('Kept song'), findsNothing);
    });
  });

  group('rows without a local file while offline', () {
    testWidgets('are disabled as not available offline; online none is', (
      tester,
    ) async {
      final reachability = FakeReachability();
      downloads.setItem(
        const TrackItemKey('p1'),
        itemState(DownloadStatus.completed),
      );
      await tester.pumpLibrary(
        tab: LibraryTab.songs,
        library: server(),
        reachability: reachability,
        overrides: overrides(),
      );
      final reason = find.bySemanticsLabel(RegExp('Not available offline'));
      expect(reason, findsNothing);

      reachability.set(Reachability.noNetwork);
      await tester.pumpAndSettle();
      // Show the server's list while offline to see the rule.
      await tester.tap(find.byKey(DownloadedOnlyChip.chipKey));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('^Song 1,')), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('^Song 1,.*Not available offline')),
        findsNothing,
      );
      for (final title in ['Song 0', 'Song 2']) {
        expect(
          find.bySemanticsLabel(RegExp('^$title,.*Not available offline\$')),
          findsOneWidget,
        );
      }
      expect(find.byTooltip('Not available offline'), findsNWidgets(2));

      reachability.set(Reachability.online);
      await tester.pumpAndSettle();
      expect(reason, findsNothing);
    });
  });
}
