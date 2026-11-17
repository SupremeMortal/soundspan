// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_state_machine.dart'
    show DownloadWaitReason;
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/features/downloads/downloads.dart';
import 'package:soundspan/shared/widgets/download_glyph.dart';

import '../../../helpers/fakes/fake_download_controller.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import 'download_text.dart';

const int _mb = 1024 * 1024;

/// A running album, a completed playlist, a blocked album and a track
/// waiting for the network, in request order.
List<DownloadCollectionEntry> sampleEntries() => const [
  DownloadCollectionEntry(
    kind: CollectionKind.album,
    refId: 'al-run',
    title: 'Running Album',
    subtitle: 'An Artist',
    artworkRef: 'art-1',
    state: CollectionDownloadState(
      status: DownloadCollectionStatus.ready,
      itemCount: 10,
      completedCount: 4,
      unavailableCount: 0,
      activeCount: 6,
      receivedBytes: 40 * _mb,
      totalBytes: 100 * _mb,
    ),
  ),
  DownloadCollectionEntry(
    kind: CollectionKind.playlist,
    refId: 'pl-done',
    title: 'Done Playlist',
    state: CollectionDownloadState(
      status: DownloadCollectionStatus.ready,
      itemCount: 3,
      completedCount: 3,
      unavailableCount: 0,
      receivedBytes: 30 * _mb,
      totalBytes: 30 * _mb,
    ),
  ),
  DownloadCollectionEntry(
    kind: CollectionKind.album,
    refId: 'al-blocked',
    title: 'Blocked Album',
    state: CollectionDownloadState(
      status: DownloadCollectionStatus.blocked,
      blockedReason: CollectionBlock.serverQuota,
      blockedDetail: {
        'estimatedBytes': 300 * _mb,
        'usedBytes': 900 * _mb,
        'limitBytes': 1024 * _mb,
      },
      itemCount: 0,
      completedCount: 0,
      unavailableCount: 0,
      receivedBytes: 0,
      totalBytes: 0,
    ),
  ),
  DownloadCollectionEntry(
    kind: CollectionKind.track,
    refId: 'p-wait',
    title: 'Waiting Song',
    state: CollectionDownloadState(
      status: DownloadCollectionStatus.pendingNetwork,
      itemCount: 0,
      completedCount: 0,
      unavailableCount: 0,
      receivedBytes: 0,
      totalBytes: 0,
    ),
  ),
];

