// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan_api/soundspan_api.dart' hide PreferenceSignal;

import '../../logging/recording_sink.dart';
import 'outbox_test_support.dart';

PlayOp _play(String session, DateTime playedAt) => PlayOp(
  sessionId: session,
  playbackId: 'pb:$session',
  metadata: const {'title': 'Song'},
  playedAt: playedAt,
  listenedMs: 30000,
);

void main() {
  late WorkerRig rig;

  setUp(() => rig = WorkerRig());
  tearDown(() => rig.close());

  Future<List<String>> pendingKeys() async => [
    for (final e in await rig.pending()) e.op.entityKey,
  ];

  group('outcomes', () {
    test('2xx deletes the op and calls onSuccess with the response', () async {
      rig.handler.script = (_) => 'answer';
      await rig.put(pref('a'));

      await rig.pass();

      expect(await rig.pending(), isEmpty);
      expect(rig.handler.succeeded, [(pref('a'), 'answer')]);
    });

    test('onSuccess runs while the op is still pending', () async {
      int? pendingDuringSuccess;
      rig.handler.onSuccessHook = (_, _) async =>
          pendingDuringSuccess = (await rig.pending()).length;
      await rig.put(pref('a'));

      await rig.pass();

      expect(pendingDuringSuccess, 1);
      expect(await rig.pending(), isEmpty);
    });

    for (final (name, error) in <(String, ApiException)>[
      ('Offline', const Offline()),
      ('5xx', const ServerError(status: 500)),
      ('Upstream', const Upstream(status: 502, code: 'UPSTREAM_FAILED')),
    ]) {
      test('$name stops the pass and backs off 5 s, 10 s, 20 s … capped at '
          '15 min', () async {
        rig.handler.script = (_) => throw error;
        await rig.put(pref('a'));
        await rig.put(pref('b'));

        final delays = <Duration>[];
        for (var i = 0; i < 10; i++) {
          final start = rig.clock.now();
          await rig.pass();
          final head = (await rig.pending()).first;
          delays.add(head.nextAttemptAt!.difference(start));
          expect(head.attempts, i + 1);
          rig.clock.set(head.nextAttemptAt!);
        }

        expect(delays, [
          for (final s in [5, 10, 20, 40, 80, 160, 320, 640])
            Duration(seconds: s),
          const Duration(minutes: 15),
          const Duration(minutes: 15),
        ]);
        expect(rig.handler.sent, everyElement(pref('a')));
        expect(await pendingKeys(), ['pref:a', 'pref:b']);
      });
    }

    test('RateLimited waits the given delay', () async {
      rig.handler.script = (_) =>
          throw const RateLimited(retryAfter: Duration(seconds: 42));
      await rig.put(pref('a'));
      final start = rig.clock.now();

      await rig.pass();

      final head = (await rig.pending()).single;
      expect(head.nextAttemptAt, start.add(const Duration(seconds: 42)));
      rig.clock.advance(const Duration(seconds: 41));
      await rig.pass();
      expect(rig.handler.sent, hasLength(1));
      rig.clock.advance(const Duration(seconds: 1));
      await rig.pass();
      expect(rig.handler.sent, hasLength(2));
    });

    test('Unauthenticated stops and keeps the row unchanged', () async {
      rig.handler.script = (_) => throw const Unauthenticated(status: 401);
      await rig.put(pref('a'));
      await rig.put(pref('b'));

      await rig.pass();

      final entries = await rig.pending();
      expect(entries, hasLength(2));
      expect(entries.first.attempts, 0);
      expect(entries.first.nextAttemptAt, isNull);
      expect(rig.handler.sent, [pref('a')]);
    });

    test(
      '404 drops and continues; three in one pass give one notice',
      () async {
        rig.handler.script = (op) => (op as PreferenceOp).playbackId == 'ok'
            ? null
            : throw const NotFound(status: 404);
        for (final id in ['a', 'b', 'ok', 'c']) {
          await rig.put(pref(id));
        }

        await rig.pass();

        expect(await rig.pending(), isEmpty);
        expect(rig.handler.dropped, [
          for (final id in ['a', 'b', 'c'])
            (pref(id), OutboxDropReason.notFound),
        ]);
        expect(rig.notices, [const OutboxItemsGone(3)]);
      },
    );

    test('409 drops, calls onDropped(conflict) and emits a notice', () async {
      rig.handler.script = (op) => throw const SourceUnavailable(status: 409);
      await rig.put(pref('a'));

      await rig.pass();

      expect(await rig.pending(), isEmpty);
      expect(rig.handler.dropped, [(pref('a'), OutboxDropReason.conflict)]);
      expect(rig.notices, [const OutboxConflict()]);
    });

    test('400 drops with no notice and logs at severe', () async {
      final sink = RecordingSink();
      AppLogging.configure(sinks: [sink], releaseMode: false);
      addTearDown(AppLogging.reset);
      rig.handler.script = (op) => throw const InvalidRequest(status: 400);
      await rig.put(pref('a'));

      await rig.pass();

      expect(await rig.pending(), isEmpty);
      expect(rig.handler.dropped, [(pref('a'), OutboxDropReason.invalid)]);
      expect(rig.notices, isEmpty);
      expect(sink.entries.map((e) => e.level), contains('severe'));
    });
  });

  group('exceptions the table does not list', () {
    test('Forbidden is handled as InvalidRequest', () async {
      rig.handler.script = (op) => throw const Forbidden(status: 403);
      await rig.put(pref('a'));

      await rig.pass();

      expect(await rig.pending(), isEmpty);
      expect(rig.handler.dropped, [(pref('a'), OutboxDropReason.invalid)]);
      expect(rig.notices, isEmpty);
    });

    test('FeatureDisabled is handled as NotFound', () async {
      rig.handler.script = (op) =>
          throw const FeatureDisabled(status: 404, code: 'FEATURE_DISABLED');
      await rig.put(pref('a'));

      await rig.pass();

      expect(rig.handler.dropped, [(pref('a'), OutboxDropReason.notFound)]);
      expect(rig.notices, [const OutboxItemsGone(1)]);
    });

    test('NotSoundspan is handled as Offline', () async {
      rig.handler.script = (op) => throw const NotSoundspan(status: 200);
      await rig.put(pref('a'));
      final start = rig.clock.now();

      await rig.pass();

      final head = (await rig.pending()).single;
      expect(head.attempts, 1);
      expect(head.nextAttemptAt, start.add(const Duration(seconds: 5)));
    });

    for (final error in <ApiException>[
      const InvalidResponse(status: 200),
      const Unexpected(status: 302),
    ]) {
      test(
        '${error.runtimeType} is handled as 2xx with a null response',
        () async {
          rig.handler.script = (op) => throw error;
          await rig.put(pref('a'));

          await rig.pass();

          expect(await rig.pending(), isEmpty);
          expect(rig.handler.succeeded, [(pref('a'), null)]);
        },
      );
    }

    test('an error that is not an ApiException backs off', () async {
      rig.handler.script = (op) => throw StateError('bug');
      await rig.put(pref('a'));

      await rig.pass();

      expect((await rig.pending()).single.attempts, 1);
    });
  });

  group('order and triggers', () {
    test('ops are sent in seq order, one at a time', () async {
      var inFlight = 0;
      var maxInFlight = 0;
      rig.handler.script = (_) async {
        inFlight++;
        maxInFlight = inFlight > maxInFlight ? inFlight : maxInFlight;
        await Future<void>.delayed(Duration.zero);
        inFlight--;
        return null;
      };
      for (final id in ['a', 'b', 'c']) {
        await rig.put(pref(id));
      }

      await rig.pass();

      expect(rig.handler.sent, [pref('a'), pref('b'), pref('c')]);
      expect(maxInFlight, 1);
    });

    test('a failing head blocks later ops', () async {
      rig.handler.script = (_) => throw const Offline();
      await rig.put(pref('a'));
      await rig.put(pref('b'));

      await rig.pass();
      await rig.pass();

      expect(rig.handler.sent, [pref('a')]);
      expect(await pendingKeys(), ['pref:a', 'pref:b']);
    });

    test('a head whose next attempt is due is retried', () async {
      var fail = true;
      rig.handler.script = (_) => fail ? throw const Offline() : null;
      await rig.put(pref('a'));
      await rig.pass();

      fail = false;
      rig.clock.advance(const Duration(seconds: 5));
      await rig.pass();

      expect(await rig.pending(), isEmpty);
    });

    test('enqueue through the facade triggers a pass', () async {
      await rig.worker.start();
      await rig.settle();

      await Outbox(rig.store, rig.worker).enqueue(pref('a'));
      await rig.settle();

      expect(rig.handler.sent, [pref('a')]);
    });

    test('becoming online triggers a pass', () async {
      rig.reachability.set(Reachability.noNetwork);
      await rig.worker.start();
      await rig.put(pref('a'));
      await rig.pass();
      expect(rig.handler.sent, isEmpty);

      rig.reachability.set(Reachability.online);
      await rig.settle();

      expect(rig.handler.sent, [pref('a')]);
    });

    test('nothing is sent while not online', () async {
      for (final state in [
        Reachability.serverUnreachable,
        Reachability.noNetwork,
        Reachability.forcedOffline,
      ]) {
        rig.reachability.set(state);
        await rig.put(pref('a'));
        await rig.pass();
      }

      expect(rig.handler.sent, isEmpty);
    });

    test('the 60 s timer triggers a pass and is cancelled when the store '
        'empties', () async {
      var fail = true;
      rig.handler.script = (_) => fail ? throw const Offline() : null;
      await rig.worker.start();
      await rig.put(pref('a'));
      await rig.pass();

      final timer = rig.activeTimer!;
      expect(timer.period, const Duration(seconds: 60));
      expect(rig.handler.sent, hasLength(1));

      fail = false;
      rig.clock.advance(const Duration(seconds: 60));
      timer.fire();
      await rig.settle();

      expect(rig.handler.sent, hasLength(2));
      expect(await rig.pending(), isEmpty);
      expect(rig.activeTimer, isNull);
      expect(rig.worker.hasTimer, isFalse);
    });

    test('the pending count is unknown until start, then follows the '
        'store', () async {
      rig.reachability.set(Reachability.noNetwork);
      expect(rig.worker.pendingCount.value, isNull);

      await rig.worker.start();
      await rig.settle();
      expect(rig.worker.pendingCount.value, 0);

      await rig.put(pref('a'));
      await rig.settle();
      expect(rig.worker.pendingCount.value, 1);
    });

    test('no timer exists while nothing is pending', () async {
      await rig.worker.start();
      await rig.settle();

      expect(rig.timers, isEmpty);
    });

    test('two triggers during a pass do not start a second pass', () async {
      final gate = Completer<void>();
      var inFlight = 0;
      var maxInFlight = 0;
      rig.handler.script = (_) async {
        inFlight++;
        maxInFlight = inFlight > maxInFlight ? inFlight : maxInFlight;
        await gate.future;
        inFlight--;
        return null;
      };
      await rig.put(pref('a'));

      rig.worker.trigger();
      await Future<void>.delayed(Duration.zero);
      rig.worker
        ..trigger()
        ..trigger();
      gate.complete();
      await rig.settle();

      expect(rig.handler.sent, [pref('a')]);
      expect(maxInFlight, 1);
    });
  });

  group('rules', () {
    test('a play older than 14 days is deleted unsent; one of 13 days is '
        'sent', () async {
      final now = rig.clock.now();
      await rig.put(_play('old', now.subtract(const Duration(days: 15))));
      await rig.put(_play('recent', now.subtract(const Duration(days: 13))));

      await rig.pass();

      expect(rig.handler.sent, [
        _play('recent', now.subtract(const Duration(days: 13))),
      ]);
      expect(await rig.pending(), isEmpty);
      expect(rig.notices, isEmpty);
    });

    test('an op replaced while in flight: the old success does not delete '
        'the replacement, which is then sent', () async {
      final gate = Completer<void>();
      const first = PlaylistRenameOp(playlistId: 'p', name: 'One');
      const second = PlaylistRenameOp(playlistId: 'p', name: 'Two');
      rig.handler.script = (op) async {
        if (op == first) await gate.future;
        return null;
      };
      await rig.put(first);

      rig.worker.trigger();
      await Future<void>.delayed(Duration.zero);
      await rig.put(second);
      rig.worker.trigger();
      gate.complete();
      await rig.settle();

      expect(rig.handler.sent, [first, second]);
      expect(await rig.pending(), isEmpty);
    });

    test('an op with no handler stops the pass and stays', () async {
      await rig.close();
      rig = WorkerRig(unhandled: {AlbumPreferenceOp.type});
      const album = AlbumPreferenceOp(
        albumId: 'al',
        signal: PreferenceSignal.thumbsUp,
      );
      await rig.put(album);
      await rig.put(pref('a'));

      await rig.pass();

      expect(rig.handler.sent, isEmpty);
      expect(await pendingKeys(), ['apref:al', 'pref:a']);
    });

    test('an onSuccess that throws does not stop the pass', () async {
      rig.handler.onSuccessHook = (op, _) async {
        if (op == pref('a')) throw StateError('cache write failed');
      };
      await rig.put(pref('a'));
      await rig.put(pref('b'));

      await rig.pass();

      expect(rig.handler.sent, [pref('a'), pref('b')]);
      expect(await rig.pending(), isEmpty);
    });

    test('flush runs one pass and completes when it has ended', () async {
      await rig.put(pref('a'));
      await rig.put(pref('b'));

      await rig.worker.flush();

      expect(rig.handler.sent, [pref('a'), pref('b')]);
      expect(await rig.pending(), isEmpty);
    });

    test('flush while not online sends nothing and completes', () async {
      rig.reachability.set(Reachability.noNetwork);
      await rig.put(pref('a'));

      await rig.worker.flush();

      expect(rig.handler.sent, isEmpty);
      expect(await pendingKeys(), ['pref:a']);
    });

    test('start after dispose does nothing', () async {
      await rig.worker.dispose();
      await rig.worker.start();
      await rig.put(pref('a'));
      await rig.pass();

      expect(rig.handler.sent, isEmpty);
    });
  });
}
