// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/equaliser_bars.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

import '../../helpers/play_rig.dart';
import '../../helpers/pump_app.dart';

const List<String> _ids = ['a', 'b', 'c'];

Track _track(String id) => Track(
  meta: TrackMeta(
    title: 'Song $id',
    artist: 'Band',
    album: 'Record',
    durationSec: 10,
  ),
  playbackId: PlaybackId('pb-$id'),
);

/// One row per id, with an index ('a', 'b') or a thumbnail ('c').
Widget _rows() => Column(
  children: [
    for (final (index, id) in _ids.indexed)
      TrackRow(
        title: 'Song $id',
        artist: 'Band',
        duration: const Duration(seconds: 10),
        leading: id == 'c'
            ? const TrackRowLeading.thumbnail('cover')
            : TrackRowLeading.index(index + 1),
        playbackId: PlaybackId('pb-$id'),
        onTap: () {},
      ),
  ],
);

void main() {
  late PlayRig rig;

  Finder row(String id) =>
      find.ancestor(of: find.text('Song $id'), matching: find.byType(TrackRow));

  Finder bars(String id) => find.descendant(
    of: row(id),
    matching: find.byKey(TrackRow.playingIndicatorKey),
  );

  Color titleColor(WidgetTester tester, String id) =>
      tester.widget<Text>(find.text('Song $id')).style!.color!;

  Future<void> pumpRows(WidgetTester tester) async {
    rig = PlayRig();
    await tester.pumpApp(
      Material(child: _rows()),
      size: TestSizes.expanded,
      overrides: rig.overrides,
    );
  }

  Future<void> play(WidgetTester tester, {int start = 0}) async {
    unawaited(
      rig.controller.playItems([
        for (final id in _ids)
          QueueItem.track(
            queueItemId: 'q-$id',
            track: _track(id),
            context: const QueueContext(kind: QueueContextKind.album),
          ),
      ], startIndex: start),
    );
    await rig.settle(tester);
  }

  testWidgets('the current row shows the bars and a brand title', (
    tester,
  ) async {
    await pumpRows(tester);
    final brand = tester.element(row('a')).colors.brand;
    expect(find.byType(EqualiserBars), findsNothing);

    await play(tester);

    expect(bars('a'), findsOneWidget);
    expect(find.byType(EqualiserBars), findsOneWidget);
    expect(
      find.descendant(of: row('a'), matching: find.text('1')),
      findsNothing,
    );
    expect(titleColor(tester, 'a'), brand);
    expect(titleColor(tester, 'b'), isNot(brand));
    expect(tester.widget<EqualiserBars>(bars('a')).animate, isTrue);
    await rig.close(tester);
  });

  testWidgets('the bars sit over a thumbnail', (tester) async {
    await pumpRows(tester);
    await play(tester, start: 2);

    expect(bars('c'), findsOneWidget);
    expect(
      find.descendant(of: row('c'), matching: find.byType(EqualiserBars)),
      findsOneWidget,
    );
    await rig.close(tester);
  });

  testWidgets('moving to the next track moves the indicator', (tester) async {
    await pumpRows(tester);
    await play(tester);

    unawaited(rig.controller.next());
    await rig.settle(tester);

    expect(bars('a'), findsNothing);
    expect(bars('b'), findsOneWidget);
    await rig.close(tester);
  });

  testWidgets('paused shows still bars', (tester) async {
    await pumpRows(tester);
    await play(tester);

    unawaited(rig.controller.pause());
    await rig.settle(tester);

    expect(tester.widget<EqualiserBars>(bars('a')).animate, isFalse);
    await rig.close(tester);
  });

  testWidgets('reduced motion shows still bars', (tester) async {
    await pumpRows(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await play(tester);

    expect(tester.widget<EqualiserBars>(bars('a')).animate, isFalse);
    await rig.close(tester);
  });

  testWidgets('position updates rebuild no TrackRow', (tester) async {
    await pumpRows(tester);
    await play(tester);
    // The node a row builds is a new widget each time the row builds.
    List<Widget> built() => [
      for (final id in _ids)
        tester.widget(
          find.descendant(of: row(id), matching: find.byType(Semantics)).first,
        ),
    ];
    final before = built();

    for (var i = 0; i < 10; i++) {
      rig.harness.fake.advance(FakeEngine.positionInterval);
      await tester.pump(FakeEngine.positionInterval);
    }

    expect(rig.controller.snapshot.position, greaterThan(Duration.zero));
    final after = built();
    for (var i = 0; i < _ids.length; i++) {
      expect(identical(before[i], after[i]), isTrue, reason: _ids[i]);
    }
    await rig.close(tester);
  });

  testWidgets('the row reads "now playing" or "paused"', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpRows(tester);
    await play(tester);

    expect(
      tester.getSemantics(row('a')),
      isSemantics(
        label: 'Song a, Band, 10 seconds, now playing',
        hint: 'Play',
        isButton: true,
      ),
    );
    expect(
      tester.getSemantics(row('b')),
      isSemantics(label: 'Song b, Band, 10 seconds', isButton: true),
    );

    unawaited(rig.controller.pause());
    await rig.settle(tester);
    expect(
      tester.getSemantics(row('a')),
      isSemantics(label: 'Song a, Band, 10 seconds, paused'),
    );
    await rig.close(tester);
    handle.dispose();
  });
}
