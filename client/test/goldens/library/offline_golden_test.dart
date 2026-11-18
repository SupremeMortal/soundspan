// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/downloaded_library.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/features/downloads/downloads.dart';
import 'package:soundspan/features/search/data/search_history_store.dart';
import 'package:soundspan/features/search/search.dart';
import 'package:soundspan/features/search/search_providers.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/cache.dart';

import '../../features/library/library_harness.dart';
import '../../helpers/fake_clock.dart';
import '../../helpers/fake_reachability.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/fakes/fake_download_controller.dart';
import '../../helpers/golden.dart';
import '../../helpers/pump_app.dart';

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

/// Offline goldens (doc 07, Reachability and Offline Mode; doc 09,
/// Library and Search): the Songs tab with the offline banner, the
/// "Downloaded only" chip and a mix of downloaded and greyed-out rows, and
/// Search answering from this device.
void main() {
  for (final theme in [ThemeMode.dark, ThemeMode.light]) {
    for (final size in [
      TestSizes.compact,
      TestSizes.medium,
      TestSizes.expanded,
    ]) {
      final songs = goldenFileName(
        'library_songs_offline',
        size: size,
        theme: theme,
      );
      testWidgets(songs, tags: ['golden'], (tester) async {
        final downloads = FakeDownloadController();
        for (final id in ['p0', 'p2', 'p3']) {
          downloads.setItem(
            TrackItemKey(id),
            itemState(DownloadStatus.completed),
          );
        }
        await tester.pumpLibrary(
          tab: LibraryTab.songs,
          library: FakeLibraryRepository()..trackList = tracks(8),
          size: size,
          theme: theme,
          reachability: FakeReachability(initial: Reachability.noNetwork),
          overrides: [
            ...downloads.overrides(),
            downloadedListProvider.overrideWith(
              (ref, list) => Stream.value(const <Object>[]),
            ),
          ],
        );
        // The user turned the filter off to see the whole cached list.
        await tester.tap(find.byKey(DownloadedOnlyChip.chipKey));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(goldenPath(songs)),
        );
      });

      final search = goldenFileName('search_offline', size: size, theme: theme);
      testWidgets(search, tags: ['golden'], (tester) async {
        final cacheDb = CacheDatabase(NativeDatabase.memory());
        final stateDb = StateDatabase(NativeDatabase.memory());
        addTearDown(() async {
          await cacheDb.close();
          await stateDb.close();
        });
        final cache = CacheStore(cacheDb, FakeClock());
        Track track(String title, String id) => Track(
          meta: TrackMeta(
            title: title,
            artist: 'Moon band',
            album: 'Night songs',
            durationSec: 200,
          ),
          playbackId: PlaybackId(id),
        );
        await tester.runAsync(
          () => cache.upsertTracks([
            track('Moon river', 'c1'),
            track('Moonlight', 'd1'),
            track('Moonrise', 'c2'),
          ]),
        );
        final downloads = FakeDownloadController()
          ..setItem(
            const TrackItemKey('d1'),
            itemState(DownloadStatus.completed),
          );
        await tester.pumpApp(
          WindowClassScope(
            windowClass: windowClassOf(size),
            child: const Scaffold(body: SearchScreen(query: 'moon')),
          ),
          size: size,
          theme: theme,
          overrides: [
            ...FakeRepositories().overrides,
            ...downloads.overrides(),
            reachabilityProvider.overrideWithValue(
              FakeReachability(initial: Reachability.noNetwork),
            ),
            cacheStoreProvider.overrideWith((ref) async => cache),
            downloadedLibraryProvider.overrideWithValue(
              _Downloaded([track('Moonlight', 'd1')]),
            ),
            searchHistoryStoreProvider.overrideWithValue(
              SearchHistoryStore(stateDb, FakeClock()),
            ),
            profilesProvider.overrideWith(
              (ref) => Stream.value(const <Profile>[]),
            ),
            initialActiveProfileIdProvider.overrideWithValue(null),
          ],
        );
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(() => Future<void>.delayed(Duration.zero));
          await tester.pumpAndSettle();
        }

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(goldenPath(search)),
        );
      });
    }
  }
}
