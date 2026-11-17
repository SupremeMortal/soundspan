// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:soundspan/platform/media_files/media_files.dart';

/// A [MediaFiles] over the real file system that records every delete and
/// can be told to fail (doc 11, Test Doubles).
final class FakeMediaFiles implements MediaFiles {
  /// Every path passed to [delete], oldest first.
  final List<String> deleted = [];

  /// When set, every [delete] throws it after recording the path, as
  /// Windows does for a file another process holds open.
  Exception? failWith;

  /// When set, every [replace] throws it.
  Exception? replaceFailsWith;

  @override
  Future<int?> length(String path) async {
    final file = File(path);
    return file.existsSync() ? file.lengthSync() : null;
  }

  @override
  Future<void> replace(String from, String to) async {
    final failure = replaceFailsWith;
    if (failure != null) throw failure;
    final target = File(to);
    if (target.existsSync()) target.deleteSync();
    File(from).renameSync(to);
  }

  @override
  Future<void> delete(String path) async {
    deleted.add(path);
    final failure = failWith;
    if (failure != null) throw failure;
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }
}
