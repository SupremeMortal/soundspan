// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/realtime/socket_client.dart';

import '../../core/playback/controller/controller_harness.dart';
import 'listen_together_rig.dart';

/// A rig in a group over a, b, c that played two seconds and is now
/// paused there, more than a second after its last seek.
Future<ListenTogetherRig> _pausedAtTwoSeconds() async {
  final rig = ListenTogetherRig();
  await rig.join();
  await rig.push(
    (s) => s.states.add(
      groupState(syncState: 'playing', serverTime: rig.serverNow),
    ),
  );
  await rig.h.play(const Duration(seconds: 2));
  await rig.push((s) => s.playbackDeltas.add(_paused(rig, 2000, 2)));
  await rig.time.advance(const Duration(milliseconds: 1100));
  rig.h.calls.clear();
  return rig;
}

int _version = 10;

PlaybackDelta _paused(ListenTogetherRig rig, int positionMs, [int? version]) =>
    PlaybackDelta(
      isPlaying: false,
      positionMs: positionMs,
      serverTime: rig.serverNow,
      stateVersion: version ?? ++_version,
      currentIndex: 0,
    );

int _engineMs(ListenTogetherRig rig) =>
    rig.h.controller.snapshot.position.inMilliseconds;

String _seek(int ms) => 'seek(${Duration(milliseconds: ms)})';

void main() {
  for (final (drift, corrected) in [
    (249, false),
    (250, true),
    (1499, true),
    (1500, true),
  ]) {
    test(
      'a drift of $drift ms on a playback-delta '
      '${corrected ? 'seeks to the expected position' : 'is left alone'}',
      () async {
        final rig = await _pausedAtTwoSeconds();
        expect(_engineMs(rig), 2000);

        await rig.push((s) => s.playbackDeltas.add(_paused(rig, 2000 + drift)));

        expect(rig.h.calls, corrected ? [_seek(2000 + drift)] : isEmpty);
      },
    );
  }

  test('a second mid-band correction inside 10 s is suppressed and allowed '
      'after', () async {
    final rig = await _pausedAtTwoSeconds();

    await rig.push((s) => s.playbackDeltas.add(_paused(rig, 2500)));
    expect(rig.h.calls, [_seek(2500)]);

    await rig.time.advance(const Duration(seconds: 2));
    await rig.push((s) => s.playbackDeltas.add(_paused(rig, 3000)));
    expect(rig.h.calls, [_seek(2500)]);

    await rig.time.advance(const Duration(seconds: 8));
    await rig.push((s) => s.playbackDeltas.add(_paused(rig, 3000)));
    expect(rig.h.calls, [_seek(2500), _seek(3000)]);
  });

  test('a large drift is corrected at once even inside the 10 s of a '
      'mid-band correction', () async {
    final rig = await _pausedAtTwoSeconds();

    await rig.push((s) => s.playbackDeltas.add(_paused(rig, 2500)));
    await rig.time.advance(const Duration(seconds: 2));
    await rig.push((s) => s.playbackDeltas.add(_paused(rig, 6000)));

    expect(rig.h.calls, [_seek(2500), _seek(6000)]);
  });

  test('no correction within 1 s of a seek this controller issued', () async {
    final rig = await _pausedAtTwoSeconds();

    await rig.push((s) => s.playbackDeltas.add(_paused(rig, 5000)));
    await rig.time.advance(const Duration(milliseconds: 900));
    await rig.push((s) => s.playbackDeltas.add(_paused(rig, 9000)));

    expect(rig.h.calls, [_seek(5000)]);
  });

  test('no correction while buffering', () async {
    final rig = ListenTogetherRig();
    rig.h.fake.sources[uriOf(groupItem(0, 'a'))] = const FakeSource(
      duration: trackLength,
      bufferedAhead: Duration(milliseconds: 100),
    );
    await rig.join();
    await rig.push((s) => s.states.add(groupState(serverTime: rig.serverNow)));
    await rig.time.advance(const Duration(seconds: 2));
    await rig.h.fake.seek(const Duration(seconds: 5));
    await rig.h.settle();
    rig.h.calls.clear();

    await rig.push((s) => s.playbackDeltas.add(_paused(rig, 1000)));

    expect(rig.h.controller.snapshot.status.name, 'buffering');
    expect(rig.h.calls, isEmpty);
  });

  test('the check runs every 5 s, only while the group is playing', () async {
    final rig = ListenTogetherRig();
    await rig.join();
    await rig.push(
      (s) => s.states.add(
        groupState(syncState: 'playing', serverTime: rig.serverNow),
      ),
    );
    rig.h.calls.clear();

    // The engine stands still while the group's clock runs on.
    await rig.time.advance(const Duration(milliseconds: 4999));
    expect(rig.h.calls, isEmpty);
    await rig.time.advance(const Duration(milliseconds: 1));
    expect(rig.h.calls, [_seek(5000)]);

    await rig.push((s) => s.playbackDeltas.add(_paused(rig, 5000)));
    rig.h.calls.clear();
    await rig.time.advance(const Duration(seconds: 20));
    expect(rig.h.calls, isEmpty);
  });
}
