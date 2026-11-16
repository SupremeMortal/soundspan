// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The media-files seam: removes downloaded files (doc 02, Platform Seams;
/// doc 07, Removing Downloads).
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

/// Removes files of downloaded media.
abstract interface class MediaFiles {
  /// Deletes the file at the absolute [path]. A missing file is not an
  /// error; any other failure (for example a file another process holds
  /// open on Windows) throws.
  Future<void> delete(String path);
}

/// The process-wide [MediaFiles] of the platform; tests override it.
final Provider<MediaFiles> mediaFilesProvider = Provider<MediaFiles>(
  (ref) => createMediaFiles(),
);
