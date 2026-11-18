// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/core/sync/outbox/outbox_store.dart';
import 'package:soundspan/shared/domain/cached.dart';

/// [base] with the [pending] ops applied to its value by [apply] (doc 07,
/// Worker: optimistic state).
///
/// Emits once both inputs have emitted, then again whenever either does.
/// [apply] receives the ops in `seq` order and must be pure. An op that is
/// dropped leaves [pending], so the next value is the cached one: that is
/// the rollback. Errors of either input are forwarded; the stream ends when
/// [base] ends. [hold] is described at [overlayEach].
Stream<Cached<T>> overlay<T>(
  Stream<Cached<T>> base,
  Stream<List<OutboxEntry>> pending,
  T Function(T value, List<OutboxEntry> ops) apply, {
  Duration? hold,
}) => overlayEach<Cached<T>>(
  base,
  pending,
  (cached, ops) => Cached<T>(
    value: apply(cached.value, ops),
    fetchedAt: cached.fetchedAt,
    refreshing: cached.refreshing,
    refreshError: cached.refreshError,
  ),
  hold: hold,
);

/// [base] with the [pending] ops applied to each of its values by [apply]:
/// the stream [overlay] is made of, for values that are not [Cached], such
/// as the snapshots of a paged list.
///
/// Emits once both inputs have emitted, then again whenever either does.
/// [apply] receives the ops in `seq` order, is not called while none is
/// pending, and must be pure. Errors of either input are forwarded; the
/// stream ends when [base] ends.
///
/// With [hold], an op that leaves [pending] is still applied until [base]
/// emits again or [hold] has passed, whichever is first. A base that
/// re-reads the cache more slowly than [pending] reports the op gone (a
/// list's entity rows, written by `onSuccess` just before the op is
/// deleted) then never shows the value from before the write; a dropped op
/// is rolled back once [hold] has passed.
Stream<S> overlayEach<S>(
  Stream<S> base,
  Stream<List<OutboxEntry>> pending,
  S Function(S value, List<OutboxEntry> ops) apply, {
  Duration? hold,
}) {
  late StreamController<S> controller;
  StreamSubscription<S>? baseSub;
  StreamSubscription<List<OutboxEntry>>? pendingSub;
  S? latest;
  var hasLatest = false;
  List<OutboxEntry>? ops;
  var retired = const <OutboxEntry>[];
  Timer? retireTimer;

  void emit() {
    final current = ops;
    if (!hasLatest || current == null) return;
    final value = latest as S;
    final sorted = [...current, ...retired]
      ..sort((a, b) => a.seq.compareTo(b.seq));
    controller.add(sorted.isEmpty ? value : apply(value, sorted));
  }

  void release() {
    retireTimer?.cancel();
    retireTimer = null;
    retired = const [];
  }

  void retire(List<OutboxEntry> next) {
    final previous = ops;
    if (hold == null || previous == null) return;
    final kept = {for (final entry in next) entry.seq};
    final removed = [
      for (final entry in previous)
        if (!kept.contains(entry.seq)) entry,
    ];
    if (removed.isEmpty) return;
    retired = [...retired, ...removed];
    retireTimer?.cancel();
    retireTimer = Timer(hold, () {
      release();
      emit();
    });
  }

  controller = StreamController<S>(
    onListen: () {
      baseSub = base.listen(
        (value) {
          release();
          latest = value;
          hasLatest = true;
          emit();
        },
        onError: controller.addError,
        onDone: () => unawaited(controller.close()),
      );
      pendingSub = pending.listen((value) {
        retire(value);
        ops = value;
        emit();
      }, onError: controller.addError);
    },
    onPause: () {
      baseSub?.pause();
      pendingSub?.pause();
    },
    onResume: () {
      baseSub?.resume();
      pendingSub?.resume();
    },
    onCancel: () async {
      release();
      await baseSub?.cancel();
      await pendingSub?.cancel();
    },
  );
  return controller.stream;
}
