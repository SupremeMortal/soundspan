// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/features/downloads/downloads.dart';

import '../../../helpers/fakes/fake_download_controller.dart';
import '../../../helpers/pump_app.dart';

const _entry = DownloadCollectionEntry(
  kind: CollectionKind.episode,
  refId: 'pc-1:e1',
  title: 'Episode One',
  subtitle: 'Night Shift',
  state: CollectionDownloadState(
    status: DownloadCollectionStatus.ready,
    itemCount: 1,
    completedCount: 1,
    unavailableCount: 0,
    receivedBytes: 1000,
    totalBytes: 1000,
  ),
);

void main() {
  late FakeDownloadController downloads;

  setUp(() => downloads = FakeDownloadController()..setEntries([_entry]));

  Future<GoRouter> pump(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/downloads',
      routes: [
        GoRoute(
          path: '/downloads',
          builder: (_, _) => const Scaffold(body: DownloadsTab()),
        ),
        GoRoute(
          path: '/podcasts/:podcastId',
          builder: (_, state) =>
              Text('podcast page ${state.pathParameters['podcastId']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpApp(
      Router.withConfig(config: router),
      overrides: downloads.overrides(),
    );
    await tester.pump();
    return router;
  }

  testWidgets('an episode row reads as its podcast and opens the podcast '
      'page', (tester) async {
    await pump(tester);

    expect(find.text('Episode One'), findsOneWidget);
    expect(find.text('Episode · Night Shift'), findsOneWidget);

    await tester.tap(find.text('Episode One'));
    await tester.pumpAndSettle();

    expect(find.text('podcast page pc-1'), findsOneWidget);
  });

  testWidgets('an episode row has no Check for changes', (tester) async {
    await pump(tester);

    await tester.tap(
      find.byKey(DownloadsTab.menuKey(CollectionKind.episode, 'pc-1:e1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Remove download'), findsOneWidget);
    expect(find.text('Check for changes'), findsNothing);
  });
}
