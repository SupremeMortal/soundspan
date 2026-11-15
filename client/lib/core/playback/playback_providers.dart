// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/playback/data/playback_info_repository.dart';
import 'package:soundspan/core/profile/api_provider.dart';

/// The [PlaybackInfoRepository] of the profile scope; its cache lives as
/// long as the scope.
final Provider<PlaybackInfoRepository> playbackInfoRepositoryProvider =
    Provider<PlaybackInfoRepository>(
      (ref) =>
          PlaybackInfoRepository(ref.watch(soundspanApiProvider).rest.playback),
      dependencies: [soundspanApiProvider],
    );
