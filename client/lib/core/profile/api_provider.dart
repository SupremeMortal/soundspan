// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// The [SoundspanApi] of the profile scope, built from [apiConfigProvider]
/// with the [sessionControllerProvider] as its credential provider, and
/// closed through the [ProfileDisposer] when the scope ends. Every
/// repository uses it.
final Provider<SoundspanApi> soundspanApiProvider = Provider<SoundspanApi>(
  (ref) {
    final api = SoundspanApi(
      ref.watch(apiConfigProvider),
      credentials: ref.watch(sessionControllerProvider),
    );
    ref.watch(profileDisposerProvider).register(() async => api.close());
    return api;
  },
  dependencies: [
    apiConfigProvider,
    sessionControllerProvider,
    profileDisposerProvider,
  ],
);
