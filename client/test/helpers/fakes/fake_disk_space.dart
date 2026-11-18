// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/disk_space/disk_space.dart';

/// A [DiskSpace] whose answer a test sets (doc 11, Test Doubles).
final class FakeDiskSpace implements DiskSpace {
  /// Creates a fake that reports [free] bytes; null means unknown.
  new({this.free});

  /// The bytes reported free, for every path; null means unknown.
  int? free;

  /// Every path asked about, oldest first.
  final List<String> asked = [];

  @override
  Future<int?> freeBytes(String path) async {
    asked.add(path);
    return free;
  }
}
