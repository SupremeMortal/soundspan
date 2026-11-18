// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:soundspan/core/playback/engines/media_kit_engine.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';

/// A libmpv player without libmpv: the test pushes what mpv would report
/// onto the player's streams and sets what `time-pos` reads.
final class _FakeMpv implements NativePlayer {
  final _Channels _channels = _Channels();

  @override
  PlayerStream get stream => _channels.stream;

  @override
  PlayerState get state => _channels.state;

  @override
  set state(PlayerState state) => _channels.state = state;

  /// What mpv's `time-pos` property reads; empty when mpv has none.
  String timePos = '';

  @override
  Future<String> getProperty(
    String property, {
    bool waitForInitialization = true,
  }) async => switch (property) {
    'time-pos' => timePos,
    'idle-active' => 'yes',
    _ => '',
  };

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
    state = state.copyWith(playlist: playlist, duration: _length);
    _channels.playlistController.add(playlist);
    _channels.durationController.add(_length);
  }

  @override
  Future<void> play({bool synchronized = true}) async {}

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

  group('a buffering change after time has passed', () {
    test('reports the position mpv reads now, not the last one', () async {
      mpv
        ..timePos = '0.600000'
        ..buffering(true);
      await pumpEventQueue();

      expect(states, isNotEmpty);
      expect(states.last.status, EngineStatus.buffering);
      for (final state in states) {
        expect(state.position, const Duration(milliseconds: 600));
      }
    });

    test('emits nothing while mpv has no position to read', () async {
      // Between two files: mpv started the next one and the ending item's
      // last audio still plays from the output buffer.
      mpv
        ..timePos = ''
        ..buffering(true);
      await pumpEventQueue();

      expect(states, isEmpty);

      mpv.position(const Duration(milliseconds: 650));
      await pumpEventQueue();

      expect(states.single.status, EngineStatus.buffering);
      expect(states.single.position, const Duration(milliseconds: 650));
    });

    test('still reports a stall at the position mpv stopped at', () async {
      mpv
        ..timePos = '0.550000'
        ..buffering(true);
      await pumpEventQueue();

      expect(states.single.status, EngineStatus.buffering);
      expect(states.single.position, const Duration(milliseconds: 550));
    });
  });

  test(
    'a buffered position change reports the position mpv reads now',
    () async {
      mpv
        ..timePos = '0.620000'
        ..buffer(const Duration(milliseconds: 975));
      await pumpEventQueue();

      expect(states, isNotEmpty);
      for (final state in states) {
        expect(state.position, const Duration(milliseconds: 620));
      }
      expect(states.last.bufferedPosition, const Duration(milliseconds: 975));
    },
  );

  test('a buffering change while paused reports the paused position', () async {
    mpv.timePos = '0.550000';
    await engine.pause();
    await pumpEventQueue();
    states.clear();

    mpv.buffer(const Duration(milliseconds: 975));
    await pumpEventQueue();

    expect(states.single.position, const Duration(milliseconds: 550));
    expect(states.single.playing, isFalse);
  });
}
