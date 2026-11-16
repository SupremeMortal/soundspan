// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_store.dart';
import 'package:soundspan/core/sync/outbox/outbox_worker.dart';
import 'package:soundspan/core/sync/outbox/temp_id_rewriter.dart';

import 'fake_clock.dart';
import 'fake_reachability.dart';

/// An [Outbox] over [database] that stores ops and never sends them: its
/// server is unreachable and it has no handlers.
Outbox idleOutbox(StateDatabase database) {
  final clock = FakeClock();
  final store = OutboxStore(database, clock);
  return Outbox(
    store,
    OutboxWorker(
      store,
      OutboxHandlerRegistry(const []),
      FakeReachability(initial: Reachability.noNetwork),
      clock,
      AppLogger.scope('IdleOutbox'),
      rewriter: TempIdRewriter(
        database,
        () async => CacheDatabase(NativeDatabase.memory()),
      ),
    ),
  );
}
