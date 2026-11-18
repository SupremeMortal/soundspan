// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/features/mixes/domain/mix_detail.dart';
import 'package:soundspan/shared/domain/cached.dart';

/// The mixes of servers with `autoPlaylists` on, served from the cache and
/// refreshed in the background (doc 05, Read Policy:
/// Stale-While-Revalidate). Each read errors with `FeatureDisabled` when
/// the server has automatic playlists off.
abstract interface class MixRepository {
  /// The mix [mixId] with its tracks.
  Stream<Cached<MixDetail>> mix(String mixId);

  /// Fetches the mix [mixId] again, whatever its age.
  Future<void> refreshMix(String mixId);
}
