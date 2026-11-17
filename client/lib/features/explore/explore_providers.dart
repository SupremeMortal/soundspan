// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The profile-scoped [RadioRepository], provided outside `data/` because
/// `ui/` may not import it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/features/explore/data/radio_repository.dart';
import 'package:soundspan/features/explore/domain/radio_repository.dart';
import 'package:soundspan/shared/providers/cache.dart';
import 'package:soundspan/shared/providers/repositories.dart';

/// The profile's [RadioRepository], over the generated `DiscoveryClient`.
final FutureProvider<RadioRepository> radioRepositoryProvider =
    FutureProvider<RadioRepository>(
      (ref) async => CachedRadioRepository(
        ref.watch(soundspanApiProvider).rest.discovery,
        await ref.watch(cacheStoreProvider.future),
        ref.watch(swrProvider),
      ),
      dependencies: [soundspanApiProvider, cacheStoreProvider, swrProvider],
    );
