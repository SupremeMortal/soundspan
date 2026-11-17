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

  /// Paths whose [delete], alone or inside [deleteTree], throws after
  /// recording the path.
  final Set<String> failingPaths = {};

  /// When set, [deleteTree] waits for it before deleting anything.
  Future<void>? treeGate;

  /// Every directory passed to [deleteTree], oldest first.
  final List<String> deletedTrees = [];

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
    if (failingPaths.contains(path)) {
      throw FileSystemException('file is in use', path);
    }
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }

  @override
  Future<void> deleteTree(String path) async {
    deletedTrees.add(path);
    await treeGate;
    final directory = Directory(path);
    if (!directory.existsSync()) return;
    (Object, StackTrace)? failure;
    for (final file in directory.listSync(recursive: true).whereType<File>()) {
      try {
        await delete(file.path);
      } on Object catch (error, stackTrace) {
        failure ??= (error, stackTrace);
      }
    }
    if (failure case (final error, final stackTrace)) {
      Error.throwWithStackTrace(error, stackTrace);
    }
    directory.deleteSync(recursive: true);
  }
}
