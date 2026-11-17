// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
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

  @override
  Future<bool> exists(String path) async => File(path).existsSync();

  @override
  Future<List<String>> list(String directory) async {
    final dir = Directory(directory);
    if (!dir.existsSync()) return const [];
    return await dir
        .list(followLinks: false)
        .where((entity) => entity is File)
        .map((entity) => p.basename(entity.path))
        .toList();
  }

  @override
  Future<void> delete(String path) async {
    try {
      await File(path).delete();
    } on PathNotFoundException {
      // Already gone.
    }
  }
}
