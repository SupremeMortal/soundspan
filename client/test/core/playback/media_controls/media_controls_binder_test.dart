// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/media_controls/media_controls.dart';
import 'package:soundspan/core/playback/media_controls/media_controls_binder.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../../helpers/fake_clock.dart';
import '../../../helpers/fake_media_controls.dart';
import '../controller/controller_harness.dart';
import '../queue/queue_test_items.dart';

/// A track entry [id] whose cover is `art-<id>`.
QueueItem _track(String id) => QueueItem.track(
  queueItemId: id,
  track: Track(
    meta: TrackMeta(
      title: 'Song $id',
      artist: 'Band',
      album: 'Record',
      durationSec: 60,
      artworkRef: 'art-$id',
    ),
    playbackId: PlaybackId('pb-$id'),
  ),
  context: testContext,
);

/// Pins artwork as `file:///art/<ref>`, each pin waiting for the test to
/// complete it.
class _Pins {
  final Map<String, Completer<Uri?>> pending = {};

  Future<Uri?> pin(String? ref) {
    final completer = Completer<Uri?>();
    pending[ref ?? ''] = completer;
    return completer.future;
  }

  void complete(String ref) =>
      pending.remove(ref)!.complete(Uri.parse('file:///art/$ref'));
}

/// A controller over 60-second sources rendered on [controls].
class _Rig {
  new({LikeTrack? like}) {
    for (final id in ['a', 'b', 'c']) {
      h.fake.sources[uriOf(id)] = const FakeSource(
        duration: Duration(seconds: 60),
      );
    }
    binder = MediaControlsBinder(
      controller: h.controller,
      controls: controls,
      pin: pins.pin,
      clock: h.clock,
      like: like,
    );
  }

  final ControllerHarness h = ControllerHarness();
  final FakeMediaControls controls = FakeMediaControls();
  final _Pins pins = _Pins();
  late final MediaControlsBinder binder;

  /// Plays a, b and c and lets the first item's artwork arrive.
  Future<void> start() async {
    await h.controller.playItems([_track('a'), _track('b'), _track('c')]);
    await h.settle();
    pins.complete('art-a');
    await h.settle();
  }
}

