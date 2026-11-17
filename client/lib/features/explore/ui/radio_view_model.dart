// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The state behind Explore's radio sections. Radio needs no server
/// feature, so nothing here is gated.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/features/explore/domain/radio_repository.dart';
import 'package:soundspan/features/explore/domain/radio_station.dart';
import 'package:soundspan/features/explore/explore_providers.dart';
import 'package:soundspan/shared/domain/track.dart';

/// A failed list is reported once; the screen hides its section.
Duration? _noRetry(int _, Object _) => null;

/// The library's genres, most tracks first, from cache first.
final StreamProvider<List<RadioGenre>> radioGenresProvider =
    StreamProvider.autoDispose<List<RadioGenre>>(
      (ref) async* {
        final repository = await ref.watch(radioRepositoryProvider.future);
        await for (final cached in repository.genres()) {
          yield _byCount(cached.value);
        }
      },
      retry: _noRetry,
      dependencies: [radioRepositoryProvider],
    );

/// The library's decades, newest first, from cache first.
final StreamProvider<List<RadioDecade>> radioDecadesProvider =
    StreamProvider.autoDispose<List<RadioDecade>>(
      (ref) async* {
        final repository = await ref.watch(radioRepositoryProvider.future);
        await for (final cached in repository.decades()) {
          yield [...cached.value]..sort((a, b) => b.decade.compareTo(a.decade));
        }
      },
      retry: _noRetry,
      dependencies: [radioRepositoryProvider],
    );

/// [genres] by track count, most first; genres with equal counts keep
/// their order.
List<RadioGenre> _byCount(List<RadioGenre> genres) {
  final indexed = [...genres.indexed]
    ..sort((a, b) {
      final byCount = b.$2.trackCount.compareTo(a.$2.trackCount);
      return byCount != 0 ? byCount : a.$1.compareTo(b.$1);
    });
  return [for (final (_, genre) in indexed) genre];
}

/// Fetches the radio lists that are on screen again: a list that failed
/// with nothing cached is requested anew; the others are refreshed
/// whatever their age. Errors of a refresh are dropped, because each list
/// keeps showing what it has.
Future<void> refreshRadio(WidgetRef ref) async {
  final refreshes = <Future<void>>[];
  Future<void> quietly(Future<void> Function() refresh) async {
    try {
      await refresh();
    } on Object {
      // The section keeps its cached value; its stream reports the failure.
    }
  }

  void each(
    StreamProvider<Object?> provider,
    Future<void> Function(RadioRepository repository) refresh,
  ) {
    if (!ref.read(provider.exists)) return;
    final state = ref.read(provider);
    if (state.hasError && !state.hasValue) {
      ref.invalidate(provider);
      return;
    }
    final repository = ref.read(radioRepositoryProvider).value;
    if (repository != null) refreshes.add(quietly(() => refresh(repository)));
  }

  each(radioGenresProvider, (repository) => repository.refreshGenres());
  each(radioDecadesProvider, (repository) => repository.refreshDecades());
  await Future.wait(refreshes);
}

/// Starts [station]: a fresh selection of its tracks from the server.
Future<List<Track>> startStation(WidgetRef ref, RadioStation station) async {
  final repository = await ref.read(radioRepositoryProvider.future);
  return await repository.station(station);
}
