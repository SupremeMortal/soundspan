// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The artwork store seam (doc 06, OS Media Controls; doc 05, Files on
/// Disk).
///
/// `createArtworkStore` returns, on native targets, a store that writes
/// artwork files under a profile's `art/` directory; on web, one that
/// stores nothing, since there are no files.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/platform/artwork_store/artwork_store_web.dart'
    if (dart.library.io) 'package:soundspan/platform/artwork_store/artwork_store_io.dart';

export 'artwork_store_web.dart'
    if (dart.library.io) 'artwork_store_io.dart'
    show artworkFileImage, createArtworkStore;

/// Writes, lists and deletes artwork files the OS can load without
/// credentials.
abstract interface class ArtworkStore {
  /// Replaces the file at [path] with [bytes] and returns its `file://`
  /// URI, or null where nothing is stored.
  Future<Uri?> write(String path, Uint8List bytes);

  /// Whether a file exists at [path]; always false where nothing is
  /// stored.
  Future<bool> exists(String path);

  /// The names of the files directly in [directory]; empty when it does
  /// not exist or nothing is stored.
  Future<List<String>> list(String directory);

  /// Deletes the file at [path]; a missing file is not an error.
  Future<void> delete(String path);
}

/// The platform's [ArtworkStore]; tests override it.
final Provider<ArtworkStore> artworkStoreProvider = Provider<ArtworkStore>(
  (ref) => createArtworkStore(),
);
