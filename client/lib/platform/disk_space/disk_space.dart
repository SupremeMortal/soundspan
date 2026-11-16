// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The disk-space seam: how many bytes a volume has free (doc 02, Platform
/// Seams; doc 07, Storage Accounting and Quota).
///
/// Native targets ask the `disk_space_2` plugin, which covers Android, iOS,
/// Windows and Linux. On macOS, on web and whenever the platform cannot
/// say, the answer is null: "unknown", and the download scheduler then
/// skips its free-space check.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/platform/disk_space/disk_space_web.dart'
    if (dart.library.io) 'package:soundspan/platform/disk_space/disk_space_io.dart';

export 'disk_space_web.dart'
    if (dart.library.io) 'disk_space_io.dart'
    show createDiskSpace;

/// Reports the free space of the volume that holds a path.
abstract interface class DiskSpace {
  /// The bytes free on the volume that holds [path], or null when unknown.
  Future<int?> freeBytes(String path);
}

/// The process-wide [DiskSpace] of the platform; tests override it.
final Provider<DiskSpace> diskSpaceProvider = Provider<DiskSpace>(
  (ref) => createDiskSpace(),
);
