// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:audio_service/audio_service.dart' as svc;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/media_controls/audio_service_controls.dart';
import 'package:soundspan/core/playback/media_controls/media_controls.dart';

import '../../../helpers/fake_clock.dart';
import '../../../helpers/recording_media_command_handler.dart';

final DateTime _at = DateTime.utc(2026, 11, 16, 12);

MediaSessionState _track({
  bool playing = true,
  bool buffering = false,
  Duration position = const Duration(seconds: 42),
  double speed = 1,
}) => MediaSessionState(
  queueItemId: 'q1',
  title: 'Song',
  artist: 'Artist',
  album: 'Album',
  duration: const Duration(minutes: 3, seconds: 35),
  artworkUri: Uri.parse('file:///profiles/p/art/now-playing.img'),
  position: position,
  playing: playing,
  buffering: buffering,
  speed: speed,
  skipInterval: const Duration(seconds: 15),
  actions: {
    if (playing) MediaAction.pause else MediaAction.play,
    MediaAction.seek,
    MediaAction.stop,
    MediaAction.next,
    MediaAction.previous,
  },
);

MediaSessionState _episode({Set<MediaAction> extra = const {}}) =>
    MediaSessionState(
      queueItemId: 'e1',
      title: 'Episode',
      artist: 'Podcast',
      album: '',
      position: Duration.zero,
      playing: true,
      buffering: false,
      speed: 1,
      skipInterval: const Duration(seconds: 15),
      actions: {
        MediaAction.pause,
        MediaAction.seek,
        MediaAction.stop,
        MediaAction.skipForward,
        MediaAction.skipBackward,
        ...extra,
      },
    );

