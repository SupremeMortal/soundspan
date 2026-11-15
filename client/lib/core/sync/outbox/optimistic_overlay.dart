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
/// [base] ends.
Stream<Cached<T>> overlay<T>(
  Stream<Cached<T>> base,
  Stream<List<OutboxEntry>> pending,
  T Function(T value, List<OutboxEntry> ops) apply,
) {
  late StreamController<Cached<T>> controller;
  StreamSubscription<Cached<T>>? baseSub;
  StreamSubscription<List<OutboxEntry>>? pendingSub;
  Cached<T>? latest;
  List<OutboxEntry>? ops;

  void emit() {
    final cached = latest;
    final current = ops;
    if (cached == null || current == null) return;
    final sorted = [...current]..sort((a, b) => a.seq.compareTo(b.seq));
    controller.add(
      Cached<T>(
        value: sorted.isEmpty ? cached.value : apply(cached.value, sorted),
        fetchedAt: cached.fetchedAt,
        refreshing: cached.refreshing,
        refreshError: cached.refreshError,
      ),
    );
  }

  controller = StreamController<Cached<T>>(
    onListen: () {
      baseSub = base.listen(
        (value) {
          latest = value;
          emit();
        },
        onError: controller.addError,
        onDone: () => unawaited(controller.close()),
      );
      pendingSub = pending.listen((value) {
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
      await baseSub?.cancel();
      await pendingSub?.cancel();
    },
  );
  return controller.stream;
}
