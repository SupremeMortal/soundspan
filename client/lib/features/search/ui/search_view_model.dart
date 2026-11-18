// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The state behind the Search screen (doc 09, Search): the recent
/// searches, one provider per page of a query and filter, the results from
/// this device, and what the screen shows.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, StreamProviderFamily;
import 'package:soundspan/core/downloads/downloaded_library.dart';
import 'package:soundspan/features/downloads/downloads.dart';
import 'package:soundspan/features/search/domain/search_ranking.dart';
import 'package:soundspan/features/search/search_providers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/cache.dart';
import 'package:soundspan/shared/providers/repositories.dart';

/// Search providers report a failure once; the screen offers Retry.
Duration? _noRetry(int _, Object _) => null;

/// The recent searches of the profile, newest first.
final StreamProvider<List<String>> searchRecentProvider =
    StreamProvider.autoDispose<List<String>>(
      (ref) => ref.watch(searchHistoryStoreProvider).watchRecent(),
      retry: _noRetry,
      dependencies: [searchHistoryStoreProvider],
    );

/// Records [query] as a recent search.
Future<void> recordSearch(WidgetRef ref, String query) =>
    ref.read(searchHistoryStoreProvider).record(query);

/// Forgets the recent search [query].
Future<void> removeRecentSearch(WidgetRef ref, String query) =>
    ref.read(searchHistoryStoreProvider).remove(query);

/// Forgets every recent search.
Future<void> clearRecentSearches(WidgetRef ref) =>
    ref.read(searchHistoryStoreProvider).clear();

/// One request of the screen: the page of `query` under `filter` that
/// starts at `offset`.
typedef SearchRequest = ({String query, SearchFilter filter, int offset});

/// The requests for the first [pageCount] pages of [query] under [filter];
/// [SearchFilter.all] has one page only.
List<SearchRequest> searchRequests(
  String query,
  SearchFilter filter,
  int pageCount,
) => [
  for (
    var page = 0;
    page < (filter == SearchFilter.all ? 1 : pageCount);
    page++
  )
    (query: query, filter: filter, offset: page * searchPageSize),
];

/// The page of one [SearchRequest], from cache first.
final StreamProviderFamily<SearchPage, SearchRequest> searchPageProvider =
    StreamProvider.autoDispose.family<SearchPage, SearchRequest>(
      (ref, request) async* {
        final repository = await ref.watch(searchRepositoryProvider.future);
        await for (final cached in repository.search(
          request.query,
          request.filter,
          offset: request.offset,
        )) {
          yield cached.value;
        }
      },
      retry: _noRetry,
      dependencies: [searchRepositoryProvider],
    );

/// The results of a query from this device only, without the server: the
/// cache's tracks, albums, artists and playlists whose title or name
/// contains it, and the downloaded tracks whose title, artist or album
/// does, ranked by [rankSearchHits]. Downloads come before cached tracks of
/// the same score; a track is listed once by its playback id. Where the
/// platform does not download, only the cache is searched.
final FutureProviderFamily<List<SearchResult>, String> localSearchProvider =
    FutureProvider.autoDispose.family<List<SearchResult>, String>(
      (ref, query) async {
        final cache = await ref.watch(cacheStoreProvider.future);
        final matches = await cache.searchLocal(query);
        final downloaded = ref.watch(downloadsAvailableProvider)
            ? await ref.watch(downloadedLibraryProvider).tracks()
            : const <Track>[];
        final needle = query.toLowerCase();
        bool matchesText(Track track) => [
          track.meta.title,
          track.meta.artist,
          track.meta.album,
        ].any((text) => text.toLowerCase().contains(needle));
        final seen = <PlaybackId>{};
        final tracks = <Track>[];
        for (final track in [
          ...downloaded.where(matchesText),
          ...matches.tracks,
        ]) {
          final id = track.playbackId;
          if (id != null && !seen.add(id)) continue;
          tracks.add(track);
        }
        return rankSearchHits(query, [
          for (final track in tracks) SearchHit.track(track: track),
          for (final artist in matches.artists)
            SearchHit.artist(artist: artist),
          for (final album in matches.albums) SearchHit.album(album: album),
          for (final playlist in matches.playlists)
            SearchHit.playlist(playlist: playlist),
        ]);
      },
      retry: _noRetry,
      dependencies: [cacheStoreProvider, downloadedLibraryProvider],
    );

/// What the Search screen shows for a query.
sealed class SearchOutcome {
  const new();
}

/// The first page has not answered yet: row skeletons.
final class SearchLoading extends SearchOutcome {
  /// The outcome.
  const new();
}

/// What was found, best match first.
final class SearchFound extends SearchOutcome {
  /// The outcome showing [results].
  const new(
    this.results, {
    this.hasMore = false,
    this.loadingMore = false,
    this.moreError,
  });

  /// The results of every page that answered, in order.
  final List<SearchResult> results;

  /// Whether the server holds more results than the pages requested.
  final bool hasMore;

  /// Whether a later page is in flight.
  final bool loadingMore;

  /// What the first later page that failed failed with, if any; the
  /// results before it still show.
  final Object? moreError;
}

/// The first page answered and nothing was found.
final class SearchNothingFound extends SearchOutcome {
  /// The outcome.
  const new();
}

/// The first page failed with nothing cached.
final class SearchFailed extends SearchOutcome {
  /// The outcome with the page's [error].
  const new(this.error);

  /// What the first page failed with.
  final Object error;
}

/// Decides what the screen shows from the states of the requested [pages],
/// in page order. The results are those of the pages that answered before
/// the first one that has not; a later page in flight or failed leaves the
/// earlier results in place.
SearchOutcome searchOutcome(List<AsyncValue<SearchPage>> pages) {
  if (pages.isEmpty) return const SearchLoading();
  final first = pages.first;
  if (!first.hasValue) {
    if (first.error case final error?) return SearchFailed(error);
    return const SearchLoading();
  }
  final results = <SearchResult>[];
  var hasMore = false;
  for (final page in pages) {
    final value = page.value;
    if (value == null) {
      return SearchFound(
        results,
        hasMore: true,
        loadingMore: !page.hasError,
        moreError: page.error,
      );
    }
    results.addAll(value.items);
    hasMore = value.hasMore;
  }
  if (results.isEmpty && !hasMore) return const SearchNothingFound();
  return SearchFound(results, hasMore: hasMore);
}

/// Requests the pages of [requests] that failed anew.
void retrySearch(WidgetRef ref, List<SearchRequest> requests) {
  for (final request in requests) {
    if (ref.read(searchPageProvider(request)).hasError) {
      ref.invalidate(searchPageProvider(request));
    }
  }
}
