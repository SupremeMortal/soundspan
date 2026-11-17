// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/media_files/media_files.dart';

/// The [MediaFiles] of a browser, which has no files.
MediaFiles createMediaFiles() => const NoMediaFiles();

/// A [MediaFiles] with no files: nothing to measure, rename or delete.
final class NoMediaFiles implements MediaFiles {
  /// Creates the seam.
  const new();

  @override
  Future<int?> length(String path) async => null;

  @override
  Future<void> replace(String from, String to) =>
      throw UnsupportedError('a browser has no files to rename');

  @override
  Future<void> delete(String path) async {}

  @override
  Future<void> deleteTree(String path) async {}

  @override
  Future<List<String>> listFiles(String directory) async => const [];

  @override
  Future<void> removeEmptyDirectories(String directory) async {}
}
