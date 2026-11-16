// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/sync/outbox/optimistic_overlay.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/outbox_store.dart';
import 'package:soundspan/shared/domain/cached.dart';
import 'package:soundspan_api/soundspan_api.dart' show NotFound;

import 'outbox_test_support.dart';

final DateTime _fetched = DateTime.utc(2025);

Cached<String> _cached(String value) =>
    Cached(value: value, fetchedAt: _fetched);

/// The latest rename in [ops] wins; the cached value otherwise.
String _applyRenames(String value, List<OutboxEntry> ops) => ops
    .map((e) => e.op)
    .whereType<PlaylistRenameOp>()
    .fold(value, (_, op) => op.name);

void main() {
  late WorkerRig rig;

  setUp(() => rig = WorkerRig());
  tearDown(() => rig.close());

  test('a pending op changes the emitted value', () async {
    final base = StreamController<Cached<String>>();
    final values = <String>[];
    final sub = overlay(
      base.stream,
      rig.store.watchPending(),
      _applyRenames,
    ).listen((c) => values.add(c.value));
    addTearDown(sub.cancel);

    base.add(_cached('Old'));
    await rig.settle();
    expect(values, ['Old']);

    await rig.put(const PlaylistRenameOp(playlistId: 'p', name: 'New'));
    await rig.settle();

    expect(values, ['Old', 'New']);
  });

  test('nothing is emitted until both inputs have emitted', () async {
    final base = StreamController<Cached<String>>();
    final pending = StreamController<List<OutboxEntry>>();
    final values = <String>[];
    final sub = overlay(
      base.stream,
      pending.stream,
      _applyRenames,
    ).listen((c) => values.add(c.value));
    addTearDown(sub.cancel);

    base.add(_cached('Old'));
    await rig.settle();
    expect(values, isEmpty);

    pending.add(const []);
    await rig.settle();
    expect(values, ['Old']);
  });

  test('server confirmation keeps the value with no flicker when onSuccess '
      'wrote the cache', () async {
    final base = StreamController<Cached<String>>.broadcast();
    final values = <String>[];
    final sub = overlay(
      base.stream,
      rig.store.watchPending(),
      _applyRenames,
    ).listen((c) => values.add(c.value));
    addTearDown(sub.cancel);
    base.add(_cached('Old'));
    await rig.put(const PlaylistRenameOp(playlistId: 'p', name: 'New'));
    await rig.settle();
    expect(values.last, 'New');

    rig.handler.onSuccessHook = (_, _) async {
      base.add(_cached('New'));
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    };
    await rig.pass();

    expect(await rig.pending(), isEmpty);
    expect(values.skipWhile((v) => v != 'New'), everyElement('New'));
  });

  test('a dropped op restores the cached value', () async {
    final base = StreamController<Cached<String>>();
    final values = <String>[];
    final sub = overlay(
      base.stream,
      rig.store.watchPending(),
      _applyRenames,
    ).listen((c) => values.add(c.value));
    addTearDown(sub.cancel);
    base.add(_cached('Old'));
    await rig.put(const PlaylistRenameOp(playlistId: 'p', name: 'New'));
    await rig.settle();
    expect(values.last, 'New');

    rig.handler.script = (_) => throw const NotFound(status: 404);
    await rig.pass();

    expect(values.last, 'Old');
  });

  test('with a hold, a confirmed op stays applied until the base catches '
      'up', () async {
    final base = StreamController<Cached<String>>.broadcast();
    final values = <String>[];
    final sub = overlay(
      base.stream,
      rig.store.watchPending(),
      _applyRenames,
      hold: const Duration(seconds: 5),
    ).listen((c) => values.add(c.value));
    addTearDown(sub.cancel);
    base.add(_cached('Old'));
    await rig.put(const PlaylistRenameOp(playlistId: 'p', name: 'New'));
    await rig.settle();
    expect(values.last, 'New');

    // The op is deleted before the slow base shows the written value.
    await rig.pass();
    expect(await rig.pending(), isEmpty);
    expect(values.last, 'New');

    base.add(_cached('New'));
    await rig.settle();
    expect(values.skip(1), everyElement('New'));
  });

  test('with a hold, a dropped op is rolled back once the hold has passed', () {
    fakeAsync((async) {
      final base = StreamController<Cached<String>>();
      final pending = StreamController<List<OutboxEntry>>();
      final values = <String>[];
      overlay(
        base.stream,
        pending.stream,
        _applyRenames,
        hold: const Duration(milliseconds: 250),
      ).listen((c) => values.add(c.value));
      final entry = OutboxEntry(
        seq: 1,
        op: const PlaylistRenameOp(playlistId: 'p', name: 'New'),
        createdAt: DateTime.utc(2025),
        attempts: 0,
      );
      base.add(_cached('Old'));
      pending.add([entry]);
      async.flushMicrotasks();
      expect(values.last, 'New');

      pending.add(const []);
      async
        ..flushMicrotasks()
        ..elapse(const Duration(milliseconds: 200));
      expect(values.last, 'New');

      async.elapse(const Duration(milliseconds: 100));
      expect(values.last, 'Old');
    });
  });

  test('ops apply in seq order', () async {
    final applied = <List<int>>[];
    final base = StreamController<Cached<String>>();
    final pending = StreamController<List<OutboxEntry>>();
    final sub = overlay(base.stream, pending.stream, (value, ops) {
      applied.add([for (final e in ops) e.seq]);
      return value;
    }).listen((_) {});
    addTearDown(sub.cancel);

    OutboxEntry entry(int seq) => OutboxEntry(
      seq: seq,
      op: PlaylistRenameOp(playlistId: 'p', name: '$seq'),
      createdAt: _fetched,
      attempts: 0,
    );
    base.add(_cached('x'));
    pending.add([entry(3), entry(1), entry(2)]);
    await rig.settle();

    expect(applied, [
      [1, 2, 3],
    ]);
  });

  test('the cached metadata passes through', () async {
    final base = StreamController<Cached<String>>();
    final pending = StreamController<List<OutboxEntry>>();
    final emitted = <Cached<String>>[];
    final sub = overlay(
      base.stream,
      pending.stream,
      _applyRenames,
    ).listen(emitted.add);
    addTearDown(sub.cancel);

    base.add(Cached(value: 'x', fetchedAt: _fetched, refreshing: true));
    pending.add(const []);
    await rig.settle();

    expect(
      emitted.single,
      Cached(value: 'x', fetchedAt: _fetched, refreshing: true),
    );
  });
}
