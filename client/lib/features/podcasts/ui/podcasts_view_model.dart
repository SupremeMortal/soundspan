// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamNotifierProviderFamily;
import 'package:soundspan/features/podcasts/domain/podcast_detail.dart';
import 'package:soundspan/features/podcasts/domain/podcast_ref.dart';
import 'package:soundspan/features/podcasts/podcasts_providers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/repositories.dart';

/// The podcasts the user is subscribed to, from
/// `PodcastRepository.subscribed`, with the writes of the Podcasts screen.
class SubscribedPodcastsController
    extends StreamNotifier<Cached<List<Podcast>>> {
  @override
  Stream<Cached<List<Podcast>>> build() async* {
    final repository = await ref.watch(podcastRepositoryProvider.future);
    yield* repository.subscribed();
  }

  /// Fetches the subscribed podcasts again.
  Future<void> refresh() async {
    final repository = await ref.read(podcastRepositoryProvider.future);
    await repository.refreshSubscribed();
  }

  /// Subscribes to the podcast [podcast] names and returns its server id.
  Future<String> subscribe(PodcastRef podcast) async {
    final repository = await ref.read(podcastRepositoryProvider.future);
    return await repository.subscribe(podcast);
  }
}

/// The [SubscribedPodcastsController] of the profile.
final StreamNotifierProvider<
  SubscribedPodcastsController,
  Cached<List<Podcast>>
>
subscribedPodcastsProvider = StreamNotifierProvider.autoDispose(
  SubscribedPodcastsController.new,
  retry: _noRetry,
  dependencies: [podcastRepositoryProvider],
);

/// The Top Podcasts shelf, from [HomeRepository.topPodcasts].
final StreamProvider<List<PodcastSummary>> topPodcastsProvider =
    StreamProvider.autoDispose<List<PodcastSummary>>(
      (ref) async* {
        final repository = await ref.watch(homeRepositoryProvider.future);
        yield* repository.topPodcasts().map((cached) => cached.value);
      },
      retry: _noRetry,
      dependencies: [homeRepositoryProvider],
    );

/// The podcast [podcastId] with its episodes, from
/// `PodcastRepository.detail`, with the writes of the podcast page.
class PodcastDetailController extends StreamNotifier<Cached<PodcastDetail>> {
  /// Creates the controller of podcast [podcastId].
  new(this.podcastId);

  /// The server's podcast id.
  final String podcastId;

  @override
  Stream<Cached<PodcastDetail>> build() async* {
    final repository = await ref.watch(podcastRepositoryProvider.future);
    yield* repository.detail(podcastId);
  }

  /// Fetches the podcast again.
  Future<void> refresh() async {
    final repository = await ref.read(podcastRepositoryProvider.future);
    await repository.refreshDetail(podcastId);
  }

  /// Subscribes to the podcast again by its feed URL [feedUrl].
  Future<void> subscribe(String feedUrl) async {
    final repository = await ref.read(podcastRepositoryProvider.future);
    await repository.subscribe(PodcastRef.feed(feedUrl));
  }

  /// Unsubscribes from the podcast.
  Future<void> unsubscribe() async {
    final repository = await ref.read(podcastRepositoryProvider.future);
    await repository.unsubscribe(podcastId);
  }
}

/// The [PodcastDetailController] of the podcast named by the argument.
final StreamNotifierProviderFamily<
  PodcastDetailController,
  Cached<PodcastDetail>,
  String
>
podcastDetailProvider = StreamNotifierProvider.autoDispose.family(
  PodcastDetailController.new,
  retry: _noRetry,
  dependencies: [podcastRepositoryProvider],
);

/// Fetches the subscribed podcasts and the Top Podcasts shelf again. A
/// failure leaves what is on screen: the cached content stays, and a
/// failed shelf is hidden.
Future<void> refreshPodcasts(WidgetRef ref) async {
  Future<void> quietly(Future<void> Function() refresh) async {
    try {
      await refresh();
    } on Exception {
      // The cached content stays on screen (doc 09, Podcasts).
    }
  }

  final subscribed = ref.read(subscribedPodcastsProvider.notifier);
  final home = ref.read(homeRepositoryProvider.future);
  await Future.wait([
    quietly(subscribed.refresh),
    quietly(() async => await (await home).refreshTopPodcasts()),
  ]);
}

/// Reads are not retried: the repository already falls back to the cache,
/// and the error view offers Retry.
Duration? _noRetry(int retryCount, Object error) => null;
