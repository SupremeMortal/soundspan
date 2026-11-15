// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/outbox_store.dart';
import 'package:soundspan/core/sync/outbox/outbox_worker.dart';
import 'package:soundspan/core/sync/outbox/temp_id_rewriter.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/providers/cache.dart';

export 'package:soundspan/core/sync/outbox/outbox_worker.dart'
    show OutboxConflict, OutboxItemsGone, OutboxNotice;
export 'package:soundspan/core/sync/outbox/temp_id_rewriter.dart'
    show TempIdResolved;

final AppLogger _log = AppLogger.scope('Outbox');

/// The profile's outbox (doc 07, Outbox): features enqueue writes here and
/// read the pending ops back for their optimistic overlays.
class Outbox {
  /// Creates the facade over [_store] and [_worker].
  new(this._store, this._worker);

  final OutboxStore _store;
  final OutboxWorker _worker;

  /// Stores [op], coalescing it with the pending ops, and triggers a pass.
  /// Answers the stored row's `seq`, or null when [op] cancelled a pending
  /// op instead.
  Future<int?> enqueue(OutboxOp op) async {
    final seq = await _store.enqueue(op);
    _worker.trigger();
    return seq;
  }

  /// The pending ops in `seq` order, limited to [opTypes] when given, again
  /// on every change.
  Stream<List<OutboxEntry>> watchPending({Set<String>? opTypes}) =>
      _store.watchPending(opTypes: opTypes);

  /// The number of pending ops, again on every change.
  Stream<int> watchCount() => _store.watchCount();

  /// Notices for the user: items gone and conflicts.
  Stream<OutboxNotice> get notices => _worker.notices;

  /// Every temporary playlist id the server replaced.
  Stream<TempIdResolved> get resolved => _worker.resolved;

  /// The number of pending ops, kept by the worker once it has started;
  /// null before. The UI reads this instead of opening its own query.
  ValueListenable<int?> get pendingCount => _worker.pendingCount;

  /// Starts delivering (doc 02, Bootstrap Sequence, step 8).
  Future<void> start() => _worker.start();
}

/// The profile's [Outbox]. Its worker stops when the profile scope ends.
final Provider<Outbox> outboxProvider = Provider<Outbox>(
  (ref) {
    final worker = OutboxWorker(
      ref.watch(outboxStoreProvider),
      ref.watch(outboxHandlerRegistryProvider),
      ref.watch(reachabilityProvider),
      ref.watch(clockProvider),
      _log,
      rewriter: TempIdRewriter(
        ref.watch(stateDatabaseProvider),
        () => ref.read(cacheDatabaseProvider.future),
      ),
    );
    ref.watch(profileDisposerProvider).register(worker.dispose);
    ref.onDispose(() => unawaited(worker.dispose()));
    return Outbox(ref.watch(outboxStoreProvider), worker);
  },
  dependencies: [
    outboxStoreProvider,
    outboxHandlerRegistryProvider,
    stateDatabaseProvider,
    cacheDatabaseProvider,
    profileDisposerProvider,
  ],
);

/// The post-first-frame task of the outbox (doc 02, Bootstrap Sequence,
/// step 8): starts the worker of every profile container the
/// [ProfileRuntime] under `root` activates, once per container.
Future<void> startOutbox(ProviderContainer root) async {
  final runtime = root.read(profileRuntimeProvider);
  final started = Expando<bool>();
  void onState() {
    final container = runtime.container;
    if (runtime.state.value is! ProfileRuntimeActive || container == null) {
      return;
    }
    if (started[container] ?? false) return;
    started[container] = true;
    unawaited(
      container
          .read(outboxProvider)
          .start()
          .catchError(
            (Object error, StackTrace stackTrace) => _log.severe(
              'Outbox did not start',
              const {},
              error,
              stackTrace,
            ),
          ),
    );
  }

  runtime.state.addListener(onState);
  onState();
}
