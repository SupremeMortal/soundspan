// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:soundspan/features/discover/discover.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' show ApiException;

import 'fake_clock.dart';

/// An in-memory [DiscoveryRepository] answering its seeded values as fresh
/// [Cached] reads.
///
/// A method named in [errors] errors with that error: a read emits it, a
/// refresh throws it. A method named in [refreshErrors] answers its seeded
/// value as cached but failed to refresh with that error. Every call is
/// counted in [calls] by method name.
class FakeDiscoveryRepository implements DiscoveryRepository {
  /// The recommended artists.
  List<DiscoveryArtist> recommended = [];

  /// The popular artists.
  List<DiscoveryArtist> popular = [];

  /// This week's discovery playlist; null when the server has none.
  DiscoveryPlaylist? playlist;

  /// Errors by method name.
  final Map<String, Exception> errors = {};

  /// Refresh errors by method name.
  final Map<String, ApiException> refreshErrors = {};

  /// Calls by method name, such as `popularArtists`.
  final Map<String, int> calls = {};

  /// How many times [method] was called.
  int count(String method) => calls[method] ?? 0;

  /// How many reads of any section were made.
  int get reads =>
      count('recommendedForYou') +
      count('popularArtists') +
      count('currentDiscovery');

  /// The override of the repository provider with this fake.
  Override get providerOverride =>
      discoveryRepositoryProvider.overrideWithValue(AsyncData(this));

  Stream<Cached<V>> _read<V>(String method, V value) {
    calls.update(method, (n) => n + 1, ifAbsent: () => 1);
    if (errors[method] case final error?) return Stream.error(error);
    return Stream.value(
      Cached(
        value: value,
        fetchedAt: FakeClock.defaultStart,
        refreshError: refreshErrors[method],
      ),
    );
  }

  Future<void> _refresh(String method) async {
    calls.update(method, (n) => n + 1, ifAbsent: () => 1);
    if (errors[method] case final error?) throw error;
  }

  @override
  Stream<Cached<List<DiscoveryArtist>>> recommendedForYou({int limit = 20}) =>
      _read('recommendedForYou', recommended);

  @override
  Future<void> refreshRecommendedForYou({int limit = 20}) =>
      _refresh('refreshRecommendedForYou');

  @override
  Stream<Cached<List<DiscoveryArtist>>> popularArtists({int limit = 20}) =>
      _read('popularArtists', popular);

  @override
  Future<void> refreshPopularArtists({int limit = 20}) =>
      _refresh('refreshPopularArtists');

  @override
  Stream<Cached<DiscoveryPlaylist?>> currentDiscovery() =>
      _read('currentDiscovery', playlist);

  @override
  Future<void> refreshCurrentDiscovery() => _refresh('refreshCurrentDiscovery');
}
