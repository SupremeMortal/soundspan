// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Measuring and emptying the app's directories (`Settings → Storage`, doc
/// 07, Storage Accounting and Quota).
///
/// On native targets the work runs on a background isolate, off the UI
/// isolate; on web there are no files, so every size is zero and nothing
/// is deleted.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/platform/file_sizes/file_sizes_web.dart'
    if (dart.library.io) 'package:soundspan/platform/file_sizes/file_sizes_io.dart';

export 'file_sizes_web.dart'
    if (dart.library.io) 'file_sizes_io.dart'
    show createFileSizes;

/// Sizes of files and directories, and emptying a directory.
abstract interface class FileSizes {
  /// The bytes of every file under [path], recursively; zero when [path]
  /// does not exist.
  Future<int> directoryBytes(String path);

  /// The bytes of the files in [paths] together; a missing file counts as
  /// zero.
  Future<int> filesBytes(List<String> paths);

  /// Deletes everything under the directory [path] and keeps the directory
  /// itself; a missing directory is left missing.
  Future<void> clearDirectory(String path);
}

/// The platform's [FileSizes].
final Provider<FileSizes> fileSizesProvider = Provider<FileSizes>(
  (ref) => createFileSizes(),
);
