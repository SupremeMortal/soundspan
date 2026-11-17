// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:soundspan/platform/media_files/media_files.dart';

/// The [MediaFiles] of the operating system the app runs on.
MediaFiles createMediaFiles() => const IoMediaFiles();

/// Measures, renames and deletes files through `dart:io`.
final class IoMediaFiles implements MediaFiles {
  /// Creates the seam.
  const new();

  @override
  Future<int?> length(String path) async {
    try {
      return await File(path).length();
    } on PathNotFoundException {
      return null;
    }
  }

  @override
  Future<void> replace(String from, String to) async {
    // A rename within one directory is atomic, but Windows refuses to
    // rename over an existing file.
    try {
      await File(to).delete();
    } on PathNotFoundException {
      // Nothing to replace.
    }
    await File(from).rename(to);
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