void main() {
  late FakeDownloadController downloads;

  setUp(() => downloads = FakeDownloadController());

  Future<void> pump(
    WidgetTester tester, {
    Size size = TestSizes.compact,
    ThemeMode theme = ThemeMode.dark,
  }) async {
    await tester.pumpApp(
      const Scaffold(body: DownloadsTab()),
      size: size,
      theme: theme,
      overrides: downloads.overrides(),
    );
    await tester.pump();
  }

  void seed() {
    downloads
      ..setEntries(sampleEntries())
      ..setItem(
        const TrackItemKey('a'),
        itemState(DownloadStatus.completed, size: 10 * _mb),
      )
      ..setItem(
        const TrackItemKey('b'),
        itemState(DownloadStatus.completed, size: 20 * _mb),
      )
      ..setItem(
        const TrackItemKey('c'),
        itemState(DownloadStatus.running, received: 100),
      );
  }

  Finder row(CollectionKind kind, String refId) =>
      find.byKey(DownloadsTab.rowKey(kind, refId));

  testWidgets('empty: "Nothing downloaded yet" with how to download', (
    tester,
  ) async {
    await pump(tester);

    expect(
      find.text(
        'Nothing downloaded yet. Choose Download on an album, a playlist or '
        'a song to keep it on this device.',
      ),
      findsOneWidget,
    );
    expectNoSourceWords(tester);
  });

  testWidgets('a running, a completed, a blocked and a pending-network '
      'collection, with the storage summary', (tester) async {
    seed();
    await pump(tester);

    expect(find.text('2 items · 30.0 MB'), findsOneWidget);
    expect(find.text('1 in progress'), findsOneWidget);
    expect(find.text('Running Album'), findsOneWidget);
    expect(find.text('Album · 4 of 10'), findsOneWidget);
    expect(
      find.descendant(
        of: row(CollectionKind.album, 'al-run'),
        matching: find.byType(LinearProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(find.text('Playlist · 3 of 3'), findsOneWidget);
    expect(
      tester
          .widget<DownloadGlyph>(
            find.descendant(
              of: row(CollectionKind.playlist, 'pl-done'),
              matching: find.byType(DownloadGlyph),
            ),
          )
          .state,
      DownloadGlyphState.completed,
    );
    expect(
      find.descendant(
        of: row(CollectionKind.album, 'al-blocked'),
        matching: find.text('Not enough space on the server'),
      ),
      findsOneWidget,
    );
    expect(find.text('Waiting for connection'), findsOneWidget);
    expectNoSourceWords(tester);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('a blocked row opens its sheet', (tester) async {
    seed();
    await pump(tester);

    await tester.tap(find.text('Blocked Album'));
    await tester.pumpAndSettle();

    expect(find.text('Needed: 300.0 MB'), findsOneWidget);
    expect(find.text('Manage downloads'), findsOneWidget);
    expectNoSourceWords(tester);
  });

  testWidgets('"In progress" shows only collections still downloading', (
    tester,
  ) async {
    seed();
    await pump(tester);

    await tester.tap(find.byKey(DownloadsTab.inProgressKey));
    await tester.pump();

    expect(find.text('Running Album'), findsOneWidget);
    expect(find.text('Done Playlist'), findsNothing);
    expect(find.text('Blocked Album'), findsNothing);
    expect(find.text('Waiting Song'), findsNothing);
  });

  testWidgets('Pause all pauses, and Resume all resumes once every active '
      'item is paused', (tester) async {
    seed();
    await pump(tester);

    await tester.tap(find.text('Pause all'));
    expect(downloads.calls, ['pauseAll']);

    downloads.setItem(
      const TrackItemKey('c'),
      const ItemDownloadState(
        status: DownloadStatus.paused,
        receivedBytes: 100,
        expectedBytes: 1000,
        waitingFor: DownloadWaitReason.user,
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Resume all'));
    expect(downloads.calls, ['pauseAll', 'resumeAll']);
  });

  testWidgets('Remove download asks for confirmation, then unpins', (
    tester,
  ) async {
    seed();
    await pump(tester);

    await tester.tap(
      find.byKey(DownloadsTab.menuKey(CollectionKind.playlist, 'pl-done')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu.remove')));
    await tester.pumpAndSettle();

    expect(find.text('Remove download?'), findsOneWidget);
    expect(downloads.calls, isEmpty);

    await tester.tap(find.byKey(removeDownloadConfirmKey));
    await tester.pumpAndSettle();

    expect(downloads.calls, ['unpin playlist pl-done']);
  });

  testWidgets('the running row offers Pause and Remove download; a failed '
      'one Retry', (tester) async {
    downloads.setEntries([
      sampleEntries().first,
      const DownloadCollectionEntry(
        kind: CollectionKind.album,
        refId: 'al-failed',
        title: 'Failed Album',
        state: CollectionDownloadState(
          status: DownloadCollectionStatus.ready,
          itemCount: 2,
          completedCount: 1,
          unavailableCount: 0,
          failedCount: 1,
          receivedBytes: 0,
          totalBytes: 0,
        ),
      ),
    ]);
    await pump(tester);

    await tester.tap(
      find.byKey(DownloadsTab.menuKey(CollectionKind.album, 'al-run')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('menu.pause')), findsOneWidget);
    expect(find.byKey(const ValueKey('menu.retry')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('menu.pause')));
    await tester.pumpAndSettle();
    expect(downloads.calls, ['pauseCollection album al-run']);

    await tester.tap(
      find.byKey(DownloadsTab.menuKey(CollectionKind.album, 'al-failed')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu.retry')));
    await tester.pumpAndSettle();
    expect(downloads.calls.last, 'retryCollection album al-failed');
  });
}
