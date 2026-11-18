// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:soundspan/features/podcasts/podcasts.dart';
import 'package:soundspan/features/podcasts/podcasts_providers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' show NotFound;

/// An in-memory [PodcastRepository].
///
/// [subscribedList] is the subscribed list; [details] the podcast details
/// (a missing one errors with [NotFound]). A method named in [errors]
/// errors with that error: a read emits it, a write throws it. Every call
/// is counted in [calls]; the writes are recorded in [subscribedRefs] and
/// [unsubscribed].
class FakePodcastRepository implements PodcastRepository {
  /// The subscribed podcasts.
  List<Podcast> subscribedList = [];

  /// Podcast details by id.
  final Map<String, PodcastDetail> details = {};

  /// Errors by method name.
  final Map<String, Exception> errors = {};

  /// Calls by method name.
  final Map<String, int> calls = {};

  /// The references passed to [subscribe], in order.
  final List<PodcastRef> subscribedRefs = [];

  /// The ids passed to [unsubscribe], in order.
  final List<String> unsubscribed = [];

  /// The id [subscribe] answers.
  String subscribeId = 'pc-new';

  /// When the subscribed list was fetched.
  DateTime fetchedAt = DateTime.utc(2026, 3);

  /// The override of the repository provider with this fake.
  Override get providerOverride =>
      podcastRepositoryProvider.overrideWithValue(AsyncData(this));

  /// How many times [method] was called.
  int count(String method) => calls[method] ?? 0;

  void _call(String method) =>
      calls.update(method, (n) => n + 1, ifAbsent: () => 1);

  Stream<Cached<V>> _read<V>(String method, V? value) {
    _call(method);
    if (errors[method] case final error?) return Stream.error(error);
    if (value == null) return Stream.error(const NotFound());
    return Stream.value(Cached(value: value, fetchedAt: fetchedAt));
  }

  Future<void> _write(String method) async {
    _call(method);
    if (errors[method] case final error?) throw error;
  }

  @override
  Stream<Cached<List<Podcast>>> subscribed() =>
      _read('subscribed', subscribedList);

  @override
  Future<void> refreshSubscribed() => _write('refreshSubscribed');

  @override
  Stream<Cached<PodcastDetail>> detail(String podcastId) =>
      _read('detail', details[podcastId]);

  @override
  Future<void> refreshDetail(String podcastId) => _write('refreshDetail');

  @override
  Future<String> subscribe(PodcastRef ref) async {
    await _write('subscribe');
    subscribedRefs.add(ref);
    return subscribeId;
  }

  @override
  Future<void> unsubscribe(String podcastId) async {
    await _write('unsubscribe');
    unsubscribed.add(podcastId);
  }

  @override
  Future<void> postProgress({
    required String podcastId,
    required String episodeId,
    required double currentTimeSec,
    required int durationSec,
    required bool isFinished,
  }) => _write('postProgress');
}
