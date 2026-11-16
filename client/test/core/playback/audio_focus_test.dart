// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/audio_focus.dart';
import 'package:soundspan/core/playback/playback_command.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/platform/audio_session/audio_session_gateway.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../helpers/fake_audio_session_gateway.dart';
import 'controller/controller_harness.dart';
import 'queue/queue_test_items.dart';

/// An episode entry with id [queueItemId].
QueueItem _episode(String queueItemId) => QueueItem.episode(
  queueItemId: queueItemId,
  episode: const Episode(
    id: 'e1',
    podcastId: 'pod1',
    title: 'Episode',
    durationSec: 600,
  ),
  podcast: const Podcast(id: 'pod1', title: 'Podcast'),
);

/// A controller harness with an [AudioFocusController] over a fake session.
class _Focus {
  new({bool osDucksItself = false})
    : session = FakeAudioSessionGateway(osDucksItself: osDucksItself) {
    focus = AudioFocusController(h.controller, session);
  }

  final ControllerHarness h = ControllerHarness(
    ids: const ['a', 'b', 'c', 'e1', 'e2'],
  );
  final FakeAudioSessionGateway session;
  late final AudioFocusController focus;

  bool get playing => h.controller.snapshot.playing;

  /// Starts playing a, b, c and lets a second pass.
  Future<void> startPlaying() async {
    await h.controller.playItems(trackItems(['a', 'b', 'c']));
    await h.play(const Duration(seconds: 1));
  }

  Future<void> emit(AudioSessionEvent event) async {
    session.emit(event);
    await h.settle();
  }
}

