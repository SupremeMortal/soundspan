// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/engines/player_engine_provider.dart';
import 'package:soundspan/platform/player_engine/player_engine_factory.dart';

final Uri _a = Uri.parse('https://music.test/a');
final Uri _b = Uri.parse('https://music.test/b');
final Uri _c = Uri.parse('https://music.test/c');

EngineSource _source(
  String id,
  Uri uri, {
  Map<String, String> headers = const {},
}) => EngineSource(queueItemId: id, uri: uri, headers: headers);

void main() {
  late FakeEngine engine;
  late List<EngineEvent> events;
  late List<EngineState> states;

  void attach(FakeEngine e) {
    engine = e;
    events = [];
    states = [];
    e.events.listen(events.add);
    e.state.listen(states.add);
  }

  tearDown(() async {
    if (!engine.isDisposed) await engine.dispose();
  });

  test(
    'a scripted failure is reported on load, which still completes',
    () async {
      attach(
        FakeEngine(
          sources: {
            _a: const FakeSource(
              duration: Duration(seconds: 2),
              failure: EngineError(
                EngineErrorKind.decode,
                detail: 'bad frames',
              ),
            ),
          },
        ),
      );

      await engine.load(_source('a', _a));
      await pumpEventQueue();

      expect(events, [const Failed('a', EngineError(EngineErrorKind.decode))]);
      expect(states.last.status, EngineStatus.error);
      expect(states.last.error?.kind, EngineErrorKind.decode);
      expect(states.last.currentQueueItemId, 'a');
      expect(states.last.playing, isFalse);
    },
  );

  test('a source with no script fails with notFound', () async {
    attach(FakeEngine());

    await engine.load(_source('a', _a));
    await pumpEventQueue();

    expect(events.single, isA<Failed>());
    expect((events.single as Failed).error.kind, EngineErrorKind.notFound);
  });

  test(
    'missing required headers fail with unauthorized and status 401',
    () async {
      attach(
        FakeEngine(
          sources: {
            _a: const FakeSource(
              duration: Duration(seconds: 2),
              requiredHeaders: {'Authorization': 'Bearer k'},
            ),
          },
        ),
      );

      await engine.load(
        _source('a', _a, headers: {'Authorization': 'Bearer x'}),
      );
      await pumpEventQueue();

      expect(events, [
        const Failed(
          'a',
          EngineError(EngineErrorKind.unauthorized, httpStatus: 401),
        ),
      ]);
    },
  );

  test(
    'a failing next source reports its own id and leaves current playing',
    () async {
      attach(
        FakeEngine(
          sources: {_a: const FakeSource(duration: Duration(seconds: 2))},
        ),
      );

      await engine.load(_source('a', _a), next: _source('b', _b));
      engine.advance(const Duration(seconds: 3));
      await pumpEventQueue();

      expect(events, [
        const Failed('b', EngineError(EngineErrorKind.notFound)),
        const Completed('a'),
      ]);
    },
  );

  test('advance across two boundaries emits events in order', () async {
    const second = Duration(seconds: 1);
    attach(
      FakeEngine(
        sources: {
          _a: const FakeSource(duration: second),
          _b: const FakeSource(duration: second),
          _c: const FakeSource(duration: second),
        },
      ),
    );

    await engine.load(_source('a', _a), next: _source('b', _b));
    engine
      ..advance(const Duration(milliseconds: 600))
      ..advance(const Duration(milliseconds: 600));
    await engine.setNext(_source('c', _c));
    engine.advance(const Duration(milliseconds: 2000));
    await pumpEventQueue();

    expect(events, [
      const AdvancedToNext('b'),
      const AdvancedToNext('c'),
      const Completed('c'),
    ]);
    expect(states.last.status, EngineStatus.ended);
    expect(states.last.position, second);
    final order = states.map((s) => s.currentQueueItemId).toSet().toList();
    expect(order, [null, 'a', 'b', 'c']);
  });

  test('requested records every source with its headers', () async {
    attach(
      FakeEngine(
        sources: {
          _a: const FakeSource(duration: Duration(seconds: 2)),
          _b: const FakeSource(duration: Duration(seconds: 2)),
        },
      ),
    );

    await engine.load(
      _source('a', _a, headers: {'X-Api-Key': 'k'}),
      next: _source('b', _b, headers: {'X-Api-Key': 'k2'}),
    );

    expect(engine.requested.map((s) => s.queueItemId), ['a', 'b']);
    expect(engine.requested.first.headers, {'X-Api-Key': 'k'});
    expect(engine.requested.last.headers, {'X-Api-Key': 'k2'});
  });

  test('advance emits nothing while paused', () async {
    attach(
      FakeEngine(
        sources: {_a: const FakeSource(duration: Duration(seconds: 2))},
      ),
    );
    await engine.load(_source('a', _a));
    await engine.pause();
    await pumpEventQueue();
    final before = states.length;

    engine.advance(const Duration(seconds: 5));
    await pumpEventQueue();

    expect(states, hasLength(before));
    expect(events, isEmpty);
    expect(states.last.position, Duration.zero);
  });

  test(
    'clamps seek, volume and speed; play with nothing loaded is a no-op',
    () async {
      attach(
        FakeEngine(
          sources: {_a: const FakeSource(duration: Duration(seconds: 2))},
        ),
      );

      await engine.play();
      await engine.setVolume(1.5);
      await engine.setSpeed(9);
      await pumpEventQueue();
      expect(states, [EngineState.idle]);
      expect(engine.volume, 1.0);
      expect(engine.speed, 3.0);

      await engine.setVolume(-1);
      await engine.setSpeed(0.1);
      expect(engine.volume, 0.0);
      expect(engine.speed, 0.5);

      await engine.load(_source('a', _a), autoPlay: false);
      await engine.seek(const Duration(seconds: 9));
      await pumpEventQueue();
      expect(states.last.position, const Duration(seconds: 2));
      await engine.seek(const Duration(seconds: -1));
      await pumpEventQueue();
      expect(states.last.position, Duration.zero);
    },
  );

  test('http sources fail with network once the network is disabled', () async {
    final file = Uri.file('/music/a.flac');
    attach(
      FakeEngine(
        sources: {
          _a: const FakeSource(duration: Duration(seconds: 2)),
          file: const FakeSource(duration: Duration(seconds: 2)),
        },
      )..networkAvailable = false,
    );

    await engine.load(_source('a', _a));
    await pumpEventQueue();
    expect((events.single as Failed).error.kind, EngineErrorKind.network);

    await engine.load(_source('f', file));
    await pumpEventQueue();
    expect(states.last.status, EngineStatus.ready);
    expect(states.last.playing, isTrue);
  });

  test(
    'dispose closes both streams and later calls throw StateError',
    () async {
      attach(FakeEngine());
      var stateDone = false;
      var eventsDone = false;
      engine.state.listen(null, onDone: () => stateDone = true);
      engine.events.listen(null, onDone: () => eventsDone = true);

      await engine.dispose();
      await pumpEventQueue();

      expect(stateDone, isTrue);
      expect(eventsDone, isTrue);
      expect(engine.play, throwsStateError);
      expect(() => engine.advance(Duration.zero), throwsStateError);
      expect(engine.dispose, throwsStateError);
    },
  );

  group('playerEngineBuilderProvider', () {
    setUp(() => attach(FakeEngine()));

    test('defaults to the platform factory', () {
      final container = ProviderContainer.test();

      final build = container.read(playerEngineBuilderProvider);

      expect(build, createPlayerEngine);
    });

    test('returns the override when overridden', () {
      final container = ProviderContainer.test(
        overrides: [
          playerEngineBuilderProvider.overrideWithValue(FakeEngine.new),
        ],
      );

      final built = container.read(playerEngineBuilderProvider)();
      addTearDown(built.dispose);

      expect(built, isA<FakeEngine>());
    });
  });
}
