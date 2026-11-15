// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The profile-scoped [DiscoveryRepository], provided outside `data/`
/// because `ui/` may not import it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/features/discover/data/cached_discovery_repository.dart';
import 'package:soundspan/features/discover/domain/discovery_repository.dart';
import 'package:soundspan/shared/providers/cache.dart';
import 'package:soundspan/shared/providers/repositories.dart';

/// The profile's [DiscoveryRepository], over the generated
/// `DiscoveryClient`.
final FutureProvider<DiscoveryRepository> discoveryRepositoryProvider =
    FutureProvider<DiscoveryRepository>(
      (ref) async => CachedDiscoveryRepository(
        ref.watch(soundspanApiProvider).rest.discovery,
        await ref.watch(cacheStoreProvider.future),
        ref.watch(swrProvider),
      ),
      dependencies: [soundspanApiProvider, cacheStoreProvider, swrProvider],
    );
