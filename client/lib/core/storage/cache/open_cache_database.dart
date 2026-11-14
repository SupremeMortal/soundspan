// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';

/// Opens the `cache.db` of [profileId] through [opener] (doc 05,
/// Migrations).
///
/// The database is opened by one trivial query. If opening or that query
/// throws, the database is closed, its file is deleted and the open is
/// retried once; a second failure propagates.
Future<CacheDatabase> openCacheDatabase(
  DatabaseOpener opener,
  String profileId,
) async {
  final target = CacheDatabaseTarget(profileId);
  try {
    return await _openOnce(opener, target);
  } on Object {
    await opener.delete(target);
    return await _openOnce(opener, target);
  }
}

Future<CacheDatabase> _openOnce(
  DatabaseOpener opener,
  CacheDatabaseTarget target,
) async {
  final db = CacheDatabase(opener.open(target));
  try {
    await db.customSelect('SELECT 1').get();
    return db;
  } on Object {
    try {
      await db.close();
    } on Object {
      // The file is deleted next; a failed close changes nothing.
    }
    rethrow;
  }
}
