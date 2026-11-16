// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:typed_data';

import 'package:soundspan/platform/artwork_store/artwork_store.dart';

/// The web [ArtworkStore].
ArtworkStore createArtworkStore() => const WebArtworkStore();

/// Stores nothing: the web has no files, and the Media Session API loads
/// the cover URL instead.
final class WebArtworkStore implements ArtworkStore {
  /// Creates the store.
  const new();

  @override
  Future<Uri?> write(String path, Uint8List bytes) async => null;
}
