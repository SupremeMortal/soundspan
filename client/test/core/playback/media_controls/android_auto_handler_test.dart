// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/downloads/download_store.dart'
    show DownloadCollectionKind;
import 'package:soundspan/core/playback/media_controls/audio_service_controls.dart';
import 'package:soundspan/core/playback/media_controls/browse/browse_tree.dart';
import 'package:soundspan/core/playback/media_controls/media_controls_binder.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../../helpers/fake_media_browse_source.dart';
import '../controller/controller_harness.dart';

String _downloadsSubtitle(DownloadCollectionKind kind, int completed) =>
    '${kind.name} · $completed';

const _titles = BrowseRootTitles(
  recent: 'Recent',
  playlists: 'Playlists',
  albums: 'Albums',
  downloads: 'Downloads',
  downloadsSubtitle: _downloadsSubtitle,
);

/// The Android handler over a real controller on a `FakeEngine`, with the
/// browse source behind the binder.
class _Car {
  new() {
    binder = MediaControlsBinder(
      controller: h.controller,
      controls: controls,
      pin: (_) async => null,
      clock: h.clock,
      browseSource: source,
    );
  }

  final ControllerHarness h = ControllerHarness(playAny: true);
  final FakeMediaBrowseSource source = FakeMediaBrowseSource()
    ..albumTrackMap = {
      'a1': [
        browseTrack('t0', playbackId: 'pt0'),
        browseTrack('gone'),
        browseTrack('t1', playbackId: 'pt1'),
        browseTrack('t2', playbackId: 'pt2'),
      ],
    };
  late final AudioServiceControls controls = AudioServiceControls(
    config: () =>
        audioServiceConfigFor(operatingSystem: 'android', channelName: 'P'),
    start: (builder, _) async => handler = builder(),
    clock: h.clock,
    likeLabel: (liked) => liked ? 'Remove like' : 'Like',
    browseTitles: () => _titles,
  );
  late final MediaControlsBinder binder;
  late SoundspanAudioHandler handler;

  Future<void> init() => controls.init(binder);
}

void main() {
  test('getChildren(root) yields the three browsable roots without '
      'artwork', () async {
    final car = _Car();
    await car.init();

    final items = await car.handler.getChildren('root');

    expect([for (final i in items) i.id], ['recent', 'playlists', 'albums']);
    expect([for (final i in items) i.title], ['Recent', 'Playlists', 'Albums']);
    expect(items.every((i) => i.playable == false), isTrue);
    expect(items.every((i) => i.artUri == null), isTrue);
  });

  test('album children are playable items with the artist as subtitle '
      'and no artwork', () async {
    final car = _Car();
    await car.init();

    final items = await car.handler.getChildren('album/a1');

    expect(
      [for (final i in items) i.id],
      ['album/a1/0', 'album/a1/1', 'album/a1/2'],
    );
    expect(items.first.artist, 'Artist t0');
    expect(items.every((i) => i.playable ?? false), isTrue);
    expect(items.every((i) => i.artUri == null), isTrue);
  });

  test('playFromMediaId replaces the queue and plays the index', () async {
    final car = _Car();
    await car.init();

    await car.handler.playFromMediaId('album/a1/2');
    await car.h.settle();

    final snapshot = car.h.controller.snapshot;
    final items = snapshot.queue.items.cast<TrackQueueItem>();
    expect([for (final i in items) i.track.meta.title], ['t0', 't1', 't2']);
    expect((snapshot.current! as TrackQueueItem).track.meta.title, 't2');
    expect(items.first.context.kind, QueueContextKind.album);
    expect(snapshot.playing, isTrue);
  });

  test('playFromSearch without hits and an unknown id change '
      'nothing', () async {
    final car = _Car();
    await car.init();

    await car.handler.playFromSearch('x');
    await car.handler.playFromMediaId('nonsense');
    await car.h.settle();

    expect(car.h.controller.snapshot.queue.items, isEmpty);
    expect(car.h.engine.calls, isEmpty);
  });

  test('search returns the playable result items', () async {
    final car = _Car();
    car.source.searchHits = {
      'daft punk': [browseTrack('d0', playbackId: 'pd0')],
    };
    await car.init();

    final items = await car.handler.search('daft punk');

    expect([for (final i in items) i.id], ['search/daft%20punk/0']);
    expect(items.single.playable, isTrue);
  });

  test('without a bound profile the tree is empty', () async {
    final car = _Car();
    final host = MediaControlsHost(car.controls);
    await car.controls.init(host);

    expect(await car.handler.getChildren('root'), isEmpty);
    await car.handler.playFromMediaId('album/a1/0');
    expect(car.h.controller.snapshot.queue.items, isEmpty);
  });
}
