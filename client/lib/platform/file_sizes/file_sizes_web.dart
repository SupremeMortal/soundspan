// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/file_sizes/file_sizes.dart';

/// The web's [FileSizes]: there are no files.
FileSizes createFileSizes() => const NoFileSizes();

/// [FileSizes] without files: every size is zero and nothing is deleted.
final class NoFileSizes implements FileSizes {
  /// Creates the seam.
  const new();

  @override
  Future<int> directoryBytes(String path) async => 0;

  @override
  Future<int> filesBytes(List<String> paths) async => 0;

  @override
  Future<void> clearDirectory(String path) async {}
}
