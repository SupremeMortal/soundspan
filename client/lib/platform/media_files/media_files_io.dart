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

  @override
  Future<void> deleteTree(String path) async {
    final directory = Directory(path);
    if (!directory.existsSync()) return;
    (Object, StackTrace)? failure;
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is Directory) continue;
      try {
        await entity.delete();
      } on PathNotFoundException {
        // Already gone.
      } on FileSystemException catch (error, stackTrace) {
        failure ??= (error, stackTrace);
      }
    }
    if (failure case (final error, final stackTrace)) {
      Error.throwWithStackTrace(error, stackTrace);
    }
    try {
      await directory.delete(recursive: true);
    } on PathNotFoundException {
      // Already gone.
    }
  }
}
