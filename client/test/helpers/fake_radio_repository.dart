// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:soundspan/features/explore/explore.dart';
import 'package:soundspan/shared/domain/domain.dart';

import 'fake_clock.dart';

/// An in-memory [RadioRepository] answering its seeded lists as fresh
/// [Cached] reads and [tracks] for every station.
///
/// A station start records its station in [stations]; it waits for
/// [gate] when one is set, then throws [stationError] when set. Every call
/// is counted in [calls] by method name.
class FakeRadioRepository implements RadioRepository {
  /// The genres, as the server answers them.
  List<RadioGenre> genreList = [];

  /// The decades, as the server answers them.
  List<RadioDecade> decadeList = [];

  /// The tracks of every station.
  List<Track> tracks = [];

  /// What a station start throws, when set.
  Exception? stationError;

  /// What a station start waits for, when set.
  Completer<void>? gate;

  /// Every station started, in order.
  final List<RadioStation> stations = [];

  /// Calls by method name, such as `genres`.
  final Map<String, int> calls = {};

  /// How many times [method] was called.
  int count(String method) => calls[method] ?? 0;

  /// The override of the repository provider with this fake.
  Override get providerOverride =>
      radioRepositoryProvider.overrideWithValue(AsyncData(this));

  void _count(String method) =>
      calls.update(method, (n) => n + 1, ifAbsent: () => 1);

  Stream<Cached<V>> _read<V>(String method, V value) {
    _count(method);
    return Stream.value(
      Cached(value: value, fetchedAt: FakeClock.defaultStart),
    );
  }

  @override
  Stream<Cached<List<RadioGenre>>> genres() => _read('genres', genreList);

  @override
  Future<void> refreshGenres() async => _count('refreshGenres');

  @override
  Stream<Cached<List<RadioDecade>>> decades() => _read('decades', decadeList);

  @override
  Future<void> refreshDecades() async => _count('refreshDecades');

  @override
  Future<List<Track>> station(RadioStation station, {int limit = 50}) async {
    _count('station');
    stations.add(station);
    if (gate case final gate?) await gate.future;
    if (stationError case final error?) throw error;
    return tracks;
  }
}
