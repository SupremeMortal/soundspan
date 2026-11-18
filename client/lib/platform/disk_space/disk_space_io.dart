// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:disk_space_2/disk_space_2.dart' as plugin;
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/platform/disk_space/disk_space.dart';

/// The [DiskSpace] of the operating system the app runs on.
DiskSpace createDiskSpace() => PluginDiskSpace();

/// Asks the `disk_space_2` plugin, which reports mebibytes, for the free
/// space of the nearest existing directory at or above the path.
///
/// macOS is not covered by the plugin and always answers null, as does any
/// platform error.
final class PluginDiskSpace implements DiskSpace {
  /// Creates the seam.
  new();

  static final AppLogger _log = AppLogger.scope('DiskSpace');

  @override
  Future<int?> freeBytes(String path) async {
    if (Platform.isMacOS) return null;
    var directory = Directory(path).absolute;
    while (!directory.existsSync() && directory.parent.path != directory.path) {
      directory = directory.parent;
    }
    try {
      final mebibytes = await plugin.DiskSpace.getFreeDiskSpaceForPath(
        directory.path,
      );
      return mebibytes == null ? null : (mebibytes * 1024 * 1024).floor();
    } on Object catch (error, stackTrace) {
      _log.warning('Free disk space unknown', const {}, error, stackTrace);
      return null;
    }
  }
}
