// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// Builds a profile's [SoundspanApi] from its config and credential
/// provider.
typedef SoundspanApiFactory = SoundspanApi Function(
  ApiConfig config,
  CredentialProvider credentials,
);

/// How [soundspanApiProvider] builds its API: [SoundspanApi.new] over the
/// platform's HTTP adapter unless overridden. Tests override it to talk to
/// a fake server.
final Provider<SoundspanApiFactory> soundspanApiFactoryProvider =
    Provider<SoundspanApiFactory>(
      (ref) =>
          (config, credentials) =>
              SoundspanApi(config, credentials: credentials),
    );

/// The [SoundspanApi] of the profile scope, built from [apiConfigProvider]
/// with the [sessionControllerProvider] as its credential provider, and
/// closed through the [ProfileDisposer] when the scope ends. Every
/// repository uses it. Its single-flight session renewal becomes the
/// session controller's refresher.
final Provider<SoundspanApi> soundspanApiProvider = Provider<SoundspanApi>(
  (ref) {
    final session = ref.watch(sessionControllerProvider);
    final api = ref.watch(soundspanApiFactoryProvider)(
      ref.watch(apiConfigProvider),
      session,
    );
    session.refresher = api.refreshSession;
    ref.watch(profileDisposerProvider).register(() async => api.close());
    return api;
  },
  dependencies: [
    apiConfigProvider,
    sessionControllerProvider,
    profileDisposerProvider,
  ],
);
