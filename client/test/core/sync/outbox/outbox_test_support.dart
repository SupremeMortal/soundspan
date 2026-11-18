// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:drift/native.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/outbox_store.dart';
import 'package:soundspan/core/sync/outbox/outbox_worker.dart';
import 'package:soundspan/core/sync/outbox/temp_id_rewriter.dart';

import '../../../helpers/fake_clock.dart';
import '../../../helpers/fake_reachability.dart';

/// What a [ScriptedHandler] does for one send: answer a value, or throw.
typedef SendScript = FutureOr<Object?> Function(OutboxOp op);

/// A handler that records every call and answers from a script.
class ScriptedHandler implements OutboxHandler<OutboxOp> {
  /// Answers null for every op unless [script] says otherwise.
  new([SendScript? script]) : script = script ?? ((_) => null);

  /// What [send] does; replaceable during a test.
  SendScript script;

  /// Ops passed to [send], in order.
  final List<OutboxOp> sent = [];

  /// Ops and responses passed to [onSuccess], in order.
  final List<(OutboxOp, Object?)> succeeded = [];

  /// Ops and reasons passed to [onDropped], in order.
  final List<(OutboxOp, OutboxDropReason)> dropped = [];

  /// Called inside [onSuccess], before it records the op.
  Future<void> Function(OutboxOp op, Object? response)? onSuccessHook;

  @override
  Future<Object?> send(OutboxOp op) async {
    sent.add(op);
    return await script(op);
  }

  @override
  Future<void> onSuccess(OutboxOp op, Object? response) async {
    await onSuccessHook?.call(op, response);
    succeeded.add((op, response));
  }

  @override
  Future<void> onDropped(OutboxOp op, OutboxDropReason reason) async {
    dropped.add((op, reason));
  }
}

/// A periodic timer that fires only when a test calls [fire].
class ManualTimer implements Timer {
  new(this.period, this._callback);

  /// The period the worker asked for.
  final Duration period;
  final void Function(Timer timer) _callback;
  bool _active = true;
  int _ticks = 0;

  /// Runs the callback once, as one period elapsing would.
  void fire() {
    if (!_active) return;
    _ticks++;
    _callback(this);
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => _ticks;
}

/// A worker over in-memory databases with every op type routed to one
/// [ScriptedHandler] (except types listed in `unhandled`).
class WorkerRig {
  new({Set<String> unhandled = const {}})
    : state = StateDatabase(NativeDatabase.memory()),
      cache = CacheDatabase(NativeDatabase.memory()),
      clock = FakeClock(),
      reachability = FakeReachability(),
      handler = ScriptedHandler() {
    store = OutboxStore(state, clock);
    rewriter = TempIdRewriter(state, () async => cache);
    worker = OutboxWorker(
      store,
      OutboxHandlerRegistry([
        for (final type in _allTypes)
          if (!unhandled.contains(type)) (opType: type, handler: handler),
      ]),
      reachability,
      clock,
      AppLogger.scope('OutboxTest'),
      rewriter: rewriter,
      periodicTimer: (period, callback) {
        final timer = ManualTimer(period, callback);
        timers.add(timer);
        return timer;
      },
    );
    notices = [];
    resolved = [];
    worker.notices.listen(notices.add);
    worker.resolved.listen(resolved.add);
  }

  static const List<String> _allTypes = [
    PreferenceOp.type,
    AlbumPreferenceOp.type,
    PlayOp.type,
    PlaylistCreateOp.type,
    PlaylistRenameOp.type,
    PlaylistDeleteOp.type,
    PlaylistAddOp.type,
    PlaylistRemoveOp.type,
    PlaylistReorderOp.type,
    EpisodeProgressOp.type,
    OfflineCompleteOp.type,
    OfflineDeleteOp.type,
  ];

  final StateDatabase state;
  final CacheDatabase cache;
  final FakeClock clock;
  final FakeReachability reachability;
  final ScriptedHandler handler;
  late final OutboxStore store;
  late final TempIdRewriter rewriter;
  late final OutboxWorker worker;
  final List<ManualTimer> timers = [];
  late final List<OutboxNotice> notices;
  late final List<TempIdResolved> resolved;

  /// The timer that is still active, if any.
  ManualTimer? get activeTimer {
    for (final timer in timers) {
      if (timer.isActive) return timer;
    }
    return null;
  }

  /// Stores [op] without triggering a pass.
  Future<int?> put(OutboxOp op) => store.enqueue(op);

  /// Triggers a pass and waits for it and for stream deliveries.
  Future<void> pass() async {
    worker.trigger();
    await settle();
  }

  /// Waits for the current pass and pending stream events.
  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await worker.idle;
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// The pending ops.
  Future<List<OutboxEntry>> pending() => store.pending();

  Future<void> close() async {
    await worker.dispose();
    await state.close();
    await cache.close();
  }
}

/// A track preference op for [id].
PreferenceOp pref(String id) => PreferenceOp(
  playbackId: id,
  signal: PreferenceSignal.thumbsUp,
  metadata: const {
    'title': 'Song',
    'artist': 'Artist',
    'album': 'Album',
    'durationSec': 180,
  },
);
