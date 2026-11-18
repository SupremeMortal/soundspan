// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';
import 'dart:isolate';

import 'package:soundspan/platform/file_sizes/file_sizes.dart';

/// The native [FileSizes].
FileSizes createFileSizes() => const IoFileSizes();

/// [FileSizes] over `dart:io`, each call on a background isolate.
final class IoFileSizes implements FileSizes {
  /// Creates the seam.
  const new();

  @override
  Future<int> directoryBytes(String path) =>
      Isolate.run(() => _directoryBytes(path));

  @override
  Future<int> filesBytes(List<String> paths) => Isolate.run(() {
    var total = 0;
    for (final path in paths) {
      total += _fileBytes(File(path));
    }
    return total;
  });

  @override
  Future<void> clearDirectory(String path) =>
      Isolate.run(() => _clearDirectory(path));
}

int _directoryBytes(String path) {
  final directory = Directory(path);
  if (!directory.existsSync()) return 0;
  var total = 0;
  try {
    for (final entity in directory.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) total += _fileBytes(entity);
    }
  } on FileSystemException {
    // The directory changed while it was listed; what was counted stands.
  }
  return total;
}

int _fileBytes(File file) {
  try {
    return file.lengthSync();
  } on FileSystemException {
    return 0;
  }
}

void _clearDirectory(String path) {
  final directory = Directory(path);
  if (!directory.existsSync()) return;
  for (final entity in directory.listSync(followLinks: false)) {
    try {
      entity.deleteSync(recursive: true);
    } on FileSystemException {
      // A file another process holds open (Windows) stays until the next
      // start-up scan.
    }
  }
}
