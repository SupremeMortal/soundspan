// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';
import 'package:soundspan/core/storage/cache/entity_kind.dart';
import 'package:soundspan/core/storage/cache/tables/lists.dart';

/// The ordered entries of the cached lists (doc 05).
///
/// Deleting a list deletes its entries.
@DataClassName('CacheListEntry')
@TableIndex(name: 'list_entries_entity', columns: {#entityKind, #entityKey})
class ListEntries extends Table {
  /// The list the entry belongs to.
  TextColumn get listKey =>
      text().references(Lists, #listKey, onDelete: KeyAction.cascade)();

  /// The entry's position in the list.
  IntColumn get position => integer()();

  /// The kind of entity the entry points at.
  TextColumn get entityKind => textEnum<CacheEntityKind>()();

  /// The entity's key: `tracks.key` or the other tables' `id`.
  TextColumn get entityKey => text()();

  @override
  Set<Column> get primaryKey => {listKey, position};
}
