// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io' as io;

import 'package:file/file.dart' show File;
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/platform/image_cache/image_cache.dart';

/// The native image store of profile [profileId].
///
/// The image files and the store's index (`index.json`) live in
/// [directory], the profile's `images/` directory, which is created on first
/// use. With no [directory] the package's default location is used.
CacheManager createImageCacheManager({
  required String profileId,
  required String? directory,
}) {
  final key = imageCacheKey(profileId);
  if (directory == null) {
    return CacheManager(
      Config(
        key,
        stalePeriod: imageCacheStalePeriod,
        maxNrOfCacheObjects: imageCacheMaxObjects,
      ),
    );
  }
  return CacheManager(
    Config(
      key,
      stalePeriod: imageCacheStalePeriod,
      maxNrOfCacheObjects: imageCacheMaxObjects,
      repo: JsonCacheInfoRepository(path: p.join(directory, 'index.json')),
      fileSystem: _DirectoryFileSystem(directory),
    ),
  );
}

/// A [FileSystem] whose files are created in one directory.
class _DirectoryFileSystem implements FileSystem {
  new(this._directory);

  final String _directory;

  static const _fs = LocalFileSystem();

  @override
  Future<File> createFile(String name) async {
    await io.Directory(_directory).create(recursive: true);
    return _fs.directory(_directory).childFile(name);
  }
}
