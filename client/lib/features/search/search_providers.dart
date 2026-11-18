// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The profile-scoped stores of Search, provided outside `data/` because
/// `ui/` may not import it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/features/search/data/search_history_store.dart';
import 'package:soundspan/shared/clock.dart';

/// The [SearchHistoryStore] of the profile's `state.db`.
final Provider<SearchHistoryStore> searchHistoryStoreProvider =
    Provider<SearchHistoryStore>(
      (ref) => SearchHistoryStore(
        ref.watch(stateDatabaseProvider),
        ref.watch(clockProvider),
      ),
      dependencies: [stateDatabaseProvider],
    );
