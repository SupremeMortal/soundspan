// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';

/// A [DatabaseOpener] whose databases live in memory.
///
/// Every [open] is a new, empty `NativeDatabase.memory()`. The targets that
/// were opened, closed and deleted are recorded, in order.
class InMemoryDatabaseOpener implements DatabaseOpener {
  /// The targets opened, one entry per [open].
  final List<DatabaseTarget> opened = [];

  /// The targets whose executor was closed.
  final List<DatabaseTarget> closed = [];

  /// The targets passed to [delete].
  final List<DatabaseTarget> deleted = [];

  @override
  QueryExecutor open(DatabaseTarget target) {
    opened.add(target);
    return NativeDatabase.memory().interceptWith(
      _CloseRecorder(() => closed.add(target)),
    );
  }

  @override
  Future<void> delete(DatabaseTarget target) async => deleted.add(target);
}

class _CloseRecorder extends QueryInterceptor {
  new(this.onClose);

  final void Function() onClose;

  @override
  Future<void> close(QueryExecutor inner) async {
    await inner.close();
    onClose();
  }
}
