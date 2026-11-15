// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The state behind the Home screen (doc 09, Home): one provider per shelf,
/// which shelves have scrolled into view, and the screen-wide outcomes.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/features/discover/discover.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/capability_refresh.dart';
import 'package:soundspan/shared/providers/repositories.dart';
import 'package:soundspan_api/soundspan_api.dart' show FeatureDisabled;

/// The shelves of Home, in screen order.
enum HomeShelf {
  /// Recently listened artists and podcasts.
  continueListening,

  /// Recently added artists.
  recentlyAdded,

  /// Liked Songs and the user's mixes.
  madeForYou,

  /// Artists similar to the ones the user plays most (`discovery`).
  recommendedForYou,

  /// Artists popular right now (`discovery`).
  popularArtists,

  /// The first page of the user's playlists.
  yourPlaylists,

  /// Popular podcasts.
  popularPodcasts,
}

/// Shelf providers report a failure once; the screen offers Retry.
Duration? _noRetry(int _, Object _) => null;

/// Continue Listening, from cache first.
final StreamProvider<List<RecentItem>?> homeRecentlyListenedProvider =
    StreamProvider.autoDispose<List<RecentItem>?>(
      (ref) => _values(ref, (repository) => repository.recentlyListened()),
      retry: _noRetry,
      dependencies: [homeRepositoryProvider],
    );

/// Recently added artists, from cache first.
final StreamProvider<List<Artist>?> homeRecentlyAddedProvider =
    StreamProvider.autoDispose<List<Artist>?>(
      (ref) => _values(ref, (repository) => repository.recentlyAdded()),
      retry: _noRetry,
      dependencies: [homeRepositoryProvider],
    );

/// The mixes of Made For You, from cache first; null while the server has
/// `autoPlaylists` off (nothing is requested) or answers `FeatureDisabled`
/// (a capability refresh is requested).
final StreamProvider<List<MixSummary>?> homeMixesProvider =
    StreamProvider.autoDispose<List<MixSummary>?>(
      (ref) async* {
        final enabled = ref.watch(
          serverCapabilitiesProvider.select((value) => value.autoPlaylists),
        );
        if (!enabled) {
          yield null;
          return;
        }
        final repository = await ref.watch(homeRepositoryProvider.future);
        try {
          await for (final cached in repository.mixes()) {
            if (cached.refreshError is FeatureDisabled) {
              ref.read(capabilityRefreshProvider)();
              yield null;
              return;
            }
            yield cached.value;
          }
        } on FeatureDisabled {
          ref.read(capabilityRefreshProvider)();
          yield null;
        }
      },
      retry: _noRetry,
      dependencies: [
        serverCapabilitiesProvider,
        homeRepositoryProvider,
        capabilityRefreshProvider,
      ],
    );

/// Popular podcasts, from cache first.
final StreamProvider<List<PodcastSummary>?> homeTopPodcastsProvider =
    StreamProvider.autoDispose<List<PodcastSummary>?>(
      (ref) => _values(ref, (repository) => repository.topPodcasts()),
      retry: _noRetry,
      dependencies: [homeRepositoryProvider],
    );

/// The paged source behind Your Playlists; only its first page is loaded.
final FutureProvider<PagedSource<PlaylistSummary>> homePlaylistSourceProvider =
    FutureProvider.autoDispose<PagedSource<PlaylistSummary>>(
      (ref) async {
        final repository = await ref.watch(playlistRepositoryProvider.future);
        final source = repository.playlists();
        ref.onDispose(source.dispose);
        source.ensureVisible(0, 0);
        return source;
      },
      retry: _noRetry,
      dependencies: [playlistRepositoryProvider],
    );

/// The loaded part of the first page of the user's playlists.
///
/// It errors with the page's error when that page failed and nothing is
/// loaded, and waits while the first page is in flight.
final StreamProvider<List<PlaylistSummary>?> homePlaylistsProvider =
    StreamProvider.autoDispose<List<PlaylistSummary>?>(
      (ref) =>
          Stream.fromFuture(ref.watch(homePlaylistSourceProvider.future))
              .asyncExpand(_firstPage),
      retry: _noRetry,
      dependencies: [homePlaylistSourceProvider],
    );

Stream<List<PlaylistSummary>?> _firstPage(
  PagedSource<PlaylistSummary> source,
) => source.watch().transform(
  StreamTransformer.fromHandlers(
    handleData: (snapshot, sink) {
      final total = snapshot.total;
      if (snapshot.loadedCount > 0) {
        final end = total == null || total > source.pageSize
            ? source.pageSize
            : total;
        sink.add([
          for (var index = 0; index < end; index++) ?snapshot.itemAt(index),
        ]);
      } else if (snapshot.refreshError case final error?) {
        sink.addError(error);
      } else if (!snapshot.refreshing && total == 0) {
        sink.add(const []);
      }
    },
  ),
);

Stream<List<T>?> _values<T>(
  Ref ref,
  Stream<Cached<List<T>>> Function(HomeRepository repository) read,
) async* {
  final repository = await ref.watch(homeRepositoryProvider.future);
  yield* read(repository).map((cached) => cached.value);
}

