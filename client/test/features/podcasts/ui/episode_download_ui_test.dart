// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/episode_download_meta.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/features/podcasts/podcasts.dart';
import 'package:soundspan/features/podcasts/ui/episode_row.dart';
import 'package:soundspan/shared/widgets/download_glyph.dart';
import 'package:soundspan_api/soundspan_api.dart' show Offline;

import '../../../helpers/fake_podcast_repository.dart';
import '../../../helpers/fakes/fake_download_controller.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import 'podcast_fixtures.dart';

const _detail = PodcastDetailScreen(podcastId: 'pc-1');

EpisodeItemKey _key(int n) =>
    EpisodeItemKey(podcastId: 'pc-1', episodeId: 'e$n');

FakePodcastRepository _repository() {
  final repository = FakePodcastRepository()
    ..subscribedList = [fixturePodcast('pc-1')];
  repository.details['pc-1'] = fixtureDetail([
    fixtureEpisode(1),
    fixtureEpisode(2),
    fixtureEpisode(3),
  ]);
  return repository;
}

EpisodeDownloadMeta _meta(int n, {double? positionSec}) => EpisodeDownloadMeta(
  episodeId: 'e$n',
  podcastId: 'pc-1',
  title: 'Episode $n',
  podcastTitle: 'Show pc-1',
  durationSec: 42 * 60,
  publishedAt: DateTime.utc(2026, 3, 10 + n),
  positionSec: positionSec,
);

Future<void> _pump(
  WidgetTester tester,
  FakeDownloadController downloads, {
  FakePodcastRepository? podcasts,
  Widget screen = _detail,
  String location = '/podcasts/pc-1',
  Reachability reachability = Reachability.online,
  bool canDownload = true,
}) => pumpPodcasts(
  tester,
  screen,
  initialLocation: location,
  podcasts: podcasts ?? _repository(),
  reachability: reachability,
  size: TestSizes.expanded,
  overrides: downloads.overrides(canDownload: canDownload),
);

Finder _row(int n) => find.ancestor(
  of: find.text('Episode $n'),
  matching: find.byType(EpisodeRow),
);

EpisodeRow _rowWidget(WidgetTester tester, int n) =>
    tester.widget<EpisodeRow>(_row(n));

Future<List<String>> _menuOf(WidgetTester tester, int n) async {
  await tester.tap(
    find.descendant(of: _row(n), matching: find.byKey(EpisodeRow.menuKey)),
  );
  await tester.pumpAndSettle();
  final labels = [
    for (final label in ['Download', 'Remove download', 'Retry download'])
      if (find.text(label).evaluate().isNotEmpty) label,
  ];
  await tester.tapAt(Offset.zero);
  await tester.pumpAndSettle();
  return labels;
}

void main() {
  testWidgets('each row shows the glyph of its download', (tester) async {
    final downloads = FakeDownloadController()
      ..setItem(_key(2), itemState(DownloadStatus.running, received: 500))
      ..setItem(_key(3), itemState(DownloadStatus.completed, size: 1000));
    await _pump(tester, downloads);

    expect(
      find.descendant(
        of: _row(1),
        matching: find.byKey(EpisodeRow.downloadGlyphKey),
      ),
      findsNothing,
    );
    expect(_rowWidget(tester, 1).download, DownloadGlyphState.none);
    expect(
      _rowWidget(tester, 2).download,
      const DownloadGlyphState.running(0.5),
    );
    expect(_rowWidget(tester, 3).download, DownloadGlyphState.completed);
    expect(
      find.descendant(
        of: _row(3),
        matching: find.byKey(EpisodeRow.downloadGlyphKey),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the menu offers Download, or Remove download once '
      'downloaded, and Retry when failed', (tester) async {
    final downloads = FakeDownloadController()
      ..setItem(_key(2), itemState(DownloadStatus.completed, size: 1000))
      ..setItem(_key(3), itemState(DownloadStatus.failedPermanent));
    await _pump(tester, downloads);

    expect(await _menuOf(tester, 1), ['Download']);
    expect(await _menuOf(tester, 2), ['Remove download']);
    expect(await _menuOf(tester, 3), ['Remove download', 'Retry download']);
  });

  testWidgets('Download pins the episode', (tester) async {
    final downloads = FakeDownloadController();
    await _pump(tester, downloads);

    await tester.tap(
      find.descendant(of: _row(1), matching: find.byKey(EpisodeRow.menuKey)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    expect(downloads.calls, ['pinEpisode pc-1 e1']);
  });

  testWidgets('glyph and menu are hidden where the platform does not '
      'download', (tester) async {
    final downloads = FakeDownloadController()
      ..setItem(_key(1), itemState(DownloadStatus.completed, size: 1000));
    await _pump(tester, downloads, canDownload: false);

    expect(find.byKey(EpisodeRow.downloadGlyphKey), findsNothing);
    expect(find.byKey(EpisodeRow.menuKey), findsNothing);
  });

  testWidgets('offline, episodes without a file are disabled', (tester) async {
    final downloads = FakeDownloadController()
      ..setItem(_key(2), itemState(DownloadStatus.completed, size: 1000));
    await _pump(tester, downloads, reachability: Reachability.forcedOffline);

    expect(_rowWidget(tester, 1).disabledReason, 'Not available offline');
    expect(_rowWidget(tester, 2).disabledReason, isNull);
    expect(_rowWidget(tester, 3).disabledReason, 'Not available offline');
    final handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp(r'^Episode 1, .*, Not available offline$')),
      findsOneWidget,
    );
    handle.dispose();

    await expectMeetsGuidelines(tester);
  });

  testWidgets('offline with nothing cached, the page lists the downloaded '
      'episodes and resumes from their stored position', (tester) async {
    final podcasts = FakePodcastRepository()
      ..errors['detail'] = const Offline();
    final downloads = FakeDownloadController()
      ..setDownloadedEpisodes([_meta(1), _meta(2, positionSec: 21 * 60)])
      ..setItem(_key(1), itemState(DownloadStatus.completed, size: 1000))
      ..setItem(_key(2), itemState(DownloadStatus.completed, size: 1000));
    await _pump(
      tester,
      downloads,
      podcasts: podcasts,
      reachability: Reachability.forcedOffline,
    );

    expect(find.text('Show pc-1'), findsOneWidget);
    expect(
      tester
          .widgetList<EpisodeRow>(find.byType(EpisodeRow))
          .map((row) => row.title),
      ['Episode 2', 'Episode 1'],
    );
    expect(_rowWidget(tester, 2).position, const Duration(minutes: 21));
  });

  testWidgets('offline with no cached list, the Podcasts screen shows the '
      'podcasts of downloaded episodes', (tester) async {
    final podcasts = FakePodcastRepository()
      ..errors['subscribed'] = const Offline();
    final downloads = FakeDownloadController()
      ..setDownloadedEpisodes([_meta(1), _meta(2)]);
    await _pump(
      tester,
      downloads,
      podcasts: podcasts,
      screen: const PodcastsScreen(),
      location: '/podcasts',
      reachability: Reachability.forcedOffline,
    );

    expect(find.byKey(PodcastsScreen.cardKey('pc-1')), findsOneWidget);
    expect(find.text('Show pc-1'), findsOneWidget);
  });
}
