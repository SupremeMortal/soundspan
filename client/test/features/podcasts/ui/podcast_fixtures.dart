// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/features/podcasts/podcasts.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../../helpers/fake_podcast_repository.dart';
import '../../../helpers/fake_reachability.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

/// Subscribed podcast [id].
Podcast fixturePodcast(String id, {String? author = 'A Host'}) => Podcast(
  id: id,
  title: 'Show $id',
  author: author,
  artworkRef: 'cover-$id',
  episodeCount: 3,
  feedUrl: 'https://example.com/$id.xml',
);

/// Top podcast [id] of the directory.
PodcastSummary fixtureTopPodcast(String id) => PodcastSummary(
  id: id,
  title: 'Top $id',
  author: 'Top Host',
  artworkRef: 'top-$id',
  feedUrl: 'https://example.com/top-$id.xml',
  itunesId: '9$id',
);

/// A description long enough to need more than three lines everywhere.
final String fixtureDescription = List.filled(
  12,
  'A weekly conversation about music, the people who make it and the '
  'places it comes from.',
).join(' ');

/// Episode [n] of `pc-1`: 42 minutes, published on 12 March 2026, with
/// [progress].
Episode fixtureEpisode(int n, {EpisodeProgress? progress}) => Episode(
  id: 'e$n',
  podcastId: 'pc-1',
  title: 'Episode $n',
  durationSec: 42 * 60,
  publishedAt: DateTime.utc(2026, 3, 12, 12),
  progress: progress,
);

/// The detail of `pc-1` with [episodes].
PodcastDetail fixtureDetail(
  List<Episode> episodes, {
  String? description,
  String? feedUrl = 'https://example.com/pc-1.xml',
}) => PodcastDetail(
  podcast: Podcast(
    id: 'pc-1',
    title: 'Show pc-1',
    author: 'A Host',
    description: description ?? fixtureDescription,
    artworkRef: 'cover-pc-1',
    episodeCount: episodes.length,
    feedUrl: feedUrl,
  ),
  episodes: episodes,
);

/// The three states of an episode: untouched, half played and finished.
List<Episode> fixtureEpisodes() => [
  fixtureEpisode(1),
  fixtureEpisode(
    2,
    progress: const EpisodeProgress(currentTimeSec: 24 * 60, isFinished: false),
  ),
  fixtureEpisode(
    3,
    progress: const EpisodeProgress(currentTimeSec: 42 * 60, isFinished: true),
  ),
];

/// Pumps [screen] at [initialLocation] of a router with `/podcasts` and
/// `/podcasts/:podcastId`: the route of [initialLocation] shows [screen]
/// and the other a stand-in text. Returns the router.
Future<GoRouter> pumpPodcasts(
  WidgetTester tester,
  Widget screen, {
  required String initialLocation,
  required FakePodcastRepository podcasts,
  FakeRepositories? repositories,
  Reachability reachability = Reachability.online,
  Size size = TestSizes.compact,
  ThemeMode theme = ThemeMode.dark,
  List<Override> overrides = const [],
}) async {
  Widget scoped(Widget child) => Builder(
    builder: (context) => WindowClassScope(
      windowClass: windowClassOf(MediaQuery.sizeOf(context)),
      child: child,
    ),
  );
  final detail = initialLocation != '/podcasts';
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/podcasts',
        builder: (_, _) =>
            detail ? const Text('podcasts root') : scoped(screen),
        routes: [
          GoRoute(
            path: ':podcastId',
            builder: (_, state) => detail
                ? scoped(screen)
                : Text('podcast page ${state.pathParameters['podcastId']}'),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpApp(
    Router.withConfig(config: router),
    size: size,
    theme: theme,
    overrides: [
      ...?repositories?.overrides,
      podcasts.providerOverride,
      reachabilityProvider.overrideWithValue(
        FakeReachability(initial: reachability),
      ),
      profilesProvider.overrideWith((ref) => Stream.value(const <Profile>[])),
      initialActiveProfileIdProvider.overrideWithValue(null),
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
  return router;
}
