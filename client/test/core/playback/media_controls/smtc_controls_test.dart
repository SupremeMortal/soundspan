// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/media_controls/media_controls.dart';
import 'package:soundspan/core/playback/media_controls/smtc_controls.dart';
import 'package:soundspan/core/playback/media_controls/smtc_gateway.dart';
import 'package:soundspan/shared/clock.dart';

import '../../../helpers/recording_media_command_handler.dart';

/// Records every gateway call as a line of text.
class FakeSmtcGateway implements SmtcGateway {
  final List<String> calls = [];
  final StreamController<SmtcButton> buttons = StreamController.broadcast();
  final StreamController<Duration> seeks = StreamController.broadcast();

  List<String> named(String name) =>
      calls.where((c) => c.startsWith('$name ') || c == name).toList();

  @override
  Future<void> init() async => calls.add('init');

  @override
  Stream<SmtcButton> get buttonPresses => buttons.stream;

  @override
  Stream<Duration> get seekRequests => seeks.stream;

  @override
  Future<void> setEnabledButtons(Set<SmtcButton> buttons) async {
    final names = buttons.map((b) => b.name).toList()..sort();
    calls.add('buttons ${names.join(',')}');
  }

  @override
  Future<void> setMetadata({
    required String title,
    required String artist,
    required String album,
    Uri? thumbnail,
  }) async => calls.add('metadata $title|$artist|$album|$thumbnail');

  @override
  Future<void> setStatus(SmtcStatus status) async =>
      calls.add('status ${status.name}');

  @override
  Future<void> setTimeline({
    required Duration position,
    required Duration? duration,
  }) async => calls.add(
    'timeline ${position.inMilliseconds}/${duration?.inMilliseconds}',
  );

  @override
  Future<void> clear() async => calls.add('clear');

  @override
  Future<void> dispose() async => calls.add('dispose');
}

/// A [Clock] that reads the fake time of [async].
class _AsyncClock implements Clock {
  new(this.async);

  final FakeAsync async;

  @override
  DateTime now() => DateTime.utc(2026, 11, 17).add(async.elapsed);
}

final Uri _art = Uri.parse('file:///profiles/p/art/now-playing.img');

MediaSessionState _track({
  bool playing = true,
  bool buffering = false,
  Duration position = const Duration(seconds: 42),
  Uri? artwork,
  String title = 'Song',
}) => MediaSessionState(
  queueItemId: 'q1',
  title: title,
  artist: 'Artist',
  album: 'Album',
  duration: const Duration(minutes: 3, seconds: 35),
  artworkUri: artwork ?? _art,
  position: position,
  playing: playing,
  buffering: buffering,
  speed: 1,
  skipInterval: const Duration(seconds: 15),
  actions: {
    if (playing) MediaAction.pause else MediaAction.play,
    MediaAction.seek,
    MediaAction.stop,
    MediaAction.next,
    MediaAction.previous,
  },
);

const MediaSessionState _episode = MediaSessionState(
  queueItemId: 'e1',
  title: 'Episode',
  artist: 'Podcast',
  album: '',
  position: Duration.zero,
  playing: true,
  buffering: false,
  speed: 1,
  skipInterval: Duration(seconds: 15),
  actions: {
    MediaAction.pause,
    MediaAction.seek,
    MediaAction.stop,
    MediaAction.skipForward,
    MediaAction.skipBackward,
  },
);

