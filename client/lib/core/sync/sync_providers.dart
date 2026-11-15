// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/sync/data/playback_state_repository.dart';
import 'package:soundspan/core/sync/data/plays_repository.dart';

/// The [PlaysRepository] of the profile scope.
final Provider<PlaysRepository> playsRepositoryProvider =
    Provider<PlaysRepository>(
      (ref) => PlaysRepository(ref.watch(soundspanApiProvider).rest.playback),
      dependencies: [soundspanApiProvider],
    );

/// The [PlaybackStateRepository] of the profile scope.
final Provider<PlaybackStateRepository> playbackStateRepositoryProvider =
    Provider<PlaybackStateRepository>(
      (ref) => PlaybackStateRepository(
        ref.watch(soundspanApiProvider).rest.playback,
      ),
      dependencies: [soundspanApiProvider],
    );
