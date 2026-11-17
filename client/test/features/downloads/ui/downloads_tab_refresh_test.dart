// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/downloads/collection_upkeep.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/features/downloads/downloads.dart';

import '../../../helpers/fakes/fake_download_controller.dart';
import '../../../helpers/pump_app.dart';

/// Records the collections it is asked to refresh.
final class _FakeUpkeep implements CollectionUpkeep {
  final List<String> refreshed = [];

  @override
  Future<UpkeepResult> refresh(
    CollectionKind kind,
    String refId, {
    CollectionSnapshot? snapshot,
  }) async {
    refreshed.add('${kind.name} $refId');
    return UpkeepResult.refreshed;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

const CollectionDownloadState _done = CollectionDownloadState(
  status: DownloadCollectionStatus.ready,
  itemCount: 2,
  completedCount: 2,
  unavailableCount: 0,
  receivedBytes: 2000,
  totalBytes: 2000,
);

void main() {
  late FakeDownloadController downloads;
  late _FakeUpkeep upkeep;

  setUp(() {
    downloads = FakeDownloadController();
    upkeep = _FakeUpkeep();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpApp(
      const Scaffold(body: DownloadsTab()),
      overrides: [
        ...downloads.overrides(),
        collectionUpkeepProvider.overrideWithValue(upkeep),
      ],
    );
    await tester.pump();
  }

  Future<void> openMenu(
    WidgetTester tester,
    CollectionKind kind,
    String refId,
  ) async {
    await tester.tap(find.byKey(DownloadsTab.menuKey(kind, refId)));
    await tester.pumpAndSettle();
  }

  testWidgets('"Check for changes" refreshes the album or playlist', (
    tester,
  ) async {
    downloads.setEntries(const [
      DownloadCollectionEntry(
        kind: CollectionKind.playlist,
        refId: 'pl',
        title: 'Road Mix',
        state: _done,
      ),
      DownloadCollectionEntry(
        kind: CollectionKind.album,
        refId: 'al',
        title: 'First Light',
        state: _done,
      ),
    ]);
    await pump(tester);

    await openMenu(tester, CollectionKind.playlist, 'pl');
    await tester.tap(find.text('Check for changes'));
    await tester.pumpAndSettle();
    await openMenu(tester, CollectionKind.album, 'al');
    await tester.tap(find.text('Check for changes'));
    await tester.pumpAndSettle();

    expect(upkeep.refreshed, ['playlist pl', 'album al']);
    expect(downloads.calls, isEmpty);
  });

  testWidgets('a single track has no "Check for changes"', (tester) async {
    downloads.setEntries(const [
      DownloadCollectionEntry(
        kind: CollectionKind.track,
        refId: 't1',
        title: 'One Song',
        state: _done,
      ),
    ]);
    await pump(tester);

    await openMenu(tester, CollectionKind.track, 't1');

    expect(find.text('Check for changes'), findsNothing);
  });

  testWidgets('a collection gone from the server says so and keeps its '
      'downloads', (tester) async {
    downloads.setEntries(const [
      DownloadCollectionEntry(
        kind: CollectionKind.playlist,
        refId: 'pl',
        title: 'Road Mix',
        state: CollectionDownloadState(
          status: DownloadCollectionStatus.ready,
          itemCount: 2,
          completedCount: 2,
          unavailableCount: 0,
          receivedBytes: 2000,
          totalBytes: 2000,
          sourceGone: true,
        ),
      ),
    ]);
    await pump(tester);

    expect(find.text('No longer on the server'), findsOneWidget);
    expect(find.text('Road Mix'), findsOneWidget);
  });
}
