// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Frame timings of the Library Songs screen over 10,000 tracks (doc 09,
// Performance Rules), run in profile mode by the perf-linux job of
// .github/workflows/client-device-tests.yml:
//
//   flutter drive --profile -d linux --driver=test_driver/perf_driver.dart \
//     --target=integration_test/perf_scroll_test.dart
//   dart run tool/perf/check_frame_timings.dart build/perf/scroll_songs.json
//
// The list is a fake paged source whose pages resolve after 50 ms, with the
// deterministic placeholder artwork. The summary is reported under
// `scroll_songs`; the budget is in tool/perf/budgets.json.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/features/library/ui/songs_tab.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

import '../test/features/library/library_harness.dart';
import '../test/helpers/fake_repositories.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('scrolling 10,000 songs stays within the frame budget', (
    tester,
  ) async {
    final library = FakeLibraryRepository()
      ..trackList = tracks(10000)
      ..pageDelay = const Duration(milliseconds: 50);
    await tester.pumpLibrary(tab: LibraryTab.songs, library: library);
    expect(find.byType(TrackRow), findsWidgets);

    final list = find
        .descendant(
          of: find.byType(SongsTab),
          matching: find.byType(Scrollable),
        )
        .first;
    await binding.watchPerformance(() async {
      for (var i = 0; i < 10; i++) {
        await tester.fling(list, const Offset(0, -600), 4000);
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < 5; i++) {
        await tester.fling(list, const Offset(0, 600), 4000);
        await tester.pumpAndSettle();
      }
      await tester.timedDrag(
        list,
        const Offset(0, -20000),
        const Duration(seconds: 5),
      );
      await tester.pumpAndSettle();
    }, reportKey: 'scroll_songs');

    expect(find.byType(TrackRow), findsWidgets);
  });
}
