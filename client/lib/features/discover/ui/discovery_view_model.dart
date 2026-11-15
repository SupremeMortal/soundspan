// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The state behind the discovery sections of Home and Explore: one
/// provider per section, gated by the server's `discovery` capability.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/features/discover/discover_providers.dart';
import 'package:soundspan/features/discover/domain/discovery_artist.dart';
import 'package:soundspan/features/discover/domain/discovery_playlist.dart';
import 'package:soundspan/features/discover/domain/discovery_repository.dart';
import 'package:soundspan/shared/domain/cached.dart';
import 'package:soundspan/shared/providers/capability_refresh.dart';
import 'package:soundspan_api/soundspan_api.dart' show FeatureDisabled;

/// Section providers report a failure once; the screens hide the section.
Duration? _noRetry(int _, Object _) => null;

/// Whether the active server has discovery on.
final Provider<bool> discoveryEnabledProvider = Provider<bool>(
  (ref) =>
      ref.watch(serverCapabilitiesProvider.select((value) => value.discovery)),
  dependencies: [serverCapabilitiesProvider],
);

/// "Recommended For You", from cache first; null while the server has
/// `discovery` off (nothing is requested) or answers `FeatureDisabled` (a
/// capability refresh is requested).
final StreamProvider<List<DiscoveryArtist>?> recommendedForYouProvider =
    StreamProvider.autoDispose<List<DiscoveryArtist>?>(
      (ref) => _gated(ref, (repository) => repository.recommendedForYou()),
      retry: _noRetry,
      dependencies: [
        discoveryEnabledProvider,
        discoveryRepositoryProvider,
        capabilityRefreshProvider,
      ],
    );

/// "Popular Artists", from cache first; null as for
/// [recommendedForYouProvider].
final StreamProvider<List<DiscoveryArtist>?> popularArtistsProvider =
    StreamProvider.autoDispose<List<DiscoveryArtist>?>(
      (ref) => _gated(ref, (repository) => repository.popularArtists()),
      retry: _noRetry,
      dependencies: [
        discoveryEnabledProvider,
        discoveryRepositoryProvider,
        capabilityRefreshProvider,
      ],
    );

/// This week's discovery playlist, from cache first; null when the server
/// has none, and as for [recommendedForYouProvider].
final StreamProvider<DiscoveryPlaylist?> currentDiscoveryProvider =
    StreamProvider.autoDispose<DiscoveryPlaylist?>(
      (ref) => _gated<DiscoveryPlaylist?>(
        ref,
        (repository) => repository.currentDiscovery(),
      ),
      retry: _noRetry,
      dependencies: [
        discoveryEnabledProvider,
        discoveryRepositoryProvider,
        capabilityRefreshProvider,
      ],
    );

Stream<T?> _gated<T>(
  Ref ref,
  Stream<Cached<T>> Function(DiscoveryRepository repository) read,
) async* {
  if (!ref.watch(discoveryEnabledProvider)) {
    yield null;
    return;
  }
  final repository = await ref.watch(discoveryRepositoryProvider.future);
  try {
    await for (final cached in read(repository)) {
      if (cached.refreshError is FeatureDisabled) {
        ref.read(capabilityRefreshProvider)();
        yield null;
        return;
      }
      yield cached.value;
    }
  } on FeatureDisabled {
    ref.read(capabilityRefreshProvider)();
    yield null;
  }
}

/// Fetches every discovery section that is on screen again: a section
/// that failed with nothing cached is requested anew; the others are
/// refreshed whatever their age. Nothing happens while discovery is off.
/// Errors of a refresh are dropped, because each section keeps showing
/// what it has.
Future<void> refreshDiscovery(WidgetRef ref) async {
  if (!ref.read(discoveryEnabledProvider)) return;
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
    Future<void> Function(DiscoveryRepository repository) refresh,
  ) {
    if (!ref.read(provider.exists)) return;
    final state = ref.read(provider);
    if (state.hasError && !state.hasValue) {
      ref.invalidate(provider);
      return;
    }
    final repository = ref.read(discoveryRepositoryProvider).value;
    if (repository != null) refreshes.add(quietly(() => refresh(repository)));
  }

  each(
    recommendedForYouProvider,
    (repository) => repository.refreshRecommendedForYou(),
  );
  each(
    popularArtistsProvider,
    (repository) => repository.refreshPopularArtists(),
  );
  each(
    currentDiscoveryProvider,
    (repository) => repository.refreshCurrentDiscovery(),
  );
  await Future.wait(refreshes);
}

/// Requests every discovery section anew.
void retryDiscovery(WidgetRef ref) {
  ref
    ..invalidate(recommendedForYouProvider)
    ..invalidate(popularArtistsProvider)
    ..invalidate(currentDiscoveryProvider);
}
