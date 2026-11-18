// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/features/downloads/downloads.dart';

import '../../../helpers/fakes/fake_download_controller.dart';
import '../../library/library_harness.dart';

void main() {
  late FakeDownloadController downloads;

  setUp(() => downloads = FakeDownloadController());

  List<String?> labels(WidgetTester tester) => [
    for (final tab in tester.widgetList<Tab>(find.byType(Tab))) tab.text,
  ];

  testWidgets('Downloads is the fifth Library tab and shows the Downloads '
      'tab at /library/downloads', (tester) async {
    await tester.pumpLibrary(
      tab: LibraryTab.downloads,
      overrides: downloads.overrides(),
    );

    expect(labels(tester), [
      'Playlists',
      'Artists',
      'Albums',
      'Songs',
      'Downloads',
    ]);
    expect(find.byType(DownloadsTab), findsOneWidget);
  });

  testWidgets('the tab is absent where the platform does not download', (
    tester,
  ) async {
    await tester.pumpLibrary(
      tab: LibraryTab.downloads,
      overrides: downloads.overrides(canDownload: false),
    );

    expect(labels(tester), ['Playlists', 'Artists', 'Albums', 'Songs']);
    expect(find.byType(DownloadsTab), findsNothing);
  });
}
