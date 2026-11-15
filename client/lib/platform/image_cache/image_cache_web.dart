// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:soundspan/platform/image_cache/image_cache.dart';

/// The web image store of profile [profileId]: the package default, which
/// leaves storage to the browser's HTTP cache. [directory] is ignored.
CacheManager createImageCacheManager({
  required String profileId,
  required String? directory,
}) => CacheManager(
  Config(
    imageCacheKey(profileId),
    stalePeriod: imageCacheStalePeriod,
    maxNrOfCacheObjects: imageCacheMaxObjects,
  ),
);
