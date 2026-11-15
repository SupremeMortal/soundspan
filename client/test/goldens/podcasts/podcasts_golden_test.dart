// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/features/podcasts/podcasts.dart';
import 'package:soundspan/features/podcasts/ui/episode_row.dart';
import 'package:soundspan/shared/providers/tint.dart';

import '../../features/podcasts/ui/podcast_fixtures.dart';
import '../../helpers/fake_podcast_repository.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/fake_tint_extractor.dart';
import '../../helpers/golden.dart';

List<Override> _overrides() {
  final podcasts = FakePodcastRepository()
    ..subscribedList = [for (var n = 1; n <= 7; n++) fixturePodcast('pc-$n')];
  podcasts.details['pc-1'] = fixtureDetail(fixtureEpisodes());
  final repositories = FakeRepositories();
  repositories.home.podcasts = [
    for (var n = 1; n <= 6; n++) fixtureTopPodcast('t$n'),
  ];
  return [
    ...repositories.overrides,
    podcasts.providerOverride,
    profilesProvider.overrideWith((ref) => Stream.value(const <Profile>[])),
    initialActiveProfileIdProvider.overrideWithValue(null),
    tintExtractorProvider.overrideWithValue(
      AsyncData(FakeTintExtractor({'cover-pc-1': const Color(0xFF0E7490)})),
    ),
  ];
}

Widget _scoped(BuildContext context, Widget child) => WindowClassScope(
  windowClass: windowClassOf(MediaQuery.sizeOf(context)),
  child: child,
);

void main() {
  goldenMatrix(
    'podcasts',
    builder: (context) => _scoped(context, const PodcastsScreen()),
    overrides: _overrides(),
  );

  goldenMatrix(
    'podcast_detail',
    builder: (context) =>
        _scoped(context, const PodcastDetailScreen(podcastId: 'pc-1')),
    overrides: _overrides(),
  );

  goldenMatrix(
    'episode_row',
    sizes: const [Size(390, 360)],
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EpisodeRow(
            title: 'An episode nobody has started yet',
            publishedAt: DateTime.utc(2026, 3, 12, 12),
            duration: const Duration(minutes: 42),
          ),
          EpisodeRow(
            title:
                'A started episode whose title is long enough to need a '
                'second line on a phone',
            publishedAt: DateTime.utc(2026, 3, 5, 12),
            duration: const Duration(hours: 1, minutes: 4),
            position: const Duration(minutes: 24),
          ),
          EpisodeRow(
            title: 'A finished episode',
            publishedAt: DateTime.utc(2026, 2, 26, 12),
            duration: const Duration(minutes: 38),
            position: const Duration(minutes: 38),
            isFinished: true,
          ),
        ],
      ),
    ),
  );
}
