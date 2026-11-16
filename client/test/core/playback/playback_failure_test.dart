// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/failure_policy.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan_api/soundspan_api.dart';

import 'controller/controller_harness.dart';
import 'queue/queue_test_items.dart';

const _zero = '0:00:00.000000';
const _four = '0:00:04.000000';

/// Scripts the source of [id] to fail with [error] whenever it is opened.
void _failing(ControllerHarness h, String id, EngineError error) =>
    h.fake.sources[uriOf(id)] = FakeSource(
      duration: trackLength,
      failure: error,
    );

/// Scripts the source of [id] to play.
void _playable(ControllerHarness h, String id, {Map<String, String>? auth}) =>
    h.fake.sources[uriOf(id)] = FakeSource(
      duration: trackLength,
      requiredHeaders: auth ?? const {},
    );

List<String> _loads(List<String> calls) => [
  for (final call in calls)
    if (call.startsWith('load(')) call,
];

const _network = EngineError(EngineErrorKind.network);

void main() {
  group('retry after 1 s', () {
    test('network failure retries once after 1 s at the same position and '
        'continues', () async {
      final h = ControllerHarness();
      await h.controller.playItems(trackItems(['a', 'b']));
      await h.play(const Duration(seconds: 4));
      h.calls.clear();

      h.fake.failCurrent(_network);
      await h.settle();

      expect(_loads(h.calls), isEmpty);
      expect(h.timers.pending, hasLength(1));
      expect(h.timers.pending.single.duration, FailurePolicy.retryDelay);

      await h.timers.fireAll();
      await h.play(const Duration(seconds: 1));

      expect(_loads(h.calls), ['load(a, autoPlay: true, at: $_four)']);
      expect(h.controller.snapshot.current?.queueItemId, 'a');
      expect(h.controller.snapshot.playing, isTrue);
      expect(h.controller.snapshot.position, const Duration(seconds: 5));
      expect(h.controller.snapshot.error, isNull);
      expect(h.notices, isEmpty);
    });

    test('http 503 retries', () async {
      final h = ControllerHarness();
      await h.controller.playItems(trackItems(['a', 'b']));
      await h.play(const Duration(seconds: 4));
      h.calls.clear();

      h.fake.failCurrent(
        const EngineError(EngineErrorKind.http, httpStatus: 503),
      );
      await h.settle();
      await h.timers.fireAll();

      expect(_loads(h.calls), ['load(a, autoPlay: true, at: $_four)']);
      expect(h.notices, isEmpty);
    });

    test('http 409 does not retry', () async {
      final h = ControllerHarness();
      await h.controller.playItems(trackItems(['a', 'b']));
      await h.play(const Duration(seconds: 4));
      h.calls.clear();

      h.fake.failCurrent(
        const EngineError(EngineErrorKind.http, httpStatus: 409),
      );
      await h.settle();

      expect(h.timers.created, isEmpty);
      expect(_loads(h.calls), ['load(b, autoPlay: true, at: $_zero)']);
      expect(h.notices, [
        const ItemSkipped('a', PlaybackErrorKind.itemUnavailable),
      ]);
    });

    test(
      'second network failure skips the item and emits itemSkipped',
      () async {
        final h = ControllerHarness();
        await h.controller.playItems(trackItems(['a', 'b']));
        await h.play(const Duration(seconds: 4));
        h.fake.failCurrent(_network);
        await h.settle();
        _failing(h, 'a', _network);
        h.calls.clear();

        await h.timers.fireAll();
        await h.settle();

        expect(_loads(h.calls), [
          'load(a, autoPlay: true, at: $_four)',
          'load(b, autoPlay: true, at: $_zero)',
        ]);
        expect(h.notices, [
          const ItemSkipped('a', PlaybackErrorKind.itemFailed),
        ]);
        expect(h.controller.snapshot.current?.queueItemId, 'b');
        expect(h.controller.snapshot.playing, isTrue);
      },
    );

    test('a user skip during the 1 s wait cancels the retry', () async {
      final h = ControllerHarness();
      await h.controller.playItems(trackItems(['a', 'b', 'c']));
      await h.play(const Duration(seconds: 4));
      h.fake.failCurrent(_network);
      await h.settle();
      final retry = h.timers.pending.single;
      h.calls.clear();

      await h.controller.next();
      retry.fire();
      await h.settle();

      expect(retry.isActive, isFalse);
      expect(_loads(h.calls), ['load(b, autoPlay: true, at: $_zero)']);
      expect(h.controller.snapshot.current?.queueItemId, 'b');
    });
  });

  group('skip without retry', () {
    for (final (name, script) in [
      ('notFound', (ControllerHarness h) => h.fake.sources.remove(uriOf('a'))),
      (
        'decode',
        (ControllerHarness h) =>
            _failing(h, 'a', const EngineError(EngineErrorKind.decode)),
      ),
      ('NotPlayable', (ControllerHarness h) => h.resolver.unplayable.add('a')),
    ]) {
      test('$name skips without retry', () async {
        final h = ControllerHarness();
        script(h);

        await h.controller.playItems(trackItems(['a', 'b', 'c']));
        await h.settle();

        expect(h.timers.created, isEmpty);
        expect(h.notices, [
          const ItemSkipped('a', PlaybackErrorKind.itemUnavailable),
        ]);
        expect(h.controller.snapshot.current?.queueItemId, 'b');
        expect(h.calls, contains('load(b, autoPlay: true, at: $_zero)'));
        expect(
          _loads(h.calls).where((c) => c.startsWith('load(a')).length,
          lessThanOrEqualTo(1),
        );
      });
    }

    test('a skip keeps the play intent and loads the following item', () async {
      final h = ControllerHarness();
      await h.controller.playItems(trackItems(['a', 'b', 'c']));
      await h.play(const Duration(seconds: 2));
      await h.controller.pause();
      h.calls.clear();

      h.fake.failCurrent(const EngineError(EngineErrorKind.notFound));
      await h.settle();

      expect(_loads(h.calls), ['load(b, autoPlay: false, at: $_zero)']);
      expect(h.controller.snapshot.playing, isFalse);
      expect(h.controller.snapshot.current?.queueItemId, 'b');
    });

    test('a failed last item with repeat off stops', () async {
      final h = ControllerHarness();
      h.fake.sources.remove(uriOf('b'));

      await h.controller.playItems(trackItems(['a', 'b']), startIndex: 1);
      await h.settle();

      expect(h.calls.last, 'stop');
      expect(h.notices, [
        const ItemSkipped('b', PlaybackErrorKind.itemUnavailable),
      ]);
      expect(
        h.controller.snapshot.error,
        const PlaybackError(
          PlaybackErrorKind.itemUnavailable,
          queueItemId: 'b',
        ),
      );
      expect(h.controller.snapshot.playing, isFalse);
      expect(h.controller.snapshot.current?.queueItemId, 'b');
    });

    test('a failed last item with repeat all wraps to the first', () async {
      final h = ControllerHarness();
      h.fake.sources.remove(uriOf('b'));
      await h.controller.setRepeat(RepeatMode.all);

      await h.controller.playItems(trackItems(['a', 'b']), startIndex: 1);
      await h.settle();

      expect(h.controller.snapshot.current?.queueItemId, 'a');
      expect(h.controller.snapshot.playing, isTrue);
    });
  });

  test('a resolve error skips with itemFailed', () async {
    final h = ControllerHarness();
    h.resolver.errors['a'] = const Offline();

    await h.controller.playItems(trackItems(['a', 'b']));
    await h.settle();

    expect(h.notices, [const ItemSkipped('a', PlaybackErrorKind.itemFailed)]);
    expect(h.controller.snapshot.current?.queueItemId, 'b');
  });

  group('consecutive failures', () {
    test('three consecutive failures stop with serverUnreachable; no fourth '
        'item is loaded', () async {
      final h = ControllerHarness();
      for (final id in ['a', 'b', 'c']) {
        h.fake.sources.remove(uriOf(id));
      }

      await h.controller.playItems(trackItems(['a', 'b', 'c', 'd']));
      await h.settle();

      expect(_loads(h.calls), [
        'load(a, autoPlay: true, at: $_zero)',
        'load(b, autoPlay: true, at: $_zero)',
        'load(c, autoPlay: true, at: $_zero)',
      ]);
      expect(h.calls.last, 'stop');
      expect(h.notices, [
        const ItemSkipped('a', PlaybackErrorKind.itemUnavailable),
        const ItemSkipped('b', PlaybackErrorKind.itemUnavailable),
        const PlaybackStopped(PlaybackErrorKind.serverUnreachable),
      ]);
      expect(
        h.controller.snapshot.error,
        const PlaybackError(
          PlaybackErrorKind.serverUnreachable,
          queueItemId: 'c',
        ),
      );
      expect(h.controller.snapshot.playing, isFalse);
    });

    test('a success between failures resets the count', () async {
      final h = ControllerHarness(ids: ['b', 'e']);

      await h.controller.playItems(trackItems(['a', 'b', 'c', 'd', 'e']));
      await h.settle();
      expect(h.controller.snapshot.current?.queueItemId, 'b');
      await h.play(trackLength + const Duration(seconds: 1));

      expect(h.controller.snapshot.current?.queueItemId, 'e');
      expect(h.controller.snapshot.playing, isTrue);
      expect(h.notices, [
        const ItemSkipped('a', PlaybackErrorKind.itemUnavailable),
        const ItemSkipped('c', PlaybackErrorKind.itemUnavailable),
        const ItemSkipped('d', PlaybackErrorKind.itemUnavailable),
      ]);
    });

    test('jumpTo after two failures resets the count', () async {
      final h = ControllerHarness(ids: ['f']);
      _failing(h, 'c', _network);

      await h.controller.playItems(trackItems(['a', 'b', 'c', 'd', 'e', 'f']));
      await h.settle();
      expect(h.controller.snapshot.current?.queueItemId, 'c');
      expect(h.timers.pending, hasLength(1));

      await h.controller.jumpTo('d');
      await h.settle();

      expect(h.timers.pending, isEmpty);
      expect(h.controller.snapshot.current?.queueItemId, 'f');
      expect(h.controller.snapshot.playing, isTrue);
      expect(h.notices.whereType<PlaybackStopped>(), isEmpty);
    });

    test('failure of the preloaded next does not count and does not disturb '
        'the current item', () async {
      final h = ControllerHarness(ids: ['a', 'd']);

      await h.controller.playItems(trackItems(['a', 'b', 'c', 'd']));
      await h.play(const Duration(seconds: 2));

      expect(h.controller.snapshot.current?.queueItemId, 'a');
      expect(h.controller.snapshot.playing, isTrue);
      expect(h.controller.snapshot.error, isNull);
      expect(h.notices, isEmpty);

      await h.play(trackLength);

      expect(h.controller.snapshot.current?.queueItemId, 'd');
      expect(h.controller.snapshot.playing, isTrue);
      expect(h.notices.whereType<PlaybackStopped>(), isEmpty);
    });
  });

  group('unauthorized', () {
    Map<String, String> bearer(ControllerHarness h) => {
      'Authorization':
          'Bearer ${(h.session.current! as JwtCredentials).accessToken}',
    };

    test('unauthorized refreshes, rebuilds the source with the new credential '
        'and resumes at the same position', () async {
      final h = ControllerHarness();
      await h.signIn(
        const JwtCredentials(accessToken: 'access-0', refreshToken: 'r0'),
      );
      h.resolver.headers = () => bearer(h);
      await h.controller.playItems(trackItems(['a', 'b']));
      await h.play(const Duration(seconds: 4));
      _playable(h, 'a', auth: {'Authorization': 'Bearer access-1'});
      h.calls.clear();

      h.fake.failCurrent(
        const EngineError(EngineErrorKind.unauthorized, httpStatus: 401),
      );
      await h.settle();

      expect(h.refreshes, 1);
      expect(_loads(h.calls), ['load(a, autoPlay: true, at: $_four)']);
      expect(h.fake.requested.last.headers, {
        'Authorization': 'Bearer access-1',
      });
      expect(h.controller.snapshot.status, EngineStatus.ready);
      expect(h.controller.snapshot.playing, isTrue);
      expect(h.notices, isEmpty);
    });

    test('second unauthorized stops with PlaybackErrorKind.unauthorized and '
        'does not skip', () async {
      final h = ControllerHarness(ids: ['b']);
      await h.signIn(
        const JwtCredentials(accessToken: 'access-0', refreshToken: 'r0'),
      );
      h.resolver.headers = () => bearer(h);
      _playable(h, 'a', auth: {'Authorization': 'Bearer never'});

      await h.controller.playItems(trackItems(['a', 'b']));
      await h.settle();

      expect(h.refreshes, 1);
      expect(_loads(h.calls), [
        'load(a, autoPlay: true, at: $_zero)',
        'load(a, autoPlay: true, at: $_zero)',
      ]);
      expect(h.notices, [
        const PlaybackStopped(PlaybackErrorKind.unauthorized),
      ]);
      expect(
        h.controller.snapshot.error,
        const PlaybackError(PlaybackErrorKind.unauthorized, queueItemId: 'a'),
      );
      expect(h.controller.snapshot.current?.queueItemId, 'a');
      expect(h.controller.snapshot.playing, isFalse);
    });

    test('unauthorized with an API-key session retries once without a refresh '
        'request and then stops', () async {
      final h = ControllerHarness(ids: ['b']);
      await h.signIn(const ApiKeyCredentials(apiKey: 'key-1'));
      h.resolver.headers = () => {
        'X-API-Key': (h.session.current! as ApiKeyCredentials).apiKey,
      };
      _playable(h, 'a', auth: {'X-API-Key': 'key-2'});

      await h.controller.playItems(trackItems(['a', 'b']));
      await h.settle();

      expect(h.refreshes, 0);
      expect(_loads(h.calls), [
        'load(a, autoPlay: true, at: $_zero)',
        'load(a, autoPlay: true, at: $_zero)',
      ]);
      expect(h.notices, [
        const PlaybackStopped(PlaybackErrorKind.unauthorized),
      ]);
    });

    test(
      'a failed renewal stops with PlaybackErrorKind.unauthorized',
      () async {
        final h = ControllerHarness(ids: ['b']);
        _playable(h, 'a', auth: {'Authorization': 'Bearer never'});

        await h.controller.playItems(trackItems(['a', 'b']));
        await h.settle();

        expect(h.notices, [
          const PlaybackStopped(PlaybackErrorKind.unauthorized),
        ]);
        expect(h.controller.snapshot.playing, isFalse);
      },
    );
  });
}
