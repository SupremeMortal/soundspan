// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Relevance ranking of search results found on this device (doc 09,
/// Search), a port of the server's tier rule: a result's score is its
/// match tier, plus a within-tier value scaled below the next tier, plus a
/// small prior by kind that breaks ties (artist, album, song, playlist,
/// podcast).
library;

import 'package:soundspan/shared/domain/domain.dart';

/// The share of a tier the within-tier value may fill, so the best result
/// of a tier never reaches the worst of the next one.
const double _withinTierSpan = 0.99;

/// Letters folded to their base letters, as Unicode compatibility
/// decomposition without marks does, plus the server's ligature folds.
const Map<String, String> _foldGroups = {
  'a': 'àáâãäåāăąǎǻ',
  'c': 'çćĉċč',
  'd': 'ď',
  'e': 'èéêëēĕėęě',
  'g': 'ĝğġģǧ',
  'h': 'ĥ',
  'i': 'ìíîïĩīĭįǐ',
  'j': 'ĵ',
  'k': 'ķǩ',
  'l': 'ĺļľ',
  'n': 'ñńņňǹ',
  'o': 'òóôõöōŏőǒøǿ',
  'r': 'ŕŗř',
  's': 'śŝşšș',
  't': 'ţťț',
  'u': 'ùúûüũūŭůűųǔǖǘǚǜ',
  'w': 'ŵ',
  'y': 'ýÿŷ',
  'z': 'źżž',
  'ae': 'æǽ',
  'oe': 'œ',
  'ss': 'ß',
};

final Map<int, String> _folds = {
  for (final MapEntry(key: base, value: letters) in _foldGroups.entries)
    for (final rune in letters.runes) rune: base,
};

final RegExp _marks = RegExp(r'\p{M}+', unicode: true);
final RegExp _separators = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// [value] in lower case without diacritics, with every run of characters
/// other than letters and digits turned into one space, trimmed.
String foldForMatch(String value) {
  final buffer = StringBuffer();
  for (final rune in value.replaceAll(_marks, '').toLowerCase().runes) {
    buffer.write(_folds[rune] ?? String.fromCharCode(rune));
  }
  return buffer.toString().replaceAll(_separators, ' ').trim();
}

/// How closely [name] matches [query] after [foldForMatch]: 4 when equal,
/// 3 when [name] starts with [query], 2 when every word of [query] starts a
/// word of [name], otherwise 1.
int matchTier(String name, String query) {
  final foldedQuery = foldForMatch(query);
  if (foldedQuery.isEmpty) return 1;
  final foldedName = foldForMatch(name);
  if (foldedName == foldedQuery) return 4;
  if (foldedName.startsWith(foldedQuery)) return 3;
  final words = foldedName.split(' ');
  final tokens = foldedQuery.split(' ');
  return tokens.every((token) => words.any((word) => word.startsWith(token)))
      ? 2
      : 1;
}

/// The name of [hit] its tier is computed from: a song's or album's title,
/// an artist's, playlist's or podcast's name.
String primaryName(SearchHit hit) => switch (hit) {
  TrackHit(:final track) => track.meta.title,
  AlbumHit(:final album) => album.title,
  ArtistHit(:final artist) => artist.name,
  PlaylistHit(:final playlist) => playlist.name,
  PodcastHit(:final podcast) => podcast.title,
};

/// The tie-breaking prior of [hit]'s kind.
double _typePrior(SearchHit hit) => switch (hit) {
  ArtistHit() => 0.0004,
  AlbumHit() => 0.0003,
  TrackHit() => 0.0002,
  PlaylistHit() => 0.0001,
  PodcastHit() => 0,
};

/// The score of [hit] for [query], with [withinTier] (clamped to 0..1)
/// ordering results of the same tier.
double scoreSearchHit(SearchHit hit, String query, {double withinTier = 0}) =>
    matchTier(primaryName(hit), query) +
    withinTier.clamp(0, 1) * _withinTierSpan +
    _typePrior(hit);

/// [hits] scored for [query] and sorted best first; equal scores keep the
/// order of [hits]. A device has no full-text rank, so every within-tier
/// value is 0 and the order of [hits] decides within a tier and kind.
List<SearchResult> rankSearchHits(String query, List<SearchHit> hits) {
  final scored =
      [
        for (final (index, hit) in hits.indexed)
          (index, SearchResult(hit: hit, score: scoreSearchHit(hit, query))),
      ]..sort((left, right) {
        final byScore = right.$2.score.compareTo(left.$2.score);
        return byScore != 0 ? byScore : left.$1.compareTo(right.$1);
      });
  return [for (final (_, result) in scored) result];
}
