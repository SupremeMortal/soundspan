// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The image cache seam: the per-profile store of downloaded artwork (doc 05,
/// Image Cache).
///
/// `createImageCacheManager()` returns, on native targets, a store whose
/// files and index live in the profile's `images/` directory, and on web the
/// package's default store.
library;

export 'image_cache_web.dart'
    if (dart.library.io) 'image_cache_io.dart'
    show createImageCacheManager;

/// How long a cached image is used without asking the server again.
const Duration imageCacheStalePeriod = Duration(days: 30);

/// The most images the store keeps.
///
/// The store limits by object count, not bytes, so the 500 MB cap of doc 05
/// is expressed as a count: 10,000 covers at about 50 KB each.
const int imageCacheMaxObjects = 10000;

/// The key of the store of profile [profileId], unique per profile.
String imageCacheKey(String profileId) => 'soundspan-images-$profileId';
