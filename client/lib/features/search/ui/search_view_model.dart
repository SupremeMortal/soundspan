// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The state behind the Search screen (doc 09, Search): the recent
/// searches, one provider per endpoint and query, the user's playlists, and
/// what the screen shows.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:soundspan/features/search/domain/search_sections.dart';
import 'package:soundspan/features/search/search_providers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/repositories.dart';
import 'package:soundspan_api/soundspan_api.dart'
    show FeatureDisabled, Upstream;

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

/// One request of the screen: a query over the scope of one endpoint
/// ([SearchScope.library], [SearchScope.discover] or
/// [SearchScope.podcasts]).
typedef SearchRequest = ({String query, SearchScope scope});

/// The results of one [SearchRequest], from cache first.
///
/// `FeatureDisabled` or `Upstream` from the catalogue search mean "no
/// catalogue results", not a failure.
final StreamProviderFamily<SearchResults, SearchRequest> searchPartProvider =
    StreamProvider.autoDispose.family<SearchResults, SearchRequest>(
      (ref, request) async* {
        final repository = await ref.watch(searchRepositoryProvider.future);
        try {
          await for (final cached in repository.search(
            request.query,
            request.scope,
          )) {
            yield cached.value;
          }
        } on Object catch (error) {
          if (request.scope == SearchScope.discover &&
              (error is FeatureDisabled || error is Upstream)) {
            yield const SearchResults(discover: DiscoverResults());
            return;
          }
          rethrow;
        }
      },
      retry: _noRetry,
      dependencies: [searchRepositoryProvider],
    );

/// The endpoint requests [scope] makes for [query].
List<SearchRequest> searchRequests(String query, SearchScope scope) =>
    switch (scope) {
      SearchScope.all => [
        (query: query, scope: SearchScope.library),
        (query: query, scope: SearchScope.discover),
      ],
      SearchScope.library => [(query: query, scope: SearchScope.library)],
      SearchScope.discover => [(query: query, scope: SearchScope.discover)],
      SearchScope.podcasts => [(query: query, scope: SearchScope.podcasts)],
    };

/// The loaded first page of the user's playlists; empty while it loads or
/// when it failed, because the playlists only add to the results.
final StreamProvider<List<PlaylistSummary>> searchPlaylistsProvider =
    StreamProvider.autoDispose<List<PlaylistSummary>>(
      (ref) async* {
        final repository = await ref.watch(playlistRepositoryProvider.future);
        final source = repository.playlists();
        ref.onDispose(source.dispose);
        source.ensureVisible(0, 0);
        yield const [];
        yield* source.watch().map(
          (snapshot) => [
            for (var index = 0; index < snapshot.loadedCount; index++)
              ?snapshot.itemAt(index),
          ],
        );
      },
      retry: _noRetry,
      dependencies: [playlistRepositoryProvider],
    );

/// What the Search screen shows for a query.
sealed class SearchOutcome {
  const new();
}

/// No request has answered yet: section skeletons.
final class SearchLoading extends SearchOutcome {
  /// The outcome.
  const new();
}

/// The sections of what was found.
final class SearchFound extends SearchOutcome {
  /// The outcome showing [sections].
  const new(this.sections);

  /// What was found.
  final SearchSections sections;
}

/// Every request answered and nothing was found.
final class SearchNothingFound extends SearchOutcome {
  /// The outcome.
  const new();
}

/// Every request failed with nothing cached.
final class SearchFailed extends SearchOutcome {
  /// The outcome with the first request's [error].
  const new(this.error);

  /// What the first request failed with.
  final Object error;
}

/// Decides what the screen shows for [query] over [scope] from the states
/// of its requests in [parts] (by request) and [playlists].
///
/// The library results come from the library or podcasts request and the
/// catalogue results from the catalogue request. A request that failed
/// while another answered is left out; while one is still in flight and
/// nothing was found yet, skeletons show.
SearchOutcome searchOutcome({
  required String query,
  required SearchScope scope,
  required Map<SearchRequest, AsyncValue<SearchResults>> parts,
  required List<PlaylistSummary> playlists,
}) {
  final states = parts.values.toList();
  if (!states.any((part) => part.hasValue)) {
    if (states.isNotEmpty && states.every((part) => part.hasError)) {
      return SearchFailed(states.first.error!);
    }
    return const SearchLoading();
  }
  LibrarySearchResults? library;
  DiscoverResults? discover;
  for (final MapEntry(key: request, value: part) in parts.entries) {
    final results = part.value;
    if (results == null) continue;
    if (request.scope == SearchScope.discover) {
      discover = results.discover;
    } else {
      library = results.library;
    }
  }
  final sections = buildSearchSections(
    library,
    discover,
    playlists,
    query,
    scope,
  );
  if (!sections.isEmpty) return SearchFound(sections);
  if (states.any((part) => !part.hasValue && !part.hasError)) {
    return const SearchLoading();
  }
  return const SearchNothingFound();
}

/// Requests [query] over [scope] anew, after every request failed.
void retrySearch(WidgetRef ref, String query, SearchScope scope) {
  for (final request in searchRequests(query, scope)) {
    ref.invalidate(searchPartProvider(request));
  }
}
