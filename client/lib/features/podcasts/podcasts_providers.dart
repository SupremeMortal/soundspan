// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The profile-scoped [PodcastRepository], provided outside `data/` because
/// `ui/` may not import it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/features/podcasts/data/cached_podcast_repository.dart';
import 'package:soundspan/features/podcasts/domain/podcast_repository.dart';
import 'package:soundspan/shared/providers/cache.dart';
import 'package:soundspan/shared/providers/repositories.dart';

/// The profile's [PodcastRepository], over the generated `PodcastsClient`.
final FutureProvider<PodcastRepository> podcastRepositoryProvider =
    FutureProvider<PodcastRepository>(
      (ref) async => CachedPodcastRepository(
        ref.watch(soundspanApiProvider).rest.podcasts,
        await ref.watch(cacheStoreProvider.future),
        ref.watch(swrProvider),
        pending: ref.watch(pendingOpsProvider),
      ),
      dependencies: [
        soundspanApiProvider,
        cacheStoreProvider,
        swrProvider,
        pendingOpsProvider,
      ],
    );
