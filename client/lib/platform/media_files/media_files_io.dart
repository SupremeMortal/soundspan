// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:soundspan/platform/media_files/media_files.dart';

/// The [MediaFiles] of the operating system the app runs on.
MediaFiles createMediaFiles() => const IoMediaFiles();

/// Deletes files through `dart:io`.
final class IoMediaFiles implements MediaFiles {
  /// Creates the seam.
  const new();

  @override
  Future<void> delete(String path) async {
    try {
      await File(path).delete();
    } on PathNotFoundException {
      // Already gone.
    }
  }
}
