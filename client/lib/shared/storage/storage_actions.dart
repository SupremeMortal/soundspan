// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show BaseCacheManager;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/file_sizes/file_sizes.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan/shared/providers/cache.dart';
import 'package:soundspan/shared/providers/images.dart';

/// The destructive actions of `Settings → Storage` for one profile (doc 07,
/// Storage Accounting and Quota and Removing Downloads).
class StorageActions {
  /// Creates the actions of profile [_profileId].
  ///
  /// [_cacheDatabase] answers the open `cache.db`; [_reopenCache] makes the
  /// next reader open it again. Without [_paths] (web) there is no
  /// `media/` directory to sweep.
  new({
    required this._downloads,
    required this._images,
    required this._cacheDatabase,
    required this._opener,
    required this._profileId,
    required this._reopenCache,
    required this._files,
    this._paths,
  });

  final DownloadController Function() _downloads;
  final BaseCacheManager _images;
  final Future<CacheDatabase> Function() _cacheDatabase;
  final DatabaseOpener _opener;
  final String _profileId;
  final void Function() _reopenCache;
  final FileSizes _files;
  final ProfilePaths? _paths;

  /// Empties the image cache and resets `cache.db`: the database is closed,
  /// its file deleted and opened again empty on the next read. `state.db`,
  /// `media/` and `art/` are untouched, so downloads still play and
  /// playback goes on.
  Future<void> clearCache() async {
    await _images.emptyCache();
    final database = await _cacheDatabase();
    await database.close();
    await _opener.delete(CacheDatabaseTarget(_profileId));
    _reopenCache();
  }

  /// Unpins every collection, tracks and episodes, which deletes their
  /// files and tells the server about the tracks, then deletes whatever is
  /// left in `media/`: with no download row left, every file there is an
  /// orphan.
  Future<void> removeAllDownloads() async {
    await _downloads().unpinAll();
    final paths = _paths;
    if (paths != null) await _files.clearDirectory(paths.media);
  }
}

/// The active profile's [StorageActions].
final Provider<StorageActions> storageActionsProvider =
    Provider.autoDispose<StorageActions>(
      (ref) {
        final context = ref.watch(profileContextProvider);
        return StorageActions(
          downloads: () => ref.read(downloadControllerProvider),
          images: ref.watch(imageCacheManagerProvider),
          cacheDatabase: () => ref.read(cacheDatabaseProvider.future),
          opener: ref.watch(databaseOpenerProvider),
          profileId: context.profile.id,
          reopenCache: () => ref.invalidate(cacheDatabaseProvider),
          files: ref.watch(fileSizesProvider),
          paths: context.paths,
        );
      },
      dependencies: [
        profileContextProvider,
        downloadControllerProvider,
        imageCacheManagerProvider,
        cacheDatabaseProvider,
      ],
    );
