// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:soundspan/features/vibe/vibe.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// An in-memory [VibeRepository]: [similarTracks] for every library id and
/// [searchTracks] for every query of at least two characters.
///
/// Each call is recorded in [similarIds] or [queries]; it waits for [gate]
/// when one is set, then throws [similarError] or [searchError] when set.
class FakeVibeRepository implements VibeRepository {
  /// The answer of every [similar], by library id; an id without one
  /// answers [similarTracks].
  final Map<String, List<Track>> similarById = {};

  /// The answer of [similar] for ids without an entry in [similarById].
  List<Track> similarTracks = [];

  /// The answer of every [search].
  List<Track> searchTracks = [];

  /// What [similar] throws, when set.
  Exception? similarError;

  /// What [search] throws, when set.
  Exception? searchError;

  /// What each call waits for, when set.
  Completer<void>? gate;

  /// The library id of every [similar], in order.
  final List<String> similarIds = [];

  /// The trimmed query of every [search] that reached the server, in order.
  final List<String> queries = [];

  /// The override of the repository provider with this fake.
  Override get providerOverride =>
      vibeRepositoryProvider.overrideWithValue(this);

  @override
  Future<List<Track>> similar(String libraryId, {int limit = 50}) async {
    similarIds.add(libraryId);
    if (gate case final gate?) await gate.future;
    if (similarError case final error?) throw error;
    return similarById[libraryId] ?? similarTracks;
  }

  @override
  Future<List<Track>> search(String query, {int limit = 50}) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];
    queries.add(trimmed);
    if (gate case final gate?) await gate.future;
    if (searchError case final error?) throw error;
    return searchTracks;
  }
}
