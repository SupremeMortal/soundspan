// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/shared/domain/track.dart';

/// Vibe (doc 03, "Home, discovery, social"; gate `audioAnalysis`): tracks
/// that sound like a library track, and tracks found by a description.
/// Nothing is cached; similarity scores and audio features are not
/// surfaced.
abstract interface class VibeRepository {
  /// At most [limit] tracks similar to the library track [libraryId]; empty
  /// when the server finds none. Answers within five minutes of an earlier
  /// call for the same id come from that call.
  Future<List<Track>> similar(String libraryId, {int limit = 50});

  /// At most [limit] tracks matching the description [query]. The query is
  /// trimmed; one shorter than [minQueryLength] or longer than
  /// [maxQueryLength] makes no request and answers an empty list.
  Future<List<Track>> search(String query, {int limit = 50});
}

/// The shortest description [VibeRepository.search] sends.
const int minQueryLength = 2;

/// The longest description [VibeRepository.search] sends.
const int maxQueryLength = 200;
