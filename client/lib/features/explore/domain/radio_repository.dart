// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/features/explore/domain/radio_station.dart';
import 'package:soundspan/shared/domain/cached.dart';
import 'package:soundspan/shared/domain/track.dart';

/// The radio stations of Explore (doc 03, "Home, discovery, social"): the
/// library's genres and decades, served from the cache and refreshed in
/// the background, and a station's tracks, fetched fresh on every start.
/// Radio needs no server feature.
abstract interface class RadioRepository {
  /// The library's genres, as the server orders them.
  Stream<Cached<List<RadioGenre>>> genres();

  /// Fetches [genres] again, whatever its age.
  Future<void> refreshGenres();

  /// The library's decades, as the server orders them.
  Stream<Cached<List<RadioDecade>>> decades();

  /// Fetches [decades] again, whatever its age.
  Future<void> refreshDecades();

  /// A new selection of at most [limit] tracks of [station]; tracks the
  /// server cannot play have no `playbackId`.
  Future<List<Track>> station(RadioStation station, {int limit = 50});
}
