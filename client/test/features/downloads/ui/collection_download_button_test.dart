// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/features/album/album.dart';
import 'package:soundspan/features/downloads/downloads.dart';
import 'package:soundspan/shared/widgets/action_bar.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

import '../../../helpers/fakes/fake_download_controller.dart';
import '../../detail_fixtures.dart';

void main() {
  late FakeDownloadController downloads;

  setUp(() => downloads = FakeDownloadController());

  Future<void> pumpAlbum(WidgetTester tester, {bool canDownload = true}) =>
      pumpDetail(
        tester,
        const AlbumScreen(albumId: 'al-1'),
        repositories: albumRepositories([fixtureTrack(1), fixtureTrack(2)]),
        overrides: downloads.overrides(canDownload: canDownload),
      );

  testWidgets('Download pins the album with a snapshot of its tracks', (
    tester,
  ) async {
    await pumpAlbum(tester);

    await tester.tap(find.byKey(CollectionDownloadButton.downloadKey));
    await tester.pumpAndSettle();

    expect(downloads.calls, ['pin album al-1']);
    final snapshot = downloads.snapshots['album al-1']!;
    expect(
      [for (final t in snapshot.tracks) t.meta.title],
      ['Song 1.1', 'Song 1.2'],
    );
    expect(snapshot.title, isNotEmpty);
    expect(find.byKey(CollectionDownloadButton.removeKey), findsOneWidget);
  });

  testWidgets('a pinned album offers Remove download behind a confirmation', (
    tester,
  ) async {
    downloads.setCollection(CollectionKind.album, 'al-1', downloads.pinResult);
    await pumpAlbum(tester);

    expect(find.byKey(CollectionDownloadButton.downloadKey), findsNothing);
    expect(find.byTooltip('Remove download'), findsOneWidget);

    await tester.tap(find.byKey(CollectionDownloadButton.removeKey));
    await tester.pumpAndSettle();
    expect(find.text('Remove download?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(downloads.calls, isEmpty);

    await tester.tap(find.byKey(CollectionDownloadButton.removeKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(removeDownloadConfirmKey));
    await tester.pumpAndSettle();
    expect(downloads.calls, ['unpin album al-1']);
  });

  testWidgets('no Download button where the platform does not download', (
    tester,
  ) async {
    await pumpAlbum(tester, canDownload: false);

    expect(find.byType(ActionBar), findsOneWidget);
    expect(find.byType(CollectionDownloadButton), findsNothing);
  });

  group('track menu', () {
    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byKey(TrackRow.overflowKey).first);
      await tester.pumpAndSettle();
    }

    testWidgets('a track not downloaded offers Download, which pins the '
        'track', (tester) async {
      await pumpAlbum(tester);
      await openMenu(tester);

      expect(find.byKey(const ValueKey('menu.removeDownload')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('menu.download')));
      await tester.pumpAndSettle();

      expect(downloads.calls.single, startsWith('pin track '));
    });

    testWidgets('a downloaded track offers Remove download', (tester) async {
      await pumpAlbum(tester);
      final row = tester.widget<TrackRow>(find.byType(TrackRow).first);
      downloads.setItem(
        TrackItemKey(row.playbackId!.value),
        itemState(DownloadStatus.completed),
      );
      await tester.pump();
      await openMenu(tester);

      expect(find.byKey(const ValueKey('menu.download')), findsNothing);
      expect(find.byKey(const ValueKey('menu.removeDownload')), findsOneWidget);
    });

    testWidgets('hidden where the platform does not download', (tester) async {
      await pumpAlbum(tester, canDownload: false);
      await openMenu(tester);

      expect(find.byKey(const ValueKey('menu.download')), findsNothing);
      expect(find.byKey(const ValueKey('menu.removeDownload')), findsNothing);
    });
  });
}
