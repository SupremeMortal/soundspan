// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Fetches a cover through the profile's authenticated image cache and
/// writes it as a local file (doc 05, Image Cache and Files on Disk; doc
/// 06, OS Media Controls). Shared by the now-playing artwork of the OS
/// media controls and the artwork pinned for downloads.
library;

import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:soundspan/platform/artwork_store/artwork_store.dart';
import 'package:soundspan/shared/providers/images.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// Fetches the bytes of one cover through the profile's authenticated image
/// cache.
typedef ArtworkBytesFetcher = Future<Uint8List> Function(ArtworkFetch fetch);

/// The pixel size of every cover written as a local file: the snapped size
/// the OS media controls use, so the image cache entry is shared.
const int localArtworkPixelSize = 512;

/// How the [localArtworkPixelSize] cover [ref] is fetched from the server
/// of [urls] with [credentials]; see [artworkFetch].
ArtworkFetch localArtworkFetch(
  String ref, {
  required ImageUrls urls,
  required Credentials? credentials,
  required bool isWeb,
}) => artworkFetch(
  ArtworkRequest(
    ref,
    logicalPx: localArtworkPixelSize.toDouble(),
    devicePixelRatio: 1,
  ),
  urls: urls,
  credentials: credentials,
  isWeb: isWeb,
);

/// Fetches the [localArtworkPixelSize] cover [ref] with [fetch] and writes
/// it to [path] through [store]; answers the file's URI, or null where the
/// store keeps no files. Errors of the fetch or the write are thrown.
Future<Uri?> fetchAndStoreArtwork(
  String ref, {
  required String path,
  required ImageUrls urls,
  required Credentials? credentials,
  required ArtworkBytesFetcher fetch,
  required ArtworkStore store,
}) async {
  final bytes = await fetch(
    localArtworkFetch(ref, urls: urls, credentials: credentials, isWeb: false),
  );
  return await store.write(path, bytes);
}

/// An [ArtworkBytesFetcher] reading through [manager], the profile's image
/// cache.
ArtworkBytesFetcher imageCacheBytesFetcher(BaseCacheManager manager) =>
    (fetch) async {
      final file = await manager.getSingleFile(
        fetch.url.toString(),
        key: fetch.cacheKey,
        headers: fetch.headers,
      );
      return await file.readAsBytes();
    };