void main() {
  group('SoundspanAudioHandler', () {
    final cases = <String, Future<void> Function(SoundspanAudioHandler)>{
      'play': (h) => h.play(),
      'pause': (h) => h.pause(),
      'stop': (h) => h.stop(),
      'next': (h) => h.skipToNext(),
      'previous': (h) => h.skipToPrevious(),
      'seek 90000': (h) => h.seek(const Duration(seconds: 90)),
      'skipForward': (h) => h.fastForward(),
      'skipBackward': (h) => h.rewind(),
    };
    for (final MapEntry(key: expected, value: press) in cases.entries) {
      test('forwards to $expected', () async {
        final commands = RecordingMediaCommandHandler();
        final handler = SoundspanAudioHandler(commands);

        await press(handler);

        expect(commands.calls, [expected]);
      });
    }

    test('a headset click while playing pauses, and while paused plays, '
        'from the state it was last shown', () async {
      final commands = RecordingMediaCommandHandler();
      final handler = SoundspanAudioHandler(commands);
      final (_, playing) = audioServiceStateOf(_track(), updateTime: _at);
      handler.playbackState.add(playing);

      await handler.click();
      final (_, paused) = audioServiceStateOf(
        _track(playing: false),
        updateTime: _at,
      );
      handler.playbackState.add(paused);
      await handler.click();

      expect(commands.calls, ['pause', 'play']);
    });
  });

  group('audioServiceStateOf', () {
    test('a playing track gives previous, pause and next, compact, and '
        'seek and stop as system actions', () {
      final (_, state) = audioServiceStateOf(_track(), updateTime: _at);

      expect(state.controls, [
        svc.MediaControl.skipToPrevious,
        svc.MediaControl.pause,
        svc.MediaControl.skipToNext,
      ]);
      expect(state.androidCompactActionIndices, [0, 1, 2]);
      expect(state.systemActions, {svc.MediaAction.seek, svc.MediaAction.stop});
      expect(state.playing, isTrue);
      expect(state.processingState, svc.AudioProcessingState.ready);
    });

    test('a paused track gives play instead of pause', () {
      final (_, state) = audioServiceStateOf(
        _track(playing: false),
        updateTime: _at,
      );

      expect(state.controls, [
        svc.MediaControl.skipToPrevious,
        svc.MediaControl.play,
        svc.MediaControl.skipToNext,
      ]);
      expect(state.playing, isFalse);
    });

    test('a single episode gives rewind, play/pause and fast-forward, and '
        'no previous or next', () {
      final (_, state) = audioServiceStateOf(_episode(), updateTime: _at);

      expect(state.controls, [
        svc.MediaControl.rewind,
        svc.MediaControl.pause,
        svc.MediaControl.fastForward,
      ]);
      expect(state.androidCompactActionIndices, [0, 1, 2]);
    });

    test('an episode in a longer queue keeps previous, play/pause and next '
        'compact, with the skips in the expanded view', () {
      final (_, state) = audioServiceStateOf(
        _episode(extra: {MediaAction.next, MediaAction.previous}),
        updateTime: _at,
      );

      expect(state.controls, [
        svc.MediaControl.skipToPrevious,
        svc.MediaControl.rewind,
        svc.MediaControl.pause,
        svc.MediaControl.fastForward,
        svc.MediaControl.skipToNext,
      ]);
      expect(state.androidCompactActionIndices, [0, 2, 4]);
    });

    test('the media item carries id, title, artist, album, duration and '
        'artwork', () {
      final (item, _) = audioServiceStateOf(_track(), updateTime: _at);

      expect(item, isNotNull);
      expect(item!.id, 'q1');
      expect(item.title, 'Song');
      expect(item.artist, 'Artist');
      expect(item.album, 'Album');
      expect(item.duration, const Duration(minutes: 3, seconds: 35));
      expect(item.artUri, Uri.parse('file:///profiles/p/art/now-playing.img'));
    });

    test('an episode has no album', () {
      final (item, _) = audioServiceStateOf(_episode(), updateTime: _at);

      expect(item!.album, isNull);
      expect(item.artist, 'Podcast');
    });

    test('buffering maps to buffering', () {
      final (_, state) = audioServiceStateOf(
        _track(buffering: true),
        updateTime: _at,
      );

      expect(state.processingState, svc.AudioProcessingState.buffering);
      expect(state.playing, isTrue);
    });

    test('the empty state is idle with no media item and no controls', () {
      final (item, state) = audioServiceStateOf(
        MediaSessionState.empty,
        updateTime: _at,
      );

      expect(item, isNull);
      expect(state.processingState, svc.AudioProcessingState.idle);
      expect(state.playing, isFalse);
      expect(state.controls, isEmpty);
      expect(state.systemActions, isEmpty);
    });

    test('position, speed and the update time are carried over', () {
      final (_, state) = audioServiceStateOf(
        _track(position: const Duration(seconds: 77), speed: 1.5),
        updateTime: _at,
      );

      expect(state.updatePosition, const Duration(seconds: 77));
      expect(state.speed, 1.5);
      expect(state.updateTime, _at);
    });
  });

  group('audioServiceConfigFor', () {
    test('Android and the other audio_service targets use the playback '
        'channel', () {
      for (final os in ['android', 'ios', 'macos', 'web']) {
        final config = audioServiceConfigFor(
          operatingSystem: os,
          channelName: 'Wiedergabe',
        );

        expect(config.androidNotificationChannelId, playbackChannelId);
        expect(config.androidNotificationChannelName, 'Wiedergabe');
        expect(config.androidNotificationOngoing, isTrue);
        expect(config.androidStopForegroundOnPause, isTrue);
        expect(config.androidNotificationIcon, 'drawable/ic_stat_soundspan');
        expect(config.fastForwardInterval, const Duration(seconds: 15));
        expect(config.rewindInterval, const Duration(seconds: 15));
      }
    });

    test('Linux names the MPRIS player soundspan, from which '
        'audio_service_mpris derives its bus name', () {
      final config = audioServiceConfigFor(
        operatingSystem: 'linux',
        channelName: 'Wiedergabe',
      );

      expect(config.androidNotificationChannelId, 'soundspan');
      expect(config.androidNotificationChannelName, 'soundspan');
      expect(mprisBusNamePrefix, 'org.mpris.MediaPlayer2.soundspan');
    });
  });

  group('AudioServiceControls', () {
    late svc.AudioServiceConfig? startedWith;
    late SoundspanAudioHandler? started;

    AudioServiceControls controls(FakeClock clock) => AudioServiceControls(
      config: () => audioServiceConfigFor(
        operatingSystem: 'android',
        channelName: 'Playback',
      ),
      start: (builder, config) async {
        startedWith = config;
        return started = builder();
      },
      clock: clock,
    );

    setUp(() {
      startedWith = null;
      started = null;
    });

    test('init starts the service with a handler forwarding to the given '
        'commands', () async {
      final commands = RecordingMediaCommandHandler();
      final c = controls(FakeClock());

      await c.init(commands);
      await started!.play();

      expect(startedWith!.androidNotificationChannelId, playbackChannelId);
      expect(commands.calls, ['play']);
    });

    test('update publishes the media item and playback state, stamped with '
        'the clock', () async {
      final clock = FakeClock(start: _at);
      final c = controls(clock);
      await c.init(RecordingMediaCommandHandler());

      c.update(_track());

      expect(started!.mediaItem.value!.id, 'q1');
      expect(started!.playbackState.value.playing, isTrue);
      expect(started!.playbackState.value.updateTime, _at);

      c.update(MediaSessionState.empty);

      expect(started!.mediaItem.value, isNull);
      expect(
        started!.playbackState.value.processingState,
        svc.AudioProcessingState.idle,
      );
    });

    test('update before init and after dispose shows nothing and does not '
        'throw', () async {
      final c = controls(FakeClock())..update(_track());
      await c.init(RecordingMediaCommandHandler());
      final handler = started!;

      await c.dispose();
      c.update(_track());

      expect(handler.mediaItem.value, isNull);
      expect(
        handler.playbackState.value.processingState,
        svc.AudioProcessingState.idle,
      );
    });
  });
}
