// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:soundspan/core/playback/engines/media_kit_engine.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';

/// A libmpv player without libmpv: the test pushes what mpv would report
/// onto the player's streams.
final class _FakeMpv implements NativePlayer {
  final _Channels _channels = _Channels();

  /// Every property read, in order. libmpv answers a read synchronously on
  /// the calling isolate, so a read while mpv's core is stuck freezes the
  /// app.
  final List<String> reads = [];

  /// Whether mpv reports the duration of an opened source; when false, the
  /// load never finishes.
  bool reportsDuration = true;

  /// When set, `play` returns only once it completes.
  Completer<void>? playHeld;

  @override
  PlayerStream get stream => _channels.stream;

  @override
  PlayerState get state => _channels.state;

  @override
  set state(PlayerState state) => _channels.state = state;

  @override
  Future<String> getProperty(
    String property, {
    bool waitForInitialization = true,
  }) async {
    reads.add(property);
    return property == 'idle-active' ? 'yes' : '';
  }

  @override
  Future<void> setProperty(
    String property,
    String value, {
    bool waitForInitialization = true,
  }) async {}

  @override
  Future<void> open(
    Playable playable, {
    bool play = true,
    bool synchronized = true,
  }) async {
    final playlist = playable is Playlist ? playable : const Playlist([]);
    state = state.copyWith(playlist: playlist);
    _channels.playlistController.add(playlist);
    if (!reportsDuration) return;
    state = state.copyWith(duration: _length);
    _channels.durationController.add(_length);
  }

  @override
  Future<void> play({bool synchronized = true}) async {
    await playHeld?.future;
  }

  @override
  Future<void> pause({bool synchronized = true}) async {}

  @override
  Future<void> stop({
    bool open = false,
    bool notify = true,
    bool synchronized = true,
  }) async {}

  @override
  Future<void> dispose({bool synchronized = true}) async {}

  /// mpv reports a new position.
  void position(Duration position) {
    state = state.copyWith(position: position);
    _channels.positionController.add(position);
  }

  /// mpv's buffering state changes.
  void buffering(bool buffering) {
    state = state.copyWith(buffering: buffering);
    _channels.bufferingController.add(buffering);
  }

  /// mpv's buffered position changes.
  void buffer(Duration buffer) {
    state = state.copyWith(buffer: buffer);
    _channels.bufferController.add(buffer);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The stream controllers of a platform player, which the fake feeds.
final class _Channels extends PlatformPlayer {
  new() : super(configuration: const PlayerConfiguration());
}

const Duration _length = Duration(seconds: 1);

final EngineSource _a = EngineSource(
  queueItemId: 'a',
  uri: Uri.parse('http://127.0.0.1/a'),
);

void main() {
  group('after a source loaded', _loaded);

  group('a load mpv never finishes', () {
    test('fails the current source as a network error after the load time '
        'limit', () {
      fakeAsync((async) {
        final mpv = _FakeMpv()..reportsDuration = false;
        final engine = MediaKitEngine(
          statusOf: (_, _) async => null,
          player: Player(platformPlayer: mpv),
        );
        final states = <EngineState>[];
        final events = <EngineEvent>[];
        engine.state.listen(states.add);
        engine.events.listen(events.add);
        var loaded = false;
        unawaited(engine.load(_a).then((_) => loaded = true));

        async.elapse(MediaKitEngine.loadTimeLimit - const Duration(seconds: 1));
        expect(loaded, isFalse);
        expect(events, isEmpty);

        async.elapse(const Duration(seconds: 2));
        expect(loaded, isTrue);
        final failed = events.single as Failed;
        expect(failed.queueItemId, 'a');
        expect(failed.error.kind, EngineErrorKind.network);
        expect(states.last.status, EngineStatus.error);

        unawaited(engine.dispose());
        async.flushTimers();
      });
    });
  });

  test('a player call that never returns does not hold up later calls', () {
    fakeAsync((async) {
      final mpv = _FakeMpv();
      final engine = MediaKitEngine(
        statusOf: (_, _) async => null,
        player: Player(platformPlayer: mpv),
      );
      unawaited(engine.load(_a, autoPlay: false));
      async.flushMicrotasks();
      mpv.playHeld = Completer<void>();
      Object? playError;
      unawaited(engine.play().catchError((Object e) => playError = e));
      var paused = false;
      unawaited(engine.pause().then((_) => paused = true));

      async.elapse(MediaKitEngine.callTimeLimit - const Duration(seconds: 1));
      expect(paused, isFalse);

      async.elapse(const Duration(seconds: 2));
      expect(playError, isA<TimeoutException>());
      expect(paused, isTrue);

      unawaited(engine.dispose());
      async.flushTimers();
    });
  });
}

void _loaded() {
  late _FakeMpv mpv;
  late MediaKitEngine engine;
  late List<EngineState> states;
  late StreamSubscription<EngineState> subscription;

  setUp(() async {
    mpv = _FakeMpv();
    engine = MediaKitEngine(
      statusOf: (_, _) async => null,
      player: Player(platformPlayer: mpv),
    );
    states = [];
    subscription = engine.state.listen(states.add);
    await engine.load(_a);
    mpv
      ..position(const Duration(milliseconds: 100))
      ..position(const Duration(milliseconds: 550));
    await pumpEventQueue();
    expect(states.last.status, EngineStatus.ready);
    expect(states.last.position, const Duration(milliseconds: 550));
    states.clear();
  });

  tearDown(() async {
    await subscription.cancel();
    await engine.dispose();
  });

  tearDown(() {
    // libmpv answers a property read synchronously on the app's isolate,
    // so while playing no read may wait on mpv's core.
    expect(mpv.reads, isNot(contains('time-pos')));
  });

  group('a buffering change while the clock runs', () {
    test('goes out with the next position, never stamped with an older '
        'one', () async {
      mpv.buffering(true);
      await pumpEventQueue();

      expect(states, isEmpty);

      mpv.position(const Duration(milliseconds: 600));
      await pumpEventQueue();

      expect(states.single.status, EngineStatus.buffering);
      expect(states.single.position, const Duration(milliseconds: 600));
    });

    test('goes out at the position mpv stopped at when no position '
        'follows', () async {
      mpv.buffering(true);
      await Future<void>.delayed(
        MediaKitEngine.positionWait + const Duration(milliseconds: 50),
      );

      expect(states.single.status, EngineStatus.buffering);
      expect(states.single.position, const Duration(milliseconds: 550));
    });
  });

  test('a buffered position change goes out with the next position', () async {
    mpv.buffer(const Duration(milliseconds: 975));
    await pumpEventQueue();

    expect(states, isEmpty);

    mpv.position(const Duration(milliseconds: 620));
    await pumpEventQueue();

    expect(states.single.position, const Duration(milliseconds: 620));
    expect(states.single.bufferedPosition, const Duration(milliseconds: 975));
  });

  test('a buffering change while paused reports the paused position', () async {
    await engine.pause();
    await pumpEventQueue();
    states.clear();

    mpv.buffer(const Duration(milliseconds: 975));
    await pumpEventQueue();

    expect(states.single.position, const Duration(milliseconds: 550));
    expect(states.single.playing, isFalse);
  });
}
