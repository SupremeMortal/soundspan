// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The profile-scoped [VibeRepository] and the gates of Vibe, provided
/// outside `data/` because `ui/` may not import it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/features/vibe/data/vibe_repository.dart';
import 'package:soundspan/features/vibe/domain/vibe_repository.dart';
import 'package:soundspan/shared/clock.dart';

/// The profile's [VibeRepository], over the generated `DiscoveryClient`.
final Provider<VibeRepository> vibeRepositoryProvider =
    Provider<VibeRepository>(
      (ref) => ApiVibeRepository(
        ref.watch(soundspanApiProvider).rest.discovery,
        ref.watch(clockProvider),
      ),
      dependencies: [soundspanApiProvider],
    );

/// Whether a Vibe call answered `FeatureDisabled` since the capabilities
/// last changed; Vibe stays hidden until a capability refresh says
/// otherwise.
class VibeTurnedOffNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(serverCapabilitiesProvider);
    return false;
  }

  /// Hides Vibe until the capabilities change.
  void turnOff() => state = true;
}

/// Whether a Vibe call answered `FeatureDisabled`.
final NotifierProvider<VibeTurnedOffNotifier, bool> vibeTurnedOffProvider =
    NotifierProvider<VibeTurnedOffNotifier, bool>(
      VibeTurnedOffNotifier.new,
      dependencies: [serverCapabilitiesProvider],
    );

/// Whether the server offers similar tracks: `audioAnalysis` is on and no
/// call answered `FeatureDisabled` since.
final Provider<bool> vibeAvailableProvider = Provider<bool>(
  (ref) =>
      ref.watch(
        serverCapabilitiesProvider.select((value) => value.audioAnalysis),
      ) &&
      !ref.watch(vibeTurnedOffProvider),
  dependencies: [serverCapabilitiesProvider, vibeTurnedOffProvider],
);

/// Whether the server also searches by description: [vibeAvailableProvider]
/// and the server's `vibeEmbeddings` flag.
final Provider<bool> vibeSearchAvailableProvider = Provider<bool>(
  (ref) =>
      ref.watch(vibeAvailableProvider) &&
      ref.watch(serverCapabilitiesProvider.select((value) => value.vibe)),
  dependencies: [vibeAvailableProvider, serverCapabilitiesProvider],
);