void main() {
  late FakeSmtcGateway gateway;
  late RecordingMediaCommandHandler handler;

  setUp(() {
    gateway = FakeSmtcGateway();
    handler = RecordingMediaCommandHandler();
  });

  /// Runs [body] with initialised controls in fake time.
  void run(void Function(FakeAsync async, SmtcControls controls) body) {
    fakeAsync((async) {
      final controls = SmtcControls(
        gateway: gateway,
        clock: _AsyncClock(async),
      );
      unawaited(controls.init(handler));
      async.flushMicrotasks();
      body(async, controls);
      unawaited(controls.dispose());
      async.flushMicrotasks();
    });
  }

  test('init initialises the gateway once', () {
    run((async, controls) {
      expect(gateway.named('init'), ['init']);
    });
  });

  test('each button press reaches the matching handler method', () {
    run((async, controls) {
      SmtcButton.values.forEach(gateway.buttons.add);
      async.flushMicrotasks();
      expect(handler.calls, [
        'play',
        'pause',
        'next',
        'previous',
        'stop',
        'skipForward',
        'skipBackward',
      ]);
    });
  });

  test('a seek request reaches seek', () {
    run((async, controls) {
      gateway.seeks.add(const Duration(seconds: 90));
      async.flushMicrotasks();
      expect(handler.calls, ['seek 90000']);
    });
  });

  test('a playing track enables play/pause, next, previous and stop and '
      'sets status playing', () {
    run((async, controls) {
      controls.update(_track());
      async.flushMicrotasks();
      expect(gateway.named('buttons'), [
        'buttons next,pause,play,previous,stop',
      ]);
      expect(gateway.named('status'), ['status playing']);
    });
  });

  test('a single episode enables fast forward and rewind, not next and '
      'previous', () {
    run((async, controls) {
      controls.update(_episode);
      async.flushMicrotasks();
      expect(gateway.named('buttons'), [
        'buttons fastForward,pause,play,rewind,stop',
      ]);
    });
  });

  test('metadata is sent on the first update and not again when only the '
      'position or the playing flag changes', () {
    run((async, controls) {
      controls
        ..update(_track())
        ..update(_track(position: const Duration(seconds: 80)))
        ..update(_track(playing: false));
      async.flushMicrotasks();
      expect(gateway.named('metadata'), ['metadata Song|Artist|Album|$_art']);
    });
  });

  test('a new artwork URI or title resends the metadata', () {
    final other = Uri.parse('file:///profiles/p/art/other.img');
    run((async, controls) {
      controls
        ..update(_track())
        ..update(_track(artwork: other))
        ..update(_track(artwork: other, title: 'Next'));
      async.flushMicrotasks();
      expect(gateway.named('metadata'), [
        'metadata Song|Artist|Album|$_art',
        'metadata Song|Artist|Album|$other',
        'metadata Next|Artist|Album|$other',
      ]);
    });
  });

  test('an item without artwork sends no thumbnail', () {
    run((async, controls) {
      controls.update(_episode);
      async.flushMicrotasks();
      expect(gateway.named('metadata'), ['metadata Episode|Podcast||null']);
    });
  });

  test('buffering maps to changing and paused to paused', () {
    run((async, controls) {
      controls
        ..update(_track(buffering: true))
        ..update(_track(playing: false));
      async.flushMicrotasks();
      expect(gateway.named('status'), ['status changing', 'status paused']);
    });
  });

  test('the timeline is sent on update and every 5 s while playing', () {
    run((async, controls) {
      controls.update(_track());
      async.flushMicrotasks();
      expect(gateway.named('timeline'), ['timeline 42000/215000']);

      async.elapse(const Duration(seconds: 4));
      expect(gateway.named('timeline'), hasLength(1));
      async
        ..elapse(const Duration(seconds: 1))
        ..elapse(const Duration(seconds: 5));
      expect(gateway.named('timeline'), [
        'timeline 42000/215000',
        'timeline 47000/215000',
        'timeline 52000/215000',
      ]);
    });
  });

  test('the timeline is not sent periodically while paused', () {
    run((async, controls) {
      controls
        ..update(_track())
        ..update(_track(playing: false, position: const Duration(seconds: 50)));
      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 20));
      expect(gateway.named('timeline'), [
        'timeline 42000/215000',
        'timeline 50000/215000',
      ]);
    });
  });

  test('the empty state clears the session and sets closed', () {
    run((async, controls) {
      controls
        ..update(_track())
        ..update(MediaSessionState.empty);
      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 20));
      expect(gateway.calls.sublist(gateway.calls.indexOf('clear')), [
        'clear',
        'status closed',
      ]);
    });
  });

  test('after the empty state the next item resends its metadata', () {
    run((async, controls) {
      controls
        ..update(_track())
        ..update(MediaSessionState.empty)
        ..update(_track());
      async.flushMicrotasks();
      expect(gateway.named('metadata'), hasLength(2));
    });
  });

  test('dispose stops the timer and the subscriptions and disposes the '
      'gateway', () {
    fakeAsync((async) {
      final controls = SmtcControls(
        gateway: gateway,
        clock: _AsyncClock(async),
      );
      unawaited(controls.init(handler));
      async.flushMicrotasks();
      controls.update(_track());
      unawaited(controls.dispose());
      async.flushMicrotasks();
      expect(gateway.calls.last, 'dispose');

      final before = gateway.calls.length;
      gateway.buttons.add(SmtcButton.play);
      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 20));
      expect(gateway.calls, hasLength(before));
      expect(handler.calls, isEmpty);
      expect(async.periodicTimerCount, 0);
    });
  });
}
