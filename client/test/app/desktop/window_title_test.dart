// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../core/playback/controller/controller_harness.dart';
import 'desktop_rig.dart';

void main() {
  late DesktopRig r;

  setUp(() async {
    r = DesktopRig();
    await r.start();
    r.desktop.setRouteTitle('Home · soundspan');
  });

  tearDown(() => r.close());

  test('the window shows the screen title while nothing plays', () {
    expect(r.shell.titles.first, 'soundspan');
    expect(r.shell.titles.last, 'Home · soundspan');
  });

  test('the window shows "Title — Artist · soundspan" while playing', () async {
    await r.play();

    expect(r.shell.titles.last, 'Song a — Band · soundspan');

    await r.h.controller.next();
    await r.h.settle();
    expect(r.shell.titles.last, 'Song b — Band · soundspan');
  });

  test('a track without an artist shows its title alone', () async {
    await r.h.controller.playItems([desktopTrack('a', artist: '')]);
    await r.h.settle();

    expect(r.shell.titles.last, 'Song a · soundspan');
  });

  test('the screen title comes back when paused', () async {
    await r.play();
    r.desktop.setRouteTitle('Library · soundspan');
    expect(r.shell.titles.last, 'Song a — Band · soundspan');

    await r.h.controller.pause();
    await r.h.settle();

    expect(r.shell.titles.last, 'Library · soundspan');
  });

  test('the screen title comes back when the queue empties', () async {
    await r.play();

    await r.h.controller.clear();
    await r.h.settle();

    expect(r.shell.titles.last, 'Home · soundspan');
  });

  test('position updates set no title', () async {
    await r.play();
    final set = r.shell.titles.length;

    r.h.fake.advance(const Duration(seconds: 5));
    await r.h.settle();

    expect(r.shell.titles, hasLength(set));
  });

  test('an episode shows its title and podcast', () async {
    r.h.fake.sources[uriOf('e')] = const FakeSource(
      duration: Duration(seconds: 60),
    );
    await r.h.controller.playItems([
      const QueueItem.episode(
        queueItemId: 'e',
        episode: Episode(
          id: 'ep-1',
          podcastId: 'pod-1',
          title: 'Pilot',
          durationSec: 60,
        ),
        podcast: Podcast(id: 'pod-1', title: 'The Show'),
      ),
    ]);
    await r.h.settle();

    expect(r.shell.titles.last, 'Pilot — The Show · soundspan');
  });
}
