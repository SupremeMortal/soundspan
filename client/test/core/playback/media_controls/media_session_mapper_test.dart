// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/media_controls/media_controls.dart';
import 'package:soundspan/core/playback/media_controls/media_session_mapper.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../queue/queue_test_items.dart';

QueueItem _episode(String id) => QueueItem.episode(
  queueItemId: id,
  episode: const Episode(
    id: 'e1',
    podcastId: 'pod1',
    title: 'The Episode',
    durationSec: 600,
  ),
  podcast: const Podcast(id: 'pod1', title: 'The Podcast'),
);

PlaybackSnapshot _snapshot(
  List<QueueItem> items, {
  bool playing = true,
  EngineStatus status = EngineStatus.ready,
  Duration position = const Duration(seconds: 7),
  Duration? duration,
}) {
  final queue = QueueState(items: items, cursor: items.isEmpty ? null : 0);
  return PlaybackSnapshot(
    queue: queue,
    current: queue.current,
    status: status,
    playing: playing,
    position: position,
    duration: duration,
  );
}

void main() {
  test('nothing current maps to the empty state', () {
    expect(mapSnapshot(PlaybackSnapshot.initial), MediaSessionState.empty);
    expect(MediaSessionState.empty.actions, isEmpty);
    expect(MediaSessionState.empty.queueItemId, isNull);
  });

  test('a playing track offers pause, seek, stop, next and previous', () {
    expect(mapSnapshot(_snapshot([trackItem('a')])).actions, {
      MediaAction.pause,
      MediaAction.seek,
      MediaAction.stop,
      MediaAction.next,
      MediaAction.previous,
    });
  });

  test('a paused track offers play instead of pause', () {
    expect(mapSnapshot(_snapshot([trackItem('a')], playing: false)).actions, {
      MediaAction.play,
      MediaAction.seek,
      MediaAction.stop,
      MediaAction.next,
      MediaAction.previous,
    });
  });

  test('a track shows its metadata, position and the artwork given', () {
    final artwork = Uri.parse('file:///art/now-playing.img');
    final state = mapSnapshot(
      _snapshot([trackItem('a')]),
      artworkUri: artwork,
      skipInterval: const Duration(seconds: 30),
    );
    expect(state.queueItemId, 'a');
    expect(state.title, 'Song a');
    expect(state.artist, 'Band');
    expect(state.album, 'Record');
    expect(state.duration, const Duration(seconds: 180));
    expect(state.artworkUri, artwork);
    expect(state.position, const Duration(seconds: 7));
    expect(state.playing, isTrue);
    expect(state.speed, 1.0);
    expect(state.skipInterval, const Duration(seconds: 30));
  });

  test('an episode reports the snapshot speed and skip interval', () {
    final queue = QueueState(items: [_episode('e')], cursor: 0);
    final state = mapSnapshot(
      PlaybackSnapshot(
        queue: queue,
        current: queue.current,
        status: EngineStatus.ready,
        playing: true,
        speed: 1.5,
        skipInterval: const Duration(seconds: 45),
      ),
    );
    expect(state.speed, 1.5);
    expect(state.skipInterval, const Duration(seconds: 45));
    expect(state.actions, contains(MediaAction.skipForward));
    expect(state.actions, isNot(contains(MediaAction.next)));
  });

  test('the engine duration wins over the metadata once known', () {
    final state = mapSnapshot(
      _snapshot([trackItem('a')], duration: const Duration(seconds: 181)),
    );
    expect(state.duration, const Duration(seconds: 181));
  });

  test('a single episode offers skip intervals and not next or '
      'previous', () {
    final state = mapSnapshot(_snapshot([_episode('e')]));
    expect(state.title, 'The Episode');
    expect(state.artist, 'The Podcast');
    expect(state.album, '');
    expect(state.duration, const Duration(seconds: 600));
    expect(state.actions, {
      MediaAction.pause,
      MediaAction.seek,
      MediaAction.stop,
      MediaAction.skipForward,
      MediaAction.skipBackward,
    });
  });

  test('an episode in a longer queue offers skips and next and '
      'previous', () {
    final state = mapSnapshot(_snapshot([_episode('e'), trackItem('a')]));
    expect(
      state.actions,
      containsAll([
        MediaAction.skipForward,
        MediaAction.skipBackward,
        MediaAction.next,
        MediaAction.previous,
      ]),
    );
  });

  test('like is never offered', () {
    for (final snapshot in [
      _snapshot([trackItem('a')]),
      _snapshot([trackItem('a')], playing: false),
      _snapshot([_episode('e')]),
      _snapshot([_episode('e'), trackItem('a')]),
    ]) {
      expect(mapSnapshot(snapshot).actions, isNot(contains(MediaAction.like)));
    }
  });

  test('buffering reflects the engine status', () {
    bool buffering(EngineStatus status) =>
        mapSnapshot(_snapshot([trackItem('a')], status: status)).buffering;
    expect(buffering(EngineStatus.buffering), isTrue);
    expect(buffering(EngineStatus.loading), isTrue);
    expect(buffering(EngineStatus.ready), isFalse);
    expect(buffering(EngineStatus.ended), isFalse);
  });

  test('the artwork of an episode falls back to its podcast', () {
    const episode = QueueItem.episode(
      queueItemId: 'e',
      episode: Episode(id: 'e1', podcastId: 'p', title: 'E'),
      podcast: Podcast(id: 'p', title: 'P', artworkRef: 'pod-art'),
    );
    expect(artworkRefOf(episode), 'pod-art');
    expect(artworkRefOf(trackItem('a')), isNull);
  });
}
