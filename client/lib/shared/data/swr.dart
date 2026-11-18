// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/domain/cached.dart';
import 'package:soundspan_api/soundspan_api.dart' show ApiException, Offline;

/// How long a list page is fresh (doc 05, TTL table).
const Duration listPageTtl = Duration(minutes: 5);

/// How long an album, artist or playlist detail is fresh.
const Duration detailTtl = Duration(minutes: 10);

/// How long a home shelf is fresh.
const Duration homeShelfTtl = Duration(minutes: 5);

/// How long a search result is fresh.
const Duration searchTtl = Duration(minutes: 2);

/// Stale-while-revalidate reads over the cache (doc 05, Read Policy).
///
/// One instance is shared by the repositories of a profile, so concurrent
/// listeners of one key share one fetch.
class Swr {
  /// Reads the time from `clock` and the server's state from
  /// `reachability`.
  new({required this._clock, required this._reachability});

  final Clock _clock;
  final ReachabilityController _reachability;
  final Map<String, Future<void>> _inflight = {};

  /// The value of [key] as the cache holds it, kept fresh by [fetch].
  ///
  /// [cache] watches the cached value; [fetch] gets the value from the
  /// server and writes it to the cache, which makes [cache] emit. When
  /// [ttlOf] is given, it chooses the TTL of a cached value in place of
  /// [ttl].
  ///
  /// 1. The cached value is emitted at once if present.
  /// 2. If it is older than [ttl] and the server is reachable, it is
  ///    fetched; meanwhile the cached value is emitted with `refreshing`.
  /// 3. On success the new value is emitted from the cache.
  /// 4. On failure the cached value is re-emitted with `refreshError`; with
  ///    nothing cached, the stream errors.
  ///
  /// While the server is not reachable the cached value is emitted whatever
  /// its age and nothing is fetched; with nothing cached the stream errors
  /// with [Offline].
  Stream<Cached<T>> watch<T>({
    required String key,
    required Duration ttl,
    required Stream<CacheEntry<T>?> Function() cache,
    required Future<void> Function() fetch,
    Duration Function(T value)? ttlOf,
  }) {
    late final StreamController<Cached<T>> controller;
    StreamSubscription<CacheEntry<T>?>? subscription;
    CacheEntry<T>? latest;
    var seen = false;
    var fetching = false;
    Cached<T>? last;
    ({DateTime fetchedAt, ApiException error})? failure;

    void emit(CacheEntry<T> entry, {bool refreshing = false}) {
      final error = failure != null && failure!.fetchedAt == entry.fetchedAt
          ? failure!.error
          : null;
      final next = Cached(
        value: entry.value,
        fetchedAt: entry.fetchedAt,
        refreshing: refreshing,
        refreshError: error,
      );
      if (last case final previous?
          when previous.fetchedAt == next.fetchedAt &&
              previous.refreshing == next.refreshing &&
              previous.refreshError == next.refreshError &&
              const DeepCollectionEquality().equals(
                previous.value,
                next.value,
              )) {
        return;
      }
      last = next;
      controller.add(next);
    }

    void startFetch() {
      fetching = true;
      final before = latest?.fetchedAt;
      unawaited(
        _run(key, fetch).then(
          (_) {
            fetching = false;
            if (controller.isClosed) return;
            // Otherwise the cache emits the new value when its write lands.
            if (latest case final entry? when entry.fetchedAt != before) {
              emit(entry);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            fetching = false;
            if (controller.isClosed) return;
            final entry = latest;
            if (entry != null && error is ApiException) {
              failure = (fetchedAt: entry.fetchedAt, error: error);
              emit(entry);
            } else {
              controller.addError(error, stackTrace);
            }
          },
        ),
      );
    }

    void onEntry(CacheEntry<T>? entry) {
      latest = entry;
      if (seen) {
        if (!fetching && entry != null) emit(entry);
        return;
      }
      seen = true;
      final online = _reachability.isOnline;
      if (entry == null) {
        if (online) {
          startFetch();
        } else {
          controller.addError(const Offline());
        }
        return;
      }
      final stale =
          _clock.now().difference(entry.fetchedAt) >
          (ttlOf?.call(entry.value) ?? ttl);
      if (stale && online) {
        startFetch();
        emit(entry, refreshing: true);
      } else {
        emit(entry);
      }
    }

    controller = StreamController<Cached<T>>(
      onListen: () {
        subscription = cache().listen(onEntry, onError: controller.addError);
      },
      onCancel: () async {
        await subscription?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  /// Fetches [key] with [fetch] whatever the age of the cached value, as
  /// pull-to-refresh does. Throws [Offline] without fetching while the
  /// server is not reachable, and the fetch's error when it fails.
  Future<void> refresh(String key, Future<void> Function() fetch) async {
    if (!_reachability.isOnline) throw const Offline();
    await _run(key, fetch);
  }

  /// Runs [fetch] for [key], or joins the fetch of [key] already in flight,
  /// and reports its outcome to reachability: an [Offline] failure is a
  /// failed call, anything else a response.
  Future<void> _run(String key, Future<void> Function() fetch) =>
      _inflight[key] ??= () async {
        try {
          await fetch();
          _reachability.reportCallOutcome(success: true);
        } on Offline {
          _reachability.reportCallOutcome(success: false);
          rethrow;
        } on ApiException {
          _reachability.reportCallOutcome(success: true);
          rethrow;
        } finally {
          unawaited(_inflight.remove(key));
        }
      }();
}
