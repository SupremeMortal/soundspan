// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';
import 'package:soundspan/core/storage/state/tables/download_items.dart';

/// Which collections need which items (doc 07).
///
/// Deleting a collection or an item deletes its membership rows.
@TableIndex(name: 'download_membership_item_key', columns: {#itemKey})
class DownloadMembership extends Table {
  /// The collection's kind.
  TextColumn get kind => text()();

  /// The collection's reference.
  TextColumn get refId => text()();

  /// The item's key.
  TextColumn get itemKey =>
      text().references(DownloadItems, #itemKey, onDelete: KeyAction.cascade)();

  /// The item's order inside the collection.
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {kind, refId, itemKey};

  static const _collectionKey =
      'FOREIGN KEY (kind, ref_id) REFERENCES download_collections (kind, ref_id) '
      'ON DELETE CASCADE';

  @override
  List<String> get customConstraints => [_collectionKey];
}
