// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';
import 'dart:typed_data';

import 'package:soundspan/platform/artwork_store/artwork_store.dart';

/// The native [ArtworkStore].
ArtworkStore createArtworkStore() => const IoArtworkStore();

/// Writes each file to a temporary sibling, then renames it over the
/// target, so a reader never sees half a file.
final class IoArtworkStore implements ArtworkStore {
  /// Creates the store.
  const new();

  @override
  Future<Uri?> write(String path, Uint8List bytes) async {
    final target = File(path);
    await target.parent.create(recursive: true);
    final temporary = File('$path.tmp');
    await temporary.writeAsBytes(bytes, flush: true);
    await temporary.rename(path);
    return target.uri;
  }
}
