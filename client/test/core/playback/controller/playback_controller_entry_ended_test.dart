// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';

import '../queue/queue_test_items.dart';
import 'controller_harness.dart';

/// A controller harness that records every [EntryEnded] event.
Future<(ControllerHarness, List<EntryEnded>)> _started(
  List<String> ids, {
  int startIndex = 0,
}) async {
  final h = ControllerHarness();
  final ended = <EntryEnded>[];
  h.controller.entryEnded.listen(ended.add);
  await h.controller.playItems(trackItems(ids), startIndex: startIndex);
  await h.settle();
  return (h, ended);
}

void main() {
  test('next, jump, replace, clear and stop each end the current entry '
      'once', () async {
    final (h, ended) = await _started(['a', 'b', 'c', 'd']);
    await h.controller.next();
    await h.controller.jumpTo('d');
    await h.controller.playItems(trackItems(['a', 'b']));
    await h.controller.stop();
    await h.controller.clear();
    await h.settle();

    expect(ended, const [
      EntryEnded('a', natural: false),
      EntryEnded('b', natural: false),
      EntryEnded('d', natural: false),
      EntryEnded('a', natural: false),
      EntryEnded('a', natural: false),
    ]);
  });

  test('queue edits that keep the current entry and a previous that seeks to '
      'zero end nothing', () async {
    final (h, ended) = await _started(['a', 'b', 'c']);
    await h.play(const Duration(seconds: 4));
    await h.controller.previous();
    await h.controller.setRepeat(RepeatMode.all);
    await h.controller.setShuffle(true);
    await h.controller.append(trackItems(['x']));
    await h.controller.removeAt('c');
    await h.controller.pause();
    await h.controller.seek(const Duration(seconds: 1));
    await h.settle();

    expect(ended, isEmpty);
  });

  test('previous that moves the cursor ends the entry', () async {
    final (h, ended) = await _started(['a', 'b'], startIndex: 1);
    await h.controller.previous();
    await h.settle();

    expect(ended, const [EntryEnded('b', natural: false)]);
  });

  test('the natural end into the preloaded next entry and the end of the '
      'queue are natural', () async {
    final (h, ended) = await _started(['a', 'b']);
    await h.play(trackLength + FakeEngine.positionInterval);
    await h.play(trackLength + FakeEngine.positionInterval);

    expect(ended, const [
      EntryEnded('a', natural: true),
      EntryEnded('b', natural: true),
    ]);
    expect(h.controller.snapshot.current?.queueItemId, 'b');
  });

  test('every repeat-one replay ends the entry', () async {
    final (h, ended) = await _started(['a', 'b']);
    await h.controller.setRepeat(RepeatMode.one);
    await h.settle();
    await h.play(trackLength + FakeEngine.positionInterval);
    await h.play(trackLength);

    expect(ended, const [
      EntryEnded('a', natural: true),
      EntryEnded('a', natural: true),
    ]);
    expect(h.controller.snapshot.current?.queueItemId, 'a');
  });

  test('a failed entry that is skipped ends', () async {
    final h = ControllerHarness();
    final ended = <EntryEnded>[];
    h.controller.entryEnded.listen(ended.add);
    h.resolver.unplayable.add('a');
    await h.controller.playItems(trackItems(['a', 'b']));
    await h.settle();

    expect(ended.first, const EntryEnded('a', natural: false));
    expect(h.controller.snapshot.current?.queueItemId, 'b');
  });

  test(
    'three failed entries in a row stop playback and end the third',
    () async {
      final h = ControllerHarness();
      final ended = <EntryEnded>[];
      h.controller.entryEnded.listen(ended.add);
      h.resolver.unplayable.addAll(['a', 'b', 'c']);
      await h.controller.playItems(trackItems(['a', 'b', 'c', 'd']));
      await h.settle();

      expect(ended.map((e) => e.queueItemId), ['a', 'b', 'c']);
      expect(h.controller.snapshot.current?.queueItemId, 'c');
    },
  );

  test('a listener after dispose is closed at once', () async {
    final (h, _) = await _started(['a']);
    await h.controller.dispose();

    expect(await h.controller.entryEnded.isEmpty, isTrue);
    expect(
      const EntryEnded('a', natural: true).toString(),
      'EntryEnded(a, natural: true)',
    );
    expect(
      const EntryEnded('a', natural: true).hashCode,
      const EntryEnded('a', natural: true).hashCode,
    );
  });
}
