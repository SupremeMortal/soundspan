// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The profile-scoped [ListenTogetherRepository], provided outside `data/`
/// because `ui/` may not import it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/features/listen_together/data/listen_together_repository.dart';

/// The profile's [ListenTogetherRepository], over the generated
/// `ListenTogetherClient`.
final Provider<ListenTogetherRepository> listenTogetherRepositoryProvider =
    Provider<ListenTogetherRepository>(
      (ref) => ListenTogetherRepository(
        ref.watch(soundspanApiProvider).rest.listenTogether,
      ),
      dependencies: [soundspanApiProvider],
    );
