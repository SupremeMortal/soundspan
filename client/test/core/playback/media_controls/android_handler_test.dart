// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:audio_service/audio_service.dart' as svc;
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/media_controls/audio_service_controls.dart';
import 'package:soundspan/core/playback/media_controls/media_controls.dart';
import 'package:soundspan/core/playback/media_controls/media_session_mapper.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../../helpers/fake_clock.dart';
import '../../../helpers/recording_media_command_handler.dart';
import '../queue/queue_test_items.dart';

String _label(bool liked) => liked ? 'Remove like' : 'Like';

QueueItem _trackItem({Preference preference = Preference.neutral}) =>
    QueueItem.track(
      queueItemId: 'q1',
      track: Track(
        meta: const TrackMeta(
          title: 'Song',
          artist: 'Artist',
          album: 'Album',
          durationSec: 200,
        ),
        playbackId: const PlaybackId('pb1'),
        preference: preference,
      ),
      context: testContext,
    );

QueueItem _episodeItem() => const QueueItem.episode(
  queueItemId: 'e1',
  episode: Episode(id: 'ep1', podcastId: 'pod1', title: 'Episode'),
  podcast: Podcast(id: 'pod1', title: 'Podcast'),
);

/// The snapshot of a queue holding only [item], current, [playing].
PlaybackSnapshot _snapshotOf(QueueItem item, {bool playing = true}) {
  final queue = QueueState(items: [item], cursor: 0);
  return PlaybackSnapshot(
    queue: queue,
    current: queue.current,
    status: EngineStatus.ready,
    playing: playing,
  );
}

/// A handler started through [AudioServiceControls] on Android, showing
/// what the mapper makes of a snapshot.
class _Android {
  new() {
    controls = AudioServiceControls(
      config: () => audioServiceConfigFor(
        operatingSystem: 'android',
        channelName: 'Playback',
      ),
      start: (builder, _) async => handler = builder(),
      clock: FakeClock(),
      likeLabel: _label,
    );
  }

  final RecordingMediaCommandHandler commands = RecordingMediaCommandHandler();
  late final AudioServiceControls controls;
  late SoundspanAudioHandler handler;

  Future<void> init() => controls.init(commands);

  /// Initialises inside [async].
  void start(FakeAsync async) {
    unawaited(init());
    async.flushMicrotasks();
  }

  void show(PlaybackSnapshot snapshot) =>
      controls.update(mapSnapshot(snapshot));

  svc.PlaybackState get state => handler.playbackState.value;
}

void main() {
  group('notification actions', () {
    test('a track shows previous, play or pause, next and an outlined '
        'Like; the first three are compact', () async {
      final a = _Android();
      await a.init();

      a.show(_snapshotOf(_trackItem()));

      final controls = a.state.controls;
      expect(controls.take(3), [
        svc.MediaControl.skipToPrevious,
        svc.MediaControl.pause,
        svc.MediaControl.skipToNext,
      ]);
      expect(controls, hasLength(4));
      expect(controls[3].customAction?.name, 'like');
      expect(controls[3].androidIcon, 'drawable/ic_action_like');
      expect(controls[3].label, 'Like');
      expect(a.state.androidCompactActionIndices, [0, 1, 2]);
    });

    test('a liked track shows the filled Like icon', () async {
      final a = _Android();
      await a.init();

      a.show(_snapshotOf(_trackItem(preference: Preference.liked)));

      final like = a.state.controls.last;
      expect(like.customAction?.name, 'like');
      expect(like.androidIcon, 'drawable/ic_action_liked');
      expect(like.label, 'Remove like');
    });

    test('a queue holding a single episode shows skip back, play or pause '
        'and skip forward, and no Like', () async {
      final a = _Android();
      await a.init();

      a.show(_snapshotOf(_episodeItem()));

      expect(a.state.controls, [
        svc.MediaControl.rewind,
        svc.MediaControl.pause,
        svc.MediaControl.fastForward,
      ]);
      expect(a.state.androidCompactActionIndices, [0, 1, 2]);
    });

    test('the system actions follow the session state', () async {
      final a = _Android();
      await a.init();

      a.show(_snapshotOf(_trackItem()));

      expect(a.state.systemActions, {
        svc.MediaAction.seek,
        svc.MediaAction.stop,
      });
    });
  });

  group('customAction', () {
    test('like forwards setLiked once, with the opposite of the shown '
        'preference', () async {
      final a = _Android();
      await a.init();

      a.show(_snapshotOf(_trackItem()));
      await a.handler.customAction('like');
      a.show(_snapshotOf(_trackItem(preference: Preference.liked)));
      await a.handler.customAction('like');

      expect(a.commands.calls, ['setLiked true', 'setLiked false']);
    });

    test('an unknown custom action is ignored', () async {
      final a = _Android();
      await a.init();
      a.show(_snapshotOf(_trackItem()));

      await a.handler.customAction('dislike', {'x': 1});

      expect(a.commands.calls, isEmpty);
    });

    test('like with nothing shown does nothing', () async {
      final a = _Android();
      await a.init();

      await a.handler.customAction('like');

      expect(a.commands.calls, isEmpty);
    });
  });

  group('paused timeout', () {
    test('ten minutes paused stops, ends the service and keeps it ended '
        'until playback starts again', () {
      fakeAsync((async) {
        final a = _Android()
          ..start(async)
          ..show(_snapshotOf(_trackItem(), playing: false));

        async.elapse(const Duration(minutes: 9, seconds: 59));
        expect(a.commands.calls, isEmpty);
        async
          ..elapse(const Duration(seconds: 1))
          ..flushMicrotasks();

        expect(a.commands.calls, ['stop']);
        expect(a.state.processingState, svc.AudioProcessingState.idle);
        expect(a.handler.mediaItem.value, isNull);

        a.show(_snapshotOf(_trackItem(), playing: false));
        expect(a.state.processingState, svc.AudioProcessingState.idle);

        a.show(_snapshotOf(_trackItem()));
        expect(a.state.processingState, svc.AudioProcessingState.ready);
        expect(a.state.playing, isTrue);
      });
    });

    test('nine minutes paused, then play, does not stop', () {
      fakeAsync((async) {
        final a = _Android()
          ..start(async)
          ..show(_snapshotOf(_trackItem(), playing: false));

        async.elapse(const Duration(minutes: 9));
        unawaited(a.handler.play());
        async
          ..elapse(const Duration(minutes: 5))
          ..flushMicrotasks();

        expect(a.commands.calls, ['play']);
      });
    });

    test('playing again restarts the count from zero', () {
      fakeAsync((async) {
        final a = _Android()
          ..start(async)
          ..show(_snapshotOf(_trackItem(), playing: false));
        async.elapse(const Duration(minutes: 9));
        a
          ..show(_snapshotOf(_trackItem()))
          ..show(_snapshotOf(_trackItem(), playing: false));

        async
          ..elapse(const Duration(minutes: 9))
          ..flushMicrotasks();
        expect(a.commands.calls, isEmpty);

        async
          ..elapse(const Duration(minutes: 1))
          ..flushMicrotasks();
        expect(a.commands.calls, ['stop']);
      });
    });

    test('nothing current starts no timer', () {
      fakeAsync((async) {
        final a = _Android()..start(async);
        a.controls.update(MediaSessionState.empty);

        async
          ..elapse(const Duration(minutes: 30))
          ..flushMicrotasks();

        expect(a.commands.calls, isEmpty);
      });
    });
  });
}
