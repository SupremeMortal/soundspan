// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/media_files/media_files.dart';

/// The [MediaFiles] of a browser, which has no files.
MediaFiles createMediaFiles() => const NoMediaFiles();

/// A [MediaFiles] with nothing to delete.
final class NoMediaFiles implements MediaFiles {
  /// Creates the seam.
  const new();

  @override
  Future<void> delete(String path) async {}
}
