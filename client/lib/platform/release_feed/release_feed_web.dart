// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/release_feed/release_feed.dart';

/// The [ReleaseFeed] of a browser: the host updates the web app, so there
/// are no releases to offer.
ReleaseFeed createReleaseFeed() => const _NoReleases();

class _NoReleases implements ReleaseFeed {
  const new();

  @override
  Future<List<ReleaseInfo>> fetch(String repository) async => const [];
}
