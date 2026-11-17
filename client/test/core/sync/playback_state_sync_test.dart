// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/persistence.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/state_sync_binding.dart';
import 'package:soundspan/core/storage/state/queue_dao.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/data/playback_state_repository.dart';
import 'package:soundspan/core/sync/playback_state.dart';
import 'package:soundspan/core/sync/playback_state_sync.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../helpers/fake_reachability.dart';
import '../playback/controller/controller_harness.dart';
import '../playback/queue/queue_test_items.dart';

/// A [Clock] that reads the virtual time of [_async].
class _FakeAsyncClock implements Clock {
  new(this._async);

  final FakeAsync _async;

  @override
  DateTime now() => _async.getClock(DateTime.utc(2025)).now().toUtc();
}

/// One request the fake server received: when, and its JSON body.
typedef _Post = ({Duration at, Map<String, Object?> body});

/// The playback-state endpoints of the server, in memory.
class _FakePlaybackClient implements api.PlaybackClient {
  new(this._now);

  final Duration Function() _now;

  /// Every `POST /playback-state`, in order.
  final List<_Post> posts = [];

  /// When each `DELETE /playback-state` was made.
  final List<Duration> deletes = [];

  /// How many `GET /playback-state` were made.
  int gets = 0;

  /// The state `GET` answers, as JSON; none when null.
  Map<String, Object?>? stored;

  /// What `GET` throws instead of answering.
  Exception? getError;

  /// When set, every write waits for it.
  Completer<void>? gate;

  /// Whether writes fail with a server error.
  bool fail = false;

  int _inFlight = 0;

  /// The most requests ever in flight at once.
  int maxInFlight = 0;

  Future<void> _write() async {
    _inFlight++;
    if (_inFlight > maxInFlight) maxInFlight = _inFlight;
    try {
      if (gate case final gate?) await gate.future;
      if (fail) throw const api.ServerError(status: 500);
    } finally {
      _inFlight--;
    }
  }

  @override
  Future<api.PlaybackState?> savePlaybackState({
    required api.SavePlaybackStateRequest body,
    Map<String, Object?> extra = const {},
    Object? cancelToken,
    Object? options,
  }) async {
    posts.add((
      at: _now(),
      body: jsonDecode(jsonEncode(body)) as Map<String, Object?>,
    ));
    await _write();
    return null;
  }

  @override
  Future<api.ClearPlaybackStateResponse> clearPlaybackState({
    Map<String, Object?> extra = const {},
    Object? cancelToken,
    Object? options,
  }) async {
    deletes.add(_now());
    await _write();
    return api.ClearPlaybackStateResponse.fromJson({'success': true});
  }

