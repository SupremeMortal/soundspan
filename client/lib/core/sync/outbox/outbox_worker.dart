// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show ValueListenable, ValueNotifier, immutable;
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/outbox_store.dart';
import 'package:soundspan/core/sync/outbox/temp_id_rewriter.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/playlist.dart';
import 'package:soundspan_api/soundspan_api.dart' hide PlaylistSummary;

/// Something the user should be told about the outbox, once per pass.
@immutable
sealed class OutboxNotice {
  const new();
}

/// [count] ops were dropped because their target no longer exists.
final class OutboxItemsGone extends OutboxNotice {
  /// Creates the notice.
  const new(this.count);

  /// How many ops were dropped in the pass.
  final int count;

  @override
  bool operator ==(Object other) =>
      other is OutboxItemsGone && other.count == count;

  @override
  int get hashCode => count.hashCode;

  @override
  String toString() => 'OutboxItemsGone($count)';
}

/// An op was dropped because its entity changed elsewhere.
final class OutboxConflict extends OutboxNotice {
  /// Creates the notice.
  const new();

  @override
  bool operator ==(Object other) => other is OutboxConflict;

  @override
  int get hashCode => (OutboxConflict).hashCode;

  @override
  String toString() => 'OutboxConflict()';
}

/// Creates the timer that triggers a pass every [period].
typedef PeriodicTimerFactory = Timer Function(
  Duration period,
  void Function(Timer timer) callback,
);

/// What a pass does after one op.
enum _Next { proceed, stop }

/// Delivers the profile's outbox, one op at a time in `seq` order (doc 07,
/// Worker).
///
/// A pass runs after [trigger] (every enqueue), when [ReachabilityController]
/// becomes online, and every [period] while ops are pending, and never while
/// not online. Passes never overlap.
class OutboxWorker {
  /// Creates the worker. The registry holds a handler per `opType`, the
  /// rewriter resolves temporary playlist ids and [periodicTimer] defaults
  /// to [Timer.periodic].
  new(
    this._store,
    this._registry,
    this._reachability,
    this._clock,
    this._log, {
    required this._rewriter,
    PeriodicTimerFactory? periodicTimer,
  }) : _periodicTimer = periodicTimer ?? Timer.periodic;

  /// How often a pass runs while ops are pending.
  static const Duration period = Duration(seconds: 60);

  /// The first retry delay after a transient failure.
  static const Duration baseBackoff = Duration(seconds: 5);

  /// The longest retry delay.
  static const Duration maxBackoff = Duration(minutes: 15);

  /// Plays older than this are dropped unsent.
  static const Duration maxPlayAge = Duration(days: 14);

  final OutboxStore _store;
  final OutboxHandlerRegistry _registry;
  final ReachabilityController _reachability;
  final Clock _clock;
  final AppLogger _log;
  final TempIdRewriter _rewriter;
  final PeriodicTimerFactory _periodicTimer;

  final StreamController<OutboxNotice> _notices =
      StreamController<OutboxNotice>.broadcast();
  final StreamController<TempIdResolved> _resolved =
      StreamController<TempIdResolved>.broadcast();

  final ValueNotifier<int?> _pendingCount = ValueNotifier<int?>(null);
  StreamSubscription<Reachability>? _reachabilitySub;
  StreamSubscription<int>? _countSub;
  Timer? _timer;
  Future<void>? _pass;
  bool _triggeredDuringPass = false;
  bool _started = false;
  bool _disposed = false;

  /// The notices to show, at most one of each kind per pass.
  Stream<OutboxNotice> get notices => _notices.stream;

  /// Every temporary playlist id the server replaced.
  Stream<TempIdResolved> get resolved => _resolved.stream;

  /// The number of pending ops once [start] has read it; null before.
  ValueListenable<int?> get pendingCount => _pendingCount;

  /// Whether the periodic timer is running.
  bool get hasTimer => _timer != null;

