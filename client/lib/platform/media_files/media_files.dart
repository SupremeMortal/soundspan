// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The media-files seam: measures, renames and removes downloaded files
/// (doc 02, Platform Seams; doc 07, Verification and Removing Downloads).
///
/// Native targets use `dart:io`. On web there are no files and every call
/// does nothing.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/platform/media_files/media_files_web.dart'
    if (dart.library.io) 'package:soundspan/platform/media_files/media_files_io.dart';

export 'media_files_web.dart'
    if (dart.library.io) 'media_files_io.dart'
    show createMediaFiles;

/// Measures, renames and removes files of downloaded media.
abstract interface class MediaFiles {
  /// The size in bytes of the file at the absolute [path], or null when
  /// there is no such file.
  Future<int?> length(String path);

  /// Renames the file at [from] to [to], in the same directory, replacing a
  /// file already at [to]. Throws when the rename fails.
  Future<void> replace(String from, String to);

  /// Deletes the file at the absolute [path]. A missing file is not an
  /// error; any other failure (for example a file another process holds
  /// open on Windows) throws.
  Future<void> delete(String path);

  /// Deletes every file under the directory [path], then the directory. A
  /// file that cannot be deleted is skipped and the others are still
  /// deleted; the first failure is thrown at the end and the directory is
  /// left. A missing directory is not an error.
  Future<void> deleteTree(String path);
}

/// The process-wide [MediaFiles] of the platform; tests override it.
final Provider<MediaFiles> mediaFilesProvider = Provider<MediaFiles>(
  (ref) => createMediaFiles(),
);
