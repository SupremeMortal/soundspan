// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:soundspan/features/mixes/mixes.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' show ApiException, NotFound;

import 'fake_clock.dart';

/// An in-memory [MixRepository] answering its seeded [mixes] as fresh
/// [Cached] reads.
///
/// A mix id in [errors] errors with that error: a read emits it, a refresh
/// throws it. A mix id in [refreshErrors] answers its seeded value as
/// cached but failed to refresh with that error. Every call is recorded in
/// [calls] as `mix <id>` or `refreshMix <id>`.
class FakeMixRepository implements MixRepository {
  /// The mixes by id; an unknown id errors with `NotFound`.
  final Map<String, MixDetail> mixes = {};

  /// Errors by mix id.
  final Map<String, Exception> errors = {};

  /// Refresh errors by mix id.
  final Map<String, ApiException> refreshErrors = {};

  /// Every call, in order.
  final List<String> calls = [];

  /// The override of the repository provider with this fake.
  Override get providerOverride =>
      mixRepositoryProvider.overrideWithValue(AsyncData(this));

  @override
  Stream<Cached<MixDetail>> mix(String mixId) {
    calls.add('mix $mixId');
    if (errors[mixId] case final error?) return Stream.error(error);
    final mix = mixes[mixId];
    if (mix == null) return Stream.error(const NotFound(status: 404));
    return Stream.value(
      Cached(
        value: mix,
        fetchedAt: FakeClock.defaultStart,
        refreshError: refreshErrors[mixId],
      ),
    );
  }

  @override
  Future<void> refreshMix(String mixId) async {
    calls.add('refreshMix $mixId');
    if (errors[mixId] case final error?) throw error;
  }
}
