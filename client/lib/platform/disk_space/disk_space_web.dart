// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/disk_space/disk_space.dart';

/// The [DiskSpace] of a browser, which has no downloads: always unknown.
DiskSpace createDiskSpace() => const UnknownDiskSpace();

/// A [DiskSpace] that never knows the answer.
final class UnknownDiskSpace implements DiskSpace {
  /// Creates the seam.
  const new();

  @override
  Future<int?> freeBytes(String path) async => null;
}