/// The data provider behind each shelf. Made For You is only its mixes:
/// Liked Songs is always there and is not data.
ProviderListenable<AsyncValue<List<Object>?>> homeShelfSource(
  HomeShelf shelf,
) => switch (shelf) {
  HomeShelf.continueListening => homeRecentlyListenedProvider,
  HomeShelf.recentlyAdded => homeRecentlyAddedProvider,
  HomeShelf.madeForYou => homeMixesProvider,
  HomeShelf.recommendedForYou => recommendedForYouProvider,
  HomeShelf.popularArtists => popularArtistsProvider,
  HomeShelf.yourPlaylists => homePlaylistsProvider,
  HomeShelf.popularPodcasts => homeTopPodcastsProvider,
};

/// The shelves that have been built at least once, that is, scrolled into
/// view. The screen-wide outcomes only count these, so a shelf below the
/// fold is not requested to decide them.
class HomeShelfActivation extends Notifier<Set<HomeShelf>> {
  @override
  Set<HomeShelf> build() => const {};

  /// Records that [shelf] has been built.
  void activate(HomeShelf shelf) {
    if (state.contains(shelf)) return;
    state = {...state, shelf};
  }
}

/// The [HomeShelfActivation] of the Home screen on display.
final NotifierProvider<HomeShelfActivation, Set<HomeShelf>>
homeShelfActivationProvider =
    NotifierProvider.autoDispose<HomeShelfActivation, Set<HomeShelf>>(
      HomeShelfActivation.new,
    );

/// What Home shows in place of its shelves.
sealed class HomeOutcome {
  const new();
}

/// The shelves, each loading, showing or hidden on its own.
final class HomeShelves extends HomeOutcome {
  /// The outcome.
  const new();
}

/// Every requested shelf failed with nothing cached.
final class HomeAllFailed extends HomeOutcome {
  /// The outcome with the first shelf's [error].
  const new(this.error);

  /// What the first failed shelf failed with.
  final Object error;
}

/// Every requested shelf loaded and is empty: a new library.
final class HomeAllEmpty extends HomeOutcome {
  /// The outcome.
  const new();
}

/// Decides what Home shows from the states of the shelves in [sources]
/// (by shelf; a missing one has not been built yet).
///
/// A shelf whose source is null (not requested, or disabled by the server)
/// takes no part. Until every shelf has been built, the shelves show.
HomeOutcome homeOutcome(Map<HomeShelf, AsyncValue<List<Object>?>> sources) {
  if (sources.length < HomeShelf.values.length) return const HomeShelves();
  final taking = [
    for (final shelf in HomeShelf.values)
      if (sources[shelf]! case final value
          when !(value.hasValue && value.value == null))
        value,
  ];
  if (taking.isEmpty) return const HomeShelves();
  if (taking.every((value) => value.hasError && !value.hasValue)) {
    return HomeAllFailed(taking.first.error!);
  }
  if (taking.every(
    (value) => !value.hasError && (value.value?.isEmpty ?? false),
  )) {
    return const HomeAllEmpty();
  }
  return const HomeShelves();
}

/// Fetches every shelf that has been built again: a shelf that failed with
/// nothing cached is requested anew; the others are refreshed whatever
/// their age. A shelf not built yet is left alone; it is read when it
/// scrolls into view. Errors of a refresh are dropped, because each shelf
/// keeps showing what it has.
Future<void> refreshHome(WidgetRef ref) async {
  final refreshes = <Future<void>>[];
  Future<void> quietly(Future<void> Function() refresh) async {
    try {
      await refresh();
    } on Object {
      // The shelf keeps its cached value; its stream reports the failure.
    }
  }

  void each(
    StreamProvider<Object?> provider,
    Future<void> Function(HomeRepository repository) refresh,
  ) {
    if (!ref.read(provider.exists)) return;
    final state = ref.read(provider);
    if (state.hasError && !state.hasValue) {
      ref.invalidate(provider);
      return;
    }
    final repository = ref.read(homeRepositoryProvider).value;
    if (repository != null) refreshes.add(quietly(() => refresh(repository)));
  }

  each(
    homeRecentlyListenedProvider,
    (repository) => repository.refreshRecentlyListened(),
  );
  each(
    homeRecentlyAddedProvider,
    (repository) => repository.refreshRecentlyAdded(),
  );
  if (ref.read(serverCapabilitiesProvider).autoPlaylists) {
    each(homeMixesProvider, (repository) => repository.refreshMixes());
  }
  each(
    homeTopPodcastsProvider,
    (repository) => repository.refreshTopPodcasts(),
  );
  refreshes.add(refreshDiscovery(ref));

  if (ref.read(homePlaylistsProvider.exists)) {
    final playlists = ref.read(homePlaylistsProvider);
    if (playlists.hasError && !playlists.hasValue) {
      ref.invalidate(homePlaylistSourceProvider);
    } else if (ref.read(homePlaylistSourceProvider.exists)) {
      final source = ref.read(homePlaylistSourceProvider).value;
      if (source != null) refreshes.add(quietly(source.refresh));
    }
  }
  await Future.wait(refreshes);
}

/// Requests every shelf anew, after they all failed.
void retryHome(WidgetRef ref) {
  ref
    ..invalidate(homeRecentlyListenedProvider)
    ..invalidate(homeRecentlyAddedProvider)
    ..invalidate(homeMixesProvider)
    ..invalidate(homeTopPodcastsProvider)
    ..invalidate(homePlaylistSourceProvider);
  retryDiscovery(ref);
}