  @override
  Future<api.PlaybackState?> getPlaybackState({
    Map<String, Object?> extra = const {},
    Object? cancelToken,
    Object? options,
  }) async {
    gets++;
    if (getError case final error?) throw error;
    final state = stored;
    return state == null ? null : api.PlaybackState.fromJson(state);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The ids every rig can play, each five minutes long.
final List<String> _playable = [
  'a',
  'b',
  'c',
  'd',
  'e',
  'x1',
  'x2',
  'x3',
  'ep',
];

/// A controller and its [PlaybackStateSync], driven in fake time.
class _Rig {
  new(
    this.async, {
    QueuePersistence? persistence,
    void Function(_FakePlaybackClient client)? server,
  }) {
    client = _FakePlaybackClient(() => async.elapsed);
    server?.call(client);
    sync = PlaybackStateSync(
      repository: PlaybackStateRepository(client),
      reachability: reachability,
      lifecycle: lifecycle.stream,
    );
    h = ControllerHarness(
      clock: _FakeAsyncClock(async),
      persistence: persistence,
      remoteRestore: () async {
        final remote = await sync.restore();
        return remote == null ? null : restoredQueueOf(remote);
      },
    );
    for (final id in _playable) {
      h.fake.sources[uriOf(id)] = const FakeSource(
        duration: Duration(minutes: 5),
      );
    }
    settle(controller.restore());
    sync.follow(controller.snapshots.map(syncedPlaybackOf));
    async.flushMicrotasks();
  }

  final FakeAsync async;
  late final _FakePlaybackClient client;
  final FakeReachability reachability = FakeReachability();
  final StreamController<AppLifecycleState> lifecycle =
      StreamController<AppLifecycleState>.broadcast(sync: true);
  late final PlaybackStateSync sync;
  late final ControllerHarness h;

  PlaybackController get controller => h.controller;

  /// Settles [future] in fake time without letting time pass.
  T settle<T>(Future<T> future) {
    late T value;
    var done = false;
    unawaited(
      future.then((v) {
        value = v;
        done = true;
      }),
    );
    async.flushMicrotasks();
    expect(done, isTrue, reason: 'the future did not complete');
    return value;
  }

  /// Lets [d] of playback pass on the engine and in fake time.
  void play(Duration d) {
    var left = d;
    const step = FakeEngine.positionInterval;
    while (left > Duration.zero) {
      final move = left < step ? left : step;
      h.fake.advance(move);
      async.elapse(move);
      left -= move;
    }
  }

  /// Plays [items] from [startIndex] and forgets the requests it caused.
  void start(List<QueueItem> items, {int startIndex = 0}) {
    settle(controller.playItems(items, startIndex: startIndex));
    async.flushMicrotasks();
    client.posts.clear();
  }

  /// The seconds of fake time at which each post was made.
  List<int> get postSeconds => [
    for (final post in client.posts) post.at.inSeconds,
  ];

  /// The latest body posted.
  Map<String, Object?> get lastBody => client.posts.last.body;

  void dispose() {
    unawaited(sync.dispose());
    unawaited(controller.dispose());
    async.elapse(const Duration(seconds: 1));
  }
}

/// Runs [body] in fake time.
void _inFakeTime(void Function(FakeAsync async) body) {
  fakeAsync((async) {
    body(async);
    async.flushMicrotasks();
  });
}

/// An episode entry with id [queueItemId].
QueueItem _episode(String queueItemId) => QueueItem.episode(
  queueItemId: queueItemId,
  episode: const Episode(
    id: 'e1',
    podcastId: 'pod1',
    title: 'Episode',
    durationSec: 600,
  ),
  podcast: const Podcast(id: 'pod1', title: 'Podcast', artworkRef: 'cover'),
);

/// A track entry that has no playback id.
QueueItem _unplayable(String queueItemId) => QueueItem.track(
  queueItemId: queueItemId,
  track: const Track(
    meta: TrackMeta(
      title: 'Gone',
      artist: 'Band',
      album: 'Record',
      durationSec: 1,
    ),
  ),
  context: testContext,
);

/// [items] as a playback view with the cursor at [cursor].
SyncedPlayback _view(
  List<QueueItem> items, {
  required int cursor,
  List<int>? shuffleOrder,
}) => SyncedPlayback(
  items: items,
  shuffleOrder: shuffleOrder,
  cursor: cursor,
  revision: 1,
);

/// The playback ids of a window's track entries.
List<String?> _windowIds(List<PlaybackStateEntry> entries) => [
  for (final entry in entries)
    switch (entry) {
      TrackStateEntry(:final playbackId) => playbackId?.value,
      EpisodeStateEntry(:final episodeId) => episodeId,
    },
];

/// A stored track queue item as `GET /playback-state` answers it.
Map<String, Object?> _wireTrack(String playbackId) => {
  'itemType': 'track',
  'id': 'library-$playbackId',
  'playbackId': playbackId,
  'title': 'Song $playbackId',
  'duration': 180,
  'artist': {'id': 'ar-1', 'name': 'Band'},
  'album': {'id': 'al-1', 'title': 'Record', 'coverArt': null},
};

/// A stored episode queue item as `GET /playback-state` answers it.
Map<String, Object?> _wireEpisode() => {
  'itemType': 'episode',
  'id': 'pod-1:ep-1',
  'episodeId': 'ep-1',
  'podcastId': 'pod-1',
  'title': 'Episode one',
  'podcastTitle': 'The Show',
  'duration': 1800,
};

/// A stored state as `GET /playback-state` answers it.
Map<String, Object?> _wireState(
  List<Map<String, Object?>> queue, {
  int currentIndex = 0,
  double currentTime = 0,
  bool isShuffle = false,
}) => {
  'userId': 'u-1',
  'deviceId': 'device-1',
  'playbackType': 'track',
  'trackId': null,
  'audiobookId': null,
  'podcastId': null,
  'queue': queue,
  'currentIndex': currentIndex,
  'isShuffle': isShuffle,
  'isPlaying': true,
  'currentTime': currentTime,
  'updatedAt': '2025-01-01T12:00:00.000Z',
  'createdAt': '2025-01-01T11:00:00.000Z',
};

void main() {
  group('triggers', () {
    test('cadence: playing for 46 s posts at 15, 30 and 45 s; nothing '
        'while paused', () {
      _inFakeTime((async) {
        final rig = _Rig(async)..start(trackItems(['a', 'b']));
        final started = async.elapsed.inSeconds;
        rig.play(const Duration(seconds: 46));
        expect([for (final s in rig.postSeconds) s - started], [15, 30, 45]);
        expect(rig.lastBody['isPlaying'], isTrue);

        rig.settle(rig.controller.pause());
        rig.client.posts.clear();
        async.elapse(const Duration(seconds: 60));
        expect(rig.client.posts, isEmpty);
        rig.dispose();
      });
    });

    test('pause posts once immediately with isPlaying false', () {
      _inFakeTime((async) {
        final rig = _Rig(async)
          ..start(trackItems(['a', 'b']))
          ..play(const Duration(seconds: 3));
        rig.settle(rig.controller.pause());
        async.flushMicrotasks();
        expect(rig.client.posts, hasLength(1));
        expect(rig.lastBody['isPlaying'], isFalse);
        expect(rig.lastBody['currentTime'], closeTo(3, 0.3));
        rig.dispose();
      });
    });

    test('track change posts immediately', () {
      _inFakeTime((async) {
        final rig = _Rig(async)..start(trackItems(['a', 'b']));
        rig.settle(rig.controller.next());
        async.flushMicrotasks();
        expect(rig.client.posts, hasLength(1));
        expect(rig.lastBody['playbackId'], 'pb-b');
        expect(rig.lastBody['currentIndex'], 1);
        rig.dispose();
      });
    });

    test('queue edits: three edits within 2 s give one post 2 s after the '
        'last', () {
      _inFakeTime((async) {
        final rig = _Rig(async)..start(trackItems(['a', 'b']));
        rig.settle(rig.controller.pause());
        rig.client.posts.clear();
        rig.settle(rig.controller.append([trackItem('x1')]));
        async.elapse(const Duration(milliseconds: 600));
        rig.settle(rig.controller.append([trackItem('x2')]));
        async.elapse(const Duration(milliseconds: 600));
        rig.settle(rig.controller.append([trackItem('x3')]));
        final last = async.elapsed;
        async.elapse(const Duration(milliseconds: 1900));
        expect(rig.client.posts, isEmpty);
        async.elapse(const Duration(milliseconds: 200));
        expect(rig.client.posts, hasLength(1));
        expect(rig.client.posts.single.at - last, const Duration(seconds: 2));
        expect(rig.lastBody['queue'], hasLength(5));
        rig.dispose();
      });
    });

    test('a cursor-only change is not treated as an edit', () {
      _inFakeTime((async) {
        final rig = _Rig(async)..start(trackItems(['a', 'b', 'c']));
        rig.settle(rig.controller.pause());
        rig.client.posts.clear();
        rig.settle(rig.controller.next());
        async.elapse(const Duration(seconds: 5));
        // The track change posts once; no debounced edit post follows.
        expect(rig.client.posts, hasLength(1));
        rig.dispose();
      });
    });

    test('background posts immediately', () {
      _inFakeTime((async) {
        final rig = _Rig(async)
          ..start(trackItems(['a', 'b']))
          ..play(const Duration(seconds: 4));
        rig.lifecycle.add(AppLifecycleState.paused);
        async.flushMicrotasks();
        expect(rig.client.posts, hasLength(1));
        expect(rig.lastBody['isPlaying'], isTrue);
        rig.dispose();
      });
    });

    test('single in-flight: two triggers during a slow request give exactly '
        'one follow-up carrying the newest state', () {
      _inFakeTime((async) {
        final rig = _Rig(async)..start(trackItems(['a', 'b', 'c']));
        final gate = rig.client.gate = Completer<void>();
        rig.settle(rig.controller.pause());
        expect(rig.client.posts, hasLength(1));
        rig.lifecycle.add(AppLifecycleState.paused);
        rig.settle(rig.controller.next());
        async.elapse(const Duration(seconds: 3));
        expect(rig.client.posts, hasLength(1));

        rig.client.gate = null;
        gate.complete();
        async.flushMicrotasks();
        expect(rig.client.posts, hasLength(2));
        expect(rig.lastBody['playbackId'], 'pb-b');
        expect(rig.client.maxInFlight, 1);
        async.elapse(const Duration(seconds: 5));
        expect(rig.client.posts, hasLength(2));
        rig.dispose();
      });
    });

    test('failure: a failed post is not retried until the next trigger', () {
      _inFakeTime((async) {
        final rig = _Rig(async)..start(trackItems(['a', 'b']));
        rig.client.fail = true;
        rig.settle(rig.controller.pause());
        async.elapse(const Duration(minutes: 2));
        expect(rig.client.posts, hasLength(1));

        rig.client.fail = false;
        rig.lifecycle.add(AppLifecycleState.paused);
        async.flushMicrotasks();
        expect(rig.client.posts, hasLength(2));
        rig.dispose();
      });
    });

    test('offline: nothing is sent, and one post with the latest state goes '
        'out on return to online', () {
      _inFakeTime((async) {
        final rig = _Rig(async)..start(trackItems(['a', 'b', 'c']));
        rig.reachability.set(Reachability.noNetwork);
        rig.play(const Duration(seconds: 20));
        rig.settle(rig.controller.pause());
        rig.settle(rig.controller.next());
        rig.lifecycle.add(AppLifecycleState.paused);
        async.elapse(const Duration(seconds: 5));
        expect(rig.client.posts, isEmpty);

        rig.reachability.set(Reachability.online);
        async.flushMicrotasks();
        expect(rig.client.posts, hasLength(1));
        expect(rig.lastBody['playbackId'], 'pb-b');
        expect(rig.lastBody['isPlaying'], isFalse);
        rig.reachability
          ..set(Reachability.serverUnreachable)
          ..set(Reachability.online);
        async.flushMicrotasks();
        expect(rig.client.posts, hasLength(1));
        rig.dispose();
      });
    });

    test('empty queue sends DELETE and no post', () {
      _inFakeTime((async) {
        final rig = _Rig(async)..start(trackItems(['a', 'b']));
        rig.settle(rig.controller.clear());
        async.elapse(const Duration(seconds: 5));
        expect(rig.client.deletes, hasLength(1));
        expect(rig.client.posts, isEmpty);
        rig.dispose();
      });
    });
  });

  group('window', () {
    final items = trackItems(numberedIds(500));

    test('cursor at 0 of 500 sends 80 items with currentIndex 0', () {
      final (entries, index) = windowOf(_view(items, cursor: 0));
      expect(entries, hasLength(80));
      expect(index, 0);
      expect(_windowIds(entries).first, 'pb-p0');
    });

    test('cursor at 250 sends 100 items with currentIndex 20', () {
      final (entries, index) = windowOf(_view(items, cursor: 250));
      expect(entries, hasLength(100));
      expect(index, 20);
      expect(_windowIds(entries)[index], 'pb-p250');
      expect(_windowIds(entries).first, 'pb-p230');
      expect(_windowIds(entries).last, 'pb-p329');
    });

    test('cursor at 495 of 500 sends 20 before plus the rest', () {
      final (entries, index) = windowOf(_view(items, cursor: 495));
      expect(entries, hasLength(25));
      expect(index, 20);
      expect(_windowIds(entries).last, 'pb-p499');
    });

    test('a 50-item queue is sent whole', () {
      final (entries, index) = windowOf(
        _view(trackItems(numberedIds(50)), cursor: 20),
      );
      expect(entries, hasLength(50));
      expect(index, 20);
    });

    test('with shuffle on the window follows shuffleOrder', () {
      final order = [for (var i = 499; i >= 0; i--) i];
      final (entries, index) = windowOf(
        _view(items, cursor: 0, shuffleOrder: order),
      );
      expect(entries, hasLength(80));
      expect(index, 0);
      expect(_windowIds(entries).take(3), ['pb-p499', 'pb-p498', 'pb-p497']);
    });

    test('an unplayable item is omitted and the index adjusted', () {
      final (entries, index) = windowOf(
        _view([
          trackItem('a'),
          _unplayable('gone'),
          trackItem('b'),
          trackItem('c'),
        ], cursor: 2),
      );
      expect(_windowIds(entries), ['pb-a', 'pb-b', 'pb-c']);
      expect(index, 1);
    });
  });

  group('body', () {
    test('of a track as current item', () {
      _inFakeTime((async) {
        final rig = _Rig(async)
          ..start(trackItems(['a', 'b', 'c']), startIndex: 1)
          ..play(const Duration(seconds: 2));
        rig.settle(rig.controller.pause());
        async.flushMicrotasks();
        final body = rig.lastBody;
        expect(body['playbackType'], 'track');
        expect(body['playbackId'], 'pb-b');
        expect(
          body.containsKey('podcastId') ? body['podcastId'] : null,
          isNull,
        );
        expect(body['currentIndex'], 1);
        expect(body['currentTime'], closeTo(2, 0.3));
        expect(body['isShuffle'], isFalse);
        expect(body['isPlaying'], isFalse);
        final queue = body['queue']! as List<Object?>;
        expect(queue, hasLength(3));
        expect(queue.first, {
          'itemType': 'track',
          'playbackId': 'pb-a',
          'metadata': {
            'title': 'Song a',
            'artist': 'Band',
            'album': 'Record',
            'durationSec': 180,
          },
        });
        rig.dispose();
      });
    });

    test('of an episode as current item', () {
      _inFakeTime((async) {
        final rig = _Rig(async)..start([_episode('ep'), trackItem('a')]);
        rig.settle(rig.controller.pause());
        async.flushMicrotasks();
        final body = rig.lastBody;
        expect(body['playbackType'], 'podcast');
        expect(body['podcastId'], 'pod1');
        expect(
          body.containsKey('playbackId') ? body['playbackId'] : null,
          isNull,
        );
        expect(body['currentIndex'], 0);
        final queue = body['queue']! as List<Object?>;
        expect(queue.first, {
          'itemType': 'episode',
          'id': 'pod1:e1',
          'episodeId': 'e1',
          'podcastId': 'pod1',
          'title': 'Episode',
          'podcastTitle': 'Podcast',
          'duration': 600,
          'coverUrl': 'cover',
        });
        rig.dispose();
      });
    });
  });

  group('restore', () {
    /// A rig over a fresh, empty `state.db`, with the server scripted by
    /// [server].
    (_Rig, StateDatabase) emptyStore(
      FakeAsync async,
      void Function(_FakePlaybackClient client) server,
    ) {
      final db = StateDatabase(NativeDatabase.memory());
      final rig = _Rig(
        async,
        persistence: QueuePersistence(
          dao: QueueDao(db),
          clock: _FakeAsyncClock(async),
        ),
        server: server,
      );
      return (rig, db);
    }

    void close(_Rig rig, StateDatabase db) {
      rig.dispose();
      unawaited(db.close());
      rig.async.flushMicrotasks();
    }

    test('without a local snapshot rebuilds items, cursor and position, '
        'paused, with identity shuffleOrder when isShuffle', () {
      _inFakeTime((async) {
        final (rig, db) = emptyStore(async, (client) {
          client.stored = _wireState(
            [_wireTrack('p1'), _wireTrack('p2'), _wireTrack('p3')],
            currentIndex: 1,
            currentTime: 12.5,
            isShuffle: true,
          );
        });
        final snapshot = rig.controller.snapshot;
        expect(rig.client.gets, 1);
        expect(
          [
            for (final item in snapshot.queue.items)
              (item as TrackQueueItem).track.playbackId?.value,
          ],
          ['p1', 'p2', 'p3'],
        );
        expect(snapshot.queue.cursor, 1);
        expect(snapshot.queue.shuffleOrder, [0, 1, 2]);
        expect(snapshot.position, const Duration(milliseconds: 12500));
        expect(snapshot.playing, isFalse);
        expect(snapshot.status.name, 'idle');
        expect(rig.client.posts, isEmpty);
        close(rig, db);
      });
    });

    test('is skipped (no GET) when a local snapshot exists', () {
      _inFakeTime((async) {
        final db = StateDatabase(NativeDatabase.memory());
        final first = _Rig(
          async,
          persistence: QueuePersistence(
            dao: QueueDao(db),
            clock: _FakeAsyncClock(async),
          ),
        )..start(trackItems(['a', 'b']));
        async.elapse(const Duration(seconds: 1));
        first.dispose();

        final second = _Rig(
          async,
          persistence: QueuePersistence(
            dao: QueueDao(db),
            clock: _FakeAsyncClock(async),
          ),
        );
        expect(second.client.gets, 0);
        expect(idsOf(second.controller.snapshot.queue.items), ['a', 'b']);
        close(second, db);
      });
    });

    for (final (name, script) in <(String, void Function(_FakePlaybackClient))>[
      ('a null answer', (client) => client.stored = null),
      (
        'an error',
        (client) => client.getError = const api.ServerError(status: 500),
      ),
      ('an empty queue', (client) => client.stored = _wireState(const [])),
    ]) {
      test('with $name yields no queue', () {
        _inFakeTime((async) {
          final (rig, db) = emptyStore(async, script);
          expect(rig.client.gets, 1);
          expect(rig.controller.snapshot.queue.items, isEmpty);
          close(rig, db);
        });
      });
    }

    test('skips episode items; a skipped current item moves the cursor to '
        'the first remaining item at position zero', () {
      _inFakeTime((async) {
        final (rig, db) = emptyStore(async, (client) {
          client.stored = _wireState([
            _wireEpisode(),
            _wireTrack('p1'),
            _wireTrack('p2'),
          ], currentTime: 300);
        });
        final snapshot = rig.controller.snapshot;
        expect(snapshot.queue.items, hasLength(2));
        expect(snapshot.queue.cursor, 0);
        expect(snapshot.queue.shuffleOrder, isNull);
        expect(
          (snapshot.current! as TrackQueueItem).track.playbackId?.value,
          'p1',
        );
        expect(snapshot.position, Duration.zero);
        close(rig, db);
      });
    });
  });
}
