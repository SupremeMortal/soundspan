// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/platform/disk_space/disk_space.dart';
import 'package:soundspan/platform/file_sizes/file_sizes.dart';
import 'package:soundspan/platform/paths/paths.dart';

/// What one profile holds on this device (`Settings → Storage`, doc 07,
/// Storage Accounting and Quota).
@immutable
final class StorageUsage {
  /// Creates the figures.
  const new({
    required this.downloadsBytes,
    required this.downloadCount,
    required this.imageCacheBytes,
    required this.databaseBytes,
    this.freeDiskBytes,
  });

  /// No files: every figure zero and free space unknown (web).
  static const StorageUsage none = StorageUsage(
    downloadsBytes: 0,
    downloadCount: 0,
    imageCacheBytes: 0,
    databaseBytes: 0,
  );

  /// The size of the completed downloads.
  final int downloadsBytes;

  /// The number of completed downloads.
  final int downloadCount;

  /// The size of the profile's image cache.
  final int imageCacheBytes;

  /// The size of `state.db` and `cache.db` with their `-wal` and `-shm`
  /// files.
  final int databaseBytes;

  /// Free space on the disk that holds the profile, or null when unknown.
  final int? freeDiskBytes;

  /// Downloads, images and databases together.
  int get totalBytes => downloadsBytes + imageCacheBytes + databaseBytes;

  @override
  bool operator ==(Object other) =>
      other is StorageUsage &&
      other.downloadsBytes == downloadsBytes &&
      other.downloadCount == downloadCount &&
      other.imageCacheBytes == imageCacheBytes &&
      other.databaseBytes == databaseBytes &&
      other.freeDiskBytes == freeDiskBytes;

  @override
  int get hashCode => Object.hash(
    downloadsBytes,
    downloadCount,
    imageCacheBytes,
    databaseBytes,
    freeDiskBytes,
  );

  @override
  String toString() =>
      'StorageUsage(downloads: $downloadsBytes in $downloadCount, '
      'images: $imageCacheBytes, databases: $databaseBytes, '
      'free: $freeDiskBytes)';
}

/// Computes the [StorageUsage] of one profile.
///
/// Downloads come from the [DownloadStore] rows, not from the files; the
/// image cache and the databases are measured on disk, off the UI isolate.
/// Without [_paths] (web) there are no files and every figure is zero.
final class StorageUsageCalculator {
  /// Creates the calculator of the profile at [_paths].
  new({
    required this._downloads,
    required this._files,
    required this._diskSpace,
    this._paths,
  });

  final DownloadStore _downloads;
  final FileSizes _files;
  final DiskSpace _diskSpace;
  final ProfilePaths? _paths;

  /// The profile's usage now.
  Future<StorageUsage> compute() async {
    final paths = _paths;
    if (paths == null) return StorageUsage.none;
    final downloads = await _downloads.completedTotals();
    final images = await _files.directoryBytes(paths.images);
    final databases = await _files.filesBytes([
      for (final db in [paths.stateDb, paths.cacheDb])
        for (final suffix in const ['', '-wal', '-shm']) '$db$suffix',
    ]);
    return StorageUsage(
      downloadsBytes: downloads.bytes,
      downloadCount: downloads.count,
      imageCacheBytes: images,
      databaseBytes: databases,
      freeDiskBytes: await _diskSpace.freeBytes(paths.supportRoot),
    );
  }
}

/// The active profile's [StorageUsage], computed when first read; the
/// storage screen invalidates it after an action changes it.
final FutureProvider<StorageUsage> storageUsageProvider =
    FutureProvider.autoDispose<StorageUsage>(
      (ref) => StorageUsageCalculator(
        downloads: ref.watch(downloadStoreProvider),
        files: ref.watch(fileSizesProvider),
        diskSpace: ref.watch(diskSpaceProvider),
        paths: ref.watch(profileContextProvider).paths,
      ).compute(),
      dependencies: [downloadStoreProvider, profileContextProvider],
    );