void main() {
  test('play requests focus before the engine starts', () async {
    final f = _Focus();
    final order = <String>[];
    f.session.calls.clear();
    f.h.engine.calls.clear();
    f.focus.dispose();
    f.h.controller.beforePlay = () async {
      order.add('focus');
      return await f.session.setActive(true);
    };

    await f.h.controller.playItems(trackItems(['a', 'b']));
    order.addAll(f.h.calls.where((c) => c.startsWith('load')));

    expect(order, ['focus', 'load(a, autoPlay: true, at: 0:00:00.000000)']);
  });

  test('the focus controller asks for focus when playback starts', () async {
    final f = _Focus();

    await f.startPlaying();

    expect(f.session.calls, contains('setActive(true)'));
    expect(f.session.active, isTrue);
    expect(f.playing, isTrue);
  });

  test('focus denied leaves playback paused and emits focusDenied', () async {
    final f = _Focus();
    f.session.grantFocus = false;

    await f.h.controller.playItems(trackItems(['a', 'b']));
    await f.h.play(const Duration(seconds: 1));

    expect(f.playing, isFalse);
    expect(f.h.notices, contains(const FocusDenied()));
    expect(f.h.calls.where((c) => c.startsWith('load')), [
      'load(a, autoPlay: false, at: 0:00:00.000000)',
    ]);
  });

  test('a denied play of a paused item does not start it', () async {
    final f = _Focus();
    await f.startPlaying();
    await f.h.controller.pause();
    f.session.grantFocus = false;
    f.h.calls.clear();

    await f.h.controller.play();
    await f.h.settle();

    expect(f.playing, isFalse);
    expect(f.h.calls, isNot(contains('play')));
    expect(f.h.notices, contains(const FocusDenied()));
  });

  test('interruption while playing pauses', () async {
    final f = _Focus();
    await f.startPlaying();

    await f.emit(const InterruptionBegan());

    expect(f.playing, isFalse);
    expect(f.h.controller.pauseOrigin, PauseOrigin.focus);
  });

  test('interruption end with shouldResume resumes', () async {
    final f = _Focus();
    await f.startPlaying();
    await f.emit(const InterruptionBegan());

    await f.emit(const InterruptionEnded(shouldResume: true));

    expect(f.playing, isTrue);
    expect(f.h.calls.last, 'play');
  });

  test('interruption end without shouldResume stays paused', () async {
    final f = _Focus();
    await f.startPlaying();
    await f.emit(const InterruptionBegan());

    await f.emit(const InterruptionEnded(shouldResume: false));
    await f.emit(const InterruptionEnded(shouldResume: true));

    expect(f.playing, isFalse);
  });

  test(
    'interruption while already paused does not resume at the end',
    () async {
      final f = _Focus();
      await f.startPlaying();
      await f.h.controller.pause();

      await f.emit(const InterruptionBegan());
      await f.emit(const InterruptionEnded(shouldResume: true));

      expect(f.playing, isFalse);
    },
  );

  test('a user pause during the interruption prevents the resume', () async {
    final f = _Focus();
    await f.startPlaying();
    await f.emit(const InterruptionBegan());

    await f.h.controller.pause();
    await f.emit(const InterruptionEnded(shouldResume: true));

    expect(f.playing, isFalse);
    expect(f.h.controller.pauseOrigin, PauseOrigin.user);
  });

  test('a user seek during the interruption prevents the resume', () async {
    final f = _Focus();
    await f.startPlaying();
    await f.emit(const InterruptionBegan());

    await f.h.controller.seek(const Duration(seconds: 5));
    await f.emit(const InterruptionEnded(shouldResume: true));

    expect(f.playing, isFalse);
  });

  test(
    'a user play during the interruption is not undone by the end event',
    () async {
      final f = _Focus();
      await f.startPlaying();
      await f.emit(const InterruptionBegan());
      await f.h.controller.play();
      f.h.calls.clear();

      await f.emit(const InterruptionEnded(shouldResume: true));

      expect(f.playing, isTrue);
      expect(f.h.calls, isNot(contains('pause')));
      expect(f.h.calls, isNot(contains('play')));
    },
  );

  test('duck begins: factor 0.3 when the OS does not duck', () async {
    final f = _Focus();
    await f.startPlaying();

    await f.emit(const DuckBegan());

    expect(f.h.fake.volume, closeTo(0.3, 1e-9));
    expect(f.playing, isTrue);
  });

  test('duck begins: no change when the OS ducks itself', () async {
    final f = _Focus(osDucksItself: true);
    await f.startPlaying();

    await f.emit(const DuckBegan());

    expect(f.h.fake.volume, 1);
  });

  test('duck ends: factor back to 1.0', () async {
    final f = _Focus();
    await f.startPlaying();
    await f.emit(const DuckBegan());

    await f.emit(const DuckEnded());

    expect(f.h.fake.volume, 1);
  });

  test('duck combines with the loudness factor, clamped', () async {
    final f = _Focus();
    await f.startPlaying();
    f.h.controller.setVolumeFactor('loudness', 0.5);
    await f.h.controller.setVolume(0.8);

    await f.emit(const DuckBegan());
    expect(f.h.fake.volume, closeTo(0.8 * 0.5 * 0.3, 1e-9));

    f.h.controller.setVolumeFactor('loudness', 4);
    await f.h.settle();
    expect(f.h.fake.volume, closeTo(0.8 * 4 * 0.3, 1e-9));

    await f.emit(const DuckEnded());
    expect(f.h.fake.volume, 1);
  });

  test('becoming noisy pauses and a following interruption end does not '
      'resume', () async {
    final f = _Focus();
    await f.startPlaying();
    await f.emit(const InterruptionBegan());
    await f.h.controller.play();

    await f.emit(const BecameNoisy());
    expect(f.playing, isFalse);

    await f.emit(const InterruptionEnded(shouldResume: true));
    expect(f.playing, isFalse);
  });

  test('becoming noisy during an interruption cancels the resume', () async {
    final f = _Focus();
    await f.startPlaying();
    await f.emit(const InterruptionBegan());

    await f.emit(const BecameNoisy());
    await f.emit(const InterruptionEnded(shouldResume: true));

    expect(f.playing, isFalse);
  });

  test('switching from a track to an episode configures speech; back to a '
      'track configures music; same kind does not reconfigure', () async {
    final f = _Focus();

    await f.h.controller.playItems([
      ...trackItems(['a', 'b']),
      _episode('e1'),
      _episode('e2'),
      ...trackItems(['c']),
    ]);
    await f.h.settle();
    await f.h.controller.next();
    await f.h.settle();
    await f.h.controller.next();
    await f.h.settle();
    await f.h.controller.next();
    await f.h.settle();
    await f.h.controller.next();
    await f.h.settle();

    expect(f.session.calls.where((c) => c.startsWith('configure')), [
      'configure(music)',
      'configure(speech)',
      'configure(music)',
    ]);
  });

  test('stop releases focus', () async {
    final f = _Focus();
    await f.startPlaying();
    f.session.calls.clear();

    await f.h.controller.stop();
    await f.h.settle();

    expect(f.session.calls, ['setActive(false)']);
    expect(f.session.active, isFalse);
  });

  test('clearing the queue releases focus', () async {
    final f = _Focus();
    await f.startPlaying();
    f.session.calls.clear();

    await f.h.controller.clear();
    await f.h.settle();

    expect(f.session.calls, ['setActive(false)']);
  });

  test('a pause keeps focus', () async {
    final f = _Focus();
    await f.startPlaying();
    f.session.calls.clear();

    await f.h.controller.pause();
    await f.h.settle();

    expect(f.session.calls, isEmpty);
  });

  test('after dispose events are ignored and the hook is removed', () async {
    final f = _Focus();
    await f.startPlaying();

    f.focus.dispose();
    await f.emit(const InterruptionBegan());

    expect(f.playing, isTrue);
    expect(f.h.controller.beforePlay, isNull);
  });
}