  /// Removes orphaned temporary cache rows, starts listening to
  /// reachability and the pending count, and runs a first pass. Calling it
  /// again does nothing.
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    try {
      await _rewriter.removeOrphans();
    } on Object catch (error, stackTrace) {
      _log.warning('Orphan cleanup failed', const {}, error, stackTrace);
    }
    if (_disposed) return;
    _reachabilitySub = _reachability.changes.listen((state) {
      if (state == Reachability.online) trigger();
    });
    _countSub = _store.watchCount().listen(_onCount);
    trigger();
  }

  /// Starts a pass unless one is running or the server is not reachable.
  /// A trigger during a pass that drains the store runs one more pass, so
  /// an op enqueued at the end of a pass is not left waiting.
  void trigger() {
    if (_disposed || !_reachability.isOnline) return;
    if (_pass != null) {
      _triggeredDuringPass = true;
      return;
    }
    _pass = _runPasses().whenComplete(() => _pass = null);
  }

  /// Triggers a pass and completes when it has finished; while not online
  /// it completes at once.
  Future<void> flush() {
    trigger();
    return idle;
  }

  /// Completes when the current pass, if any, has finished.
  Future<void> get idle => _pass ?? Future<void>.value();

  /// Cancels the timer and subscriptions and closes the streams.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    await _reachabilitySub?.cancel();
    await _countSub?.cancel();
    await idle;
    await _notices.close();
    await _resolved.close();
  }

  void _onCount(int count) {
    _pendingCount.value = count;
    if (count > 0) {
      _timer ??= _periodicTimer(period, (_) => trigger());
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> _runPasses() async {
    while (true) {
      _triggeredDuringPass = false;
      final drained = await _runPass();
      if (!drained || !_triggeredDuringPass || _disposed) return;
      if (!_reachability.isOnline) return;
    }
  }

  /// One pass; answers whether it ended because the store was empty.
  Future<bool> _runPass() async {
    var gone = 0;
    var conflicts = 0;
    try {
      while (!_disposed && _reachability.isOnline) {
        final entry = await _store.head();
        if (entry == null) return true;
        final next = entry.nextAttemptAt;
        if (next != null && next.isAfter(_clock.now())) return false;
        final result = await _deliver(entry);
        switch (result) {
          case _Outcome(:final next, :final notFound, :final conflict):
            if (notFound) gone++;
            if (conflict) conflicts++;
            if (next == _Next.stop) return false;
        }
      }
      return false;
    } on Object catch (error, stackTrace) {
      _log.severe('Outbox pass failed', const {}, error, stackTrace);
      return false;
    } finally {
      if (!_disposed) {
        if (gone > 0) _notices.add(OutboxItemsGone(gone));
        if (conflicts > 0) _notices.add(const OutboxConflict());
      }
    }
  }

  Future<_Outcome> _deliver(OutboxEntry entry) async {
    final op = entry.op;
    final fields = {'seq': entry.seq, 'opType': op.opType};
    if (op is PlayOp &&
        op.playedAt.isBefore(_clock.now().subtract(maxPlayAge))) {
      await _store.delete(entry.seq);
      _log.info('Play older than 14 days dropped unsent', fields);
      return const _Outcome(_Next.proceed);
    }
    final handler = _registry[op.opType];
    if (handler == null) {
      _log.warning('No outbox handler', fields);
      return const _Outcome(_Next.stop);
    }

    final Object? response;
    try {
      response = await handler.send(op);
    } on ApiException catch (error) {
      return await _onFailure(entry, handler, error, fields);
    } on Object catch (error, stackTrace) {
      _log.severe('Outbox send failed', fields, error, stackTrace);
      await _backOff(entry, error);
      return const _Outcome(_Next.stop);
    }
    await _onSent(entry, handler, response, fields);
    return const _Outcome(_Next.proceed);
  }

  Future<void> _onSent(
    OutboxEntry entry,
    OutboxHandler<OutboxOp> handler,
    Object? response,
    Map<String, Object?> fields,
  ) async {
    final op = entry.op;
    if (op is PlaylistCreateOp && response is PlaylistSummary) {
      await _rewriter.resolve(
        createSeq: entry.seq,
        tempId: op.tempId,
        realId: response.id,
      );
      if (!_disposed) _resolved.add(TempIdResolved(op.tempId, response.id));
      await _guard('onSuccess', fields, () => handler.onSuccess(op, response));
      return;
    }
    // The cache is updated before the op leaves the pending list, so an
    // overlay never shows the value from before the write.
    await _guard('onSuccess', fields, () => handler.onSuccess(op, response));
    await _store.delete(entry.seq);
  }

  Future<_Outcome> _onFailure(
    OutboxEntry entry,
    OutboxHandler<OutboxOp> handler,
    ApiException error,
    Map<String, Object?> fields,
  ) async {
    switch (error) {
      case Offline() || ServerError() || Upstream() || NotSoundspan():
        await _backOff(entry, error);
        return const _Outcome(_Next.stop);
      case RateLimited(:final retryAfter):
        await _store.recordFailure(
          entry.seq,
          nextAttemptAt: _clock.now().add(retryAfter),
          lastError: '$error',
        );
        return const _Outcome(_Next.stop);
      case Unauthenticated():
        return const _Outcome(_Next.stop);
      case NotFound() || FeatureDisabled():
        await _drop(entry, handler, OutboxDropReason.notFound, fields);
        return const _Outcome(_Next.proceed, notFound: true);
      case Conflict():
        await _drop(entry, handler, OutboxDropReason.conflict, fields);
        return const _Outcome(_Next.proceed, conflict: true);
      case InvalidRequest() || Forbidden():
        _log.severe('Outbox op rejected as invalid', {
          ...fields,
          'status': error.status,
          'code': error.code,
        });
        await _drop(entry, handler, OutboxDropReason.invalid, fields);
        return const _Outcome(_Next.proceed);
      case InvalidResponse() || Unexpected():
        _log.severe('Outbox op answered unexpectedly; treated as sent', {
          ...fields,
          'error': '$error',
        });
        await _onSent(entry, handler, null, fields);
        return const _Outcome(_Next.proceed);
    }
  }

  Future<void> _backOff(OutboxEntry entry, Object error) {
    final factor = math.pow(2, math.min(entry.attempts, 20)).toInt();
    final delay = baseBackoff * factor;
    return _store.recordFailure(
      entry.seq,
      nextAttemptAt: _clock.now().add(delay > maxBackoff ? maxBackoff : delay),
      lastError: '$error',
    );
  }

  Future<void> _drop(
    OutboxEntry entry,
    OutboxHandler<OutboxOp> handler,
    OutboxDropReason reason,
    Map<String, Object?> fields,
  ) async {
    await _store.delete(entry.seq);
    _log.info('Outbox op dropped', {...fields, 'reason': reason.name});
    await _guard(
      'onDropped',
      fields,
      () => handler.onDropped(entry.op, reason),
    );
  }

  Future<void> _guard(
    String what,
    Map<String, Object?> fields,
    Future<void> Function() body,
  ) async {
    try {
      await body();
    } on Object catch (error, stackTrace) {
      _log.severe('Outbox $what failed', fields, error, stackTrace);
    }
  }
}

final class _Outcome {
  const new(this.next, {this.notFound = false, this.conflict = false});

  final _Next next;
  final bool notFound;
  final bool conflict;
}