void main() {
  test('a new current item is sent at once without artwork, then again '
      'with the pinned artwork', () async {
    final r = _Rig();
    addTearDown(r.binder.dispose);
    await r.h.settle();
    expect(r.controls.updates, [MediaSessionState.empty]);

    await r.h.controller.playItems([_track('a'), _track('b')]);
    await r.h.settle();
    final first = r.controls.updates.firstWhere((s) => s.queueItemId == 'a');
    expect(first.title, 'Song a');
    expect(first.artworkUri, isNull);
    expect(r.controls.last!.artworkUri, isNull);

    r.pins.complete('art-a');
    await r.h.settle();
    expect(r.controls.last!.queueItemId, 'a');
    expect(r.controls.last!.artworkUri, Uri.parse('file:///art/art-a'));

    await r.h.controller.next();
    await r.h.settle();
    final second = r.controls.updates.firstWhere((s) => s.queueItemId == 'b');
    expect(second.artworkUri, isNull, reason: 'the old artwork is cleared');
  });

  test('a pin that completes after the item changed is not sent', () async {
    final r = _Rig();
    addTearDown(r.binder.dispose);
    await r.h.controller.playItems([_track('a'), _track('b')]);
    await r.h.settle();
    await r.h.controller.next();
    await r.h.settle();
    final count = r.controls.updates.length;

    r.pins.complete('art-a');
    await r.h.settle();

    expect(r.controls.updates, hasLength(count));
    expect(r.controls.updates.where((s) => s.artworkUri != null), isEmpty);
  });

  test('pause and resume each send one update', () async {
    final r = _Rig();
    addTearDown(r.binder.dispose);
    await r.start();
    await r.h.play(const Duration(seconds: 1));
    var count = r.controls.updates.length;

    await r.h.controller.pause();
    await r.h.settle();
    expect(r.controls.updates, hasLength(count + 1));
    expect(r.controls.last!.playing, isFalse);
    expect(r.controls.last!.actions, contains(MediaAction.play));
    count = r.controls.updates.length;

    await r.h.controller.play();
    await r.h.settle();
    expect(r.controls.updates, hasLength(count + 1));
    expect(r.controls.last!.playing, isTrue);
  });

  test('ten seconds of steady playback send no further updates', () async {
    final r = _Rig();
    addTearDown(r.binder.dispose);
    await r.start();
    await r.h.play(const Duration(milliseconds: 400));
    final count = r.controls.updates.length;

    await r.h.play(const Duration(seconds: 10));

    expect(r.controls.updates, hasLength(count));
  });

  test('a seek sends one update with the new position', () async {
    final r = _Rig();
    addTearDown(r.binder.dispose);
    await r.start();
    await r.h.play(const Duration(seconds: 1));
    final count = r.controls.updates.length;

    await r.h.controller.seek(const Duration(seconds: 30));
    // The controller publishes position-only changes at most every 250 ms.
    await r.h.play(const Duration(milliseconds: 400));

    expect(r.controls.updates, hasLength(count + 1));
    expect(
      r.controls.last!.position.inMilliseconds,
      inInclusiveRange(30000, 30400),
    );
  });

  test('a stall sends the position once it lags by more than the '
      'tolerance', () async {
    final r = _Rig();
    addTearDown(r.binder.dispose);
    await r.start();
    await r.h.play(const Duration(seconds: 1));
    final count = r.controls.updates.length;
    // The clock moves on while the engine does not.
    (r.h.clock as FakeClock).advance(const Duration(seconds: 2));
    await r.h.play(const Duration(milliseconds: 200));

    expect(r.controls.updates, hasLength(count + 1));
  });

  test('the handler commands reach the controller', () async {
    final r = _Rig();
    addTearDown(r.binder.dispose);
    await r.start();
    final c = r.h.controller;

    await r.binder.pause();
    expect(c.snapshot.playing, isFalse);
    await r.binder.play();
    expect(c.snapshot.playing, isTrue);
    await r.binder.next();
    expect(c.snapshot.current?.queueItemId, 'b');
    await r.binder.previous();
    expect(c.snapshot.current?.queueItemId, 'a');
    await r.binder.seek(const Duration(seconds: 2));
    expect(r.h.calls, contains('seek(${const Duration(seconds: 2)})'));
    await r.binder.setLiked(true);
    await r.binder.stop();
    await r.h.settle();
    expect(c.snapshot.playing, isFalse);
    expect(c.snapshot.status, EngineStatus.idle);
  });

  test('setLiked likes the current track, shows it liked at once, and '
      'forgets the override when the item changes', () async {
    final calls = <(String?, bool)>[];
    final r = _Rig(
      like: (track, {required liked}) async =>
          calls.add((track.playbackId?.value, liked)),
    );
    addTearDown(r.binder.dispose);
    await r.start();
    expect(r.controls.updates.last.liked, isFalse);

    await r.binder.setLiked(true);
    await r.h.settle();

    expect(calls, [('pb-a', true)]);
    expect(r.controls.updates.last.liked, isTrue);
    expect(r.controls.updates.last.queueItemId, 'a');

    await r.binder.next();
    await r.h.settle();
    expect(r.controls.updates.last.queueItemId, 'b');
    expect(r.controls.updates.last.liked, isFalse);
  });

  test('setLiked on an episode, or with nothing to like through, does '
      'nothing', () async {
    final calls = <bool>[];
    final r = _Rig(like: (_, {required liked}) async => calls.add(liked));
    addTearDown(r.binder.dispose);
    const episode = QueueItem.episode(
      queueItemId: 'e',
      episode: Episode(id: 'e1', podcastId: 'p', title: 'E'),
      podcast: Podcast(id: 'p', title: 'P'),
    );
    r.h.fake.sources[uriOf('e')] = const FakeSource(
      duration: Duration(seconds: 60),
    );
    await r.h.controller.playItems([episode]);
    await r.h.settle();
    final sent = r.controls.updates.length;

    await r.binder.setLiked(true);

    expect(calls, isEmpty);
    expect(r.controls.updates, hasLength(sent));
  });

  test('a failing like is logged and keeps the shown state', () async {
    final r = _Rig(like: (_, {required liked}) async => throw StateError('x'));
    addTearDown(r.binder.dispose);
    await r.start();

    await r.binder.setLiked(true);

    expect(r.controls.updates.last.liked, isTrue);
  });

  test('skip forward and back move by the interval and clamp at both '
      'ends', () async {
    final r = _Rig();
    addTearDown(r.binder.dispose);
    await r.start();
    await r.h.play(const Duration(seconds: 3));
    await r.h.controller.pause();
    await r.h.settle();
    final at = r.h.controller.snapshot.position;

    await r.binder.skipForward();
    expect(r.h.calls.last, 'seek(${at + const Duration(seconds: 15)})');

    await r.binder.seek(const Duration(seconds: 50));
    await r.h.settle();
    await r.binder.skipForward();
    expect(r.h.calls.last, 'seek(${const Duration(seconds: 60)})');

    await r.binder.seek(const Duration(seconds: 5));
    await r.h.settle();
    await r.binder.skipBackward();
    expect(r.h.calls.last, 'seek(${Duration.zero})');
  });

  test('an item without a cover is not pinned', () async {
    final r = _Rig();
    addTearDown(r.binder.dispose);
    await r.h.controller.playItems(trackItems(['a']));
    await r.h.settle();

    expect(r.pins.pending, isEmpty);
    expect(r.controls.last!.queueItemId, 'a');
    expect(r.controls.last!.artworkUri, isNull);
  });

  test('a disposed binder sends nothing more', () async {
    final r = _Rig();
    await r.h.controller.playItems([_track('a')]);
    await r.h.settle();
    await r.binder.dispose();
    final count = r.controls.updates.length;

    r.pins.complete('art-a');
    await r.h.controller.pause();
    await r.h.settle();

    expect(r.controls.updates, hasLength(count));
  });

  group('MediaControlsHost', () {
    test('rebinding to another controller stops the old one driving '
        'updates', () async {
      final controls = FakeMediaControls();
      final host = MediaControlsHost(controls);
      final first = ControllerHarness();
      final second = ControllerHarness();
      MediaControlsBinder bind(ControllerHarness h) => MediaControlsBinder(
        controller: h.controller,
        controls: controls,
        pin: (_) async => null,
        clock: h.clock,
      );

      await host.bind(bind(first));
      await first.controller.playItems(trackItems(['a']));
      await first.settle();
      expect(controls.last!.queueItemId, 'a');

      await host.bind(bind(second));
      await second.controller.playItems(trackItems(['b']));
      await second.settle();
      expect(controls.last!.queueItemId, 'b');
      final count = controls.updates.length;

      await first.controller.pause();
      await first.settle();
      expect(controls.updates, hasLength(count));

      await host.pause();
      expect(second.controller.snapshot.playing, isFalse);
      expect(first.controller.snapshot.current?.queueItemId, 'a');
      await host.bind(null);
    });

    test('with nothing bound the empty state is shown and buttons do '
        'nothing', () async {
      final controls = FakeMediaControls();
      final host = MediaControlsHost(controls);
      final h = ControllerHarness();
      await host.bind(
        MediaControlsBinder(
          controller: h.controller,
          controls: controls,
          pin: (_) async => null,
          clock: h.clock,
        ),
      );
      await h.controller.playItems(trackItems(['a']));
      await h.settle();

      await host.bind(null);
      expect(controls.last, MediaSessionState.empty);
      expect(host.binder, isNull);

      await host.play();
      await host.pause();
      await host.stop();
      await host.next();
      await host.previous();
      await host.seek(Duration.zero);
      await host.skipForward();
      await host.skipBackward();
      await host.setLiked(true);
      await h.settle();
      expect(controls.last, MediaSessionState.empty);
    });

    test('forwards every button to the bound binder', () async {
      final controls = FakeMediaControls();
      final host = MediaControlsHost(controls);
      final h = ControllerHarness();
      await host.bind(
        MediaControlsBinder(
          controller: h.controller,
          controls: controls,
          pin: (_) async => null,
          clock: h.clock,
        ),
      );
      await h.controller.playItems(trackItems(['a', 'b']));
      await h.settle();

      await host.pause();
      expect(h.controller.snapshot.playing, isFalse);
      await host.play();
      expect(h.controller.snapshot.playing, isTrue);
      await host.next();
      expect(h.controller.snapshot.current?.queueItemId, 'b');
      await host.previous();
      expect(h.controller.snapshot.current?.queueItemId, 'a');
      await host.seek(const Duration(seconds: 1));
      await h.settle();
      await host.skipForward();
      expect(h.calls.last, 'seek(${const Duration(seconds: 10)})');
      await h.settle();
      await host.skipBackward();
      expect(h.calls.last, 'seek(${Duration.zero})');
      await host.setLiked(true);
      await host.stop();
      expect(h.controller.snapshot.playing, isFalse);
      await host.bind(null);
    });
  });
}
