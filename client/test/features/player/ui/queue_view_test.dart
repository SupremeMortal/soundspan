// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math';

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/queue/queue_reducer.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import 'player_rig.dart';

void main() {
  const ids = ['a', 'b', 'c', 'd', 'e'];

  Future<PlayerRig> pumpQueue(
    WidgetTester tester, {
    List<String> ids = ids,
    List<String>? rigIds,
    Size size = TestSizes.compact,
  }) async {
    // Seeded, so shuffling c, d, e gives the same new order every run.
    final rig = PlayerRig(
      ids: rigIds ?? ids,
      reducer: QueueReducer(random: Random(1)),
    );
    final container = await tester.pumpApp(
      const Scaffold(body: QueueView()),
      size: size,
      overrides: rig.overrides,
    );
    // The view does not create the controller; a play action does.
    container.read(playbackControllerProvider);
    return rig;
  }

  /// The titles of the rows, in the order they are laid out.
  List<String> titles(WidgetTester tester) =>
      tester.widgetList<TrackRow>(find.byType(TrackRow)).map((row) {
        return row.title;
      }).toList();

  List<String> playOrderIds(PlayerRig rig) {
    final queue = rig.controller.snapshot.queue;
    return [for (final i in queue.playOrder) queue.items[i].queueItemId];
  }

  Finder inRow(String queueItemId, Finder matching) => find.descendant(
    of: find.byKey(QueueView.rowKey(queueItemId)),
    matching: matching,
  );

  testWidgets('current and next-up entries follow play order', (tester) async {
    final rig = await pumpQueue(tester);
    await rig.start(tester, ids: ids, play: false);

    expect(find.text('Now playing'), findsOneWidget);
    expect(find.text('Next up'), findsOneWidget);
    expect(titles(tester), ['Song a', 'Song b', 'Song c', 'Song d', 'Song e']);
    expect(tester.widget<TrackRow>(find.byType(TrackRow).first).selected, true);

    await rig.controller.next();
    await rig.settle(tester);
    expect(titles(tester), ['Song b', 'Song c', 'Song d', 'Song e']);

    await rig.controller.setShuffle(true);
    await rig.settle(tester);
    final order = playOrderIds(rig);
    final cursor = rig.controller.snapshot.queue.cursor!;
    expect(order[cursor], 'b');
    expect(titles(tester), [
      for (final id in order.sublist(cursor)) 'Song $id',
    ]);
    expect(titles(tester), isNot(['Song b', 'Song c', 'Song d', 'Song e']));
    await rig.close(tester);
  });

  testWidgets('tapping a next-up row jumps to it', (tester) async {
    final rig = await pumpQueue(tester);
    await rig.start(tester, ids: ids, play: false);

    await tester.tap(find.text('Song c'));
    await rig.settle(tester);

    expect(rig.controller.snapshot.current?.queueItemId, 'c');
    expect(titles(tester).first, 'Song c');
    await rig.close(tester);
  });

  testWidgets('dragging a row moves that entry once', (tester) async {
    final rig = await pumpQueue(tester);
    await rig.start(tester, ids: ids, play: false);
    final revision = rig.controller.snapshot.queue.revision;
    final extent = tester.getSize(find.byKey(QueueView.rowKey('b'))).height;

    final handle = inRow('b', find.byIcon(Icons.drag_handle_rounded));
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    // One row down: past "c", not past "d".
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(Offset(0, extent * 0.25));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    await rig.settle(tester);

    expect(rig.controller.snapshot.queue.revision, revision + 1);
    expect(playOrderIds(rig), ['a', 'c', 'b', 'd', 'e']);
    expect(titles(tester), ['Song a', 'Song c', 'Song b', 'Song d', 'Song e']);
    await rig.close(tester);
  });

  testWidgets('remove takes out that entry when the track is queued twice', (
    tester,
  ) async {
    final rig = await pumpQueue(tester, rigIds: ['a', 'b1', 'b2']);
    await rig.start(
      tester,
      items: [
        playerItem('a'),
        playerItem('b', queueItemId: 'b1'),
        playerItem('b', queueItemId: 'b2'),
      ],
      play: false,
    );
    expect(titles(tester), ['Song a', 'Song b', 'Song b']);

    await tester.tap(inRow('b2', find.byTooltip('Remove from queue')));
    await rig.settle(tester);

    expect(playOrderIds(rig), ['a', 'b1']);
    expect(find.byKey(QueueView.rowKey('b1')), findsOneWidget);
    expect(find.byKey(QueueView.rowKey('b2')), findsNothing);
    await rig.close(tester);
  });

  testWidgets('Clear empties the queue and shows the empty state', (
    tester,
  ) async {
    final rig = await pumpQueue(tester);
    await rig.start(tester, ids: ids, play: false);

    await tester.tap(find.byKey(QueueView.clearKey));
    await rig.settle(tester);

    expect(rig.controller.snapshot.queue.items, isEmpty);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Nothing is queued'), findsOneWidget);
    expect(find.byType(TrackRow), findsNothing);
    await rig.close(tester);
  });

  testWidgets('an empty queue shows the empty state', (tester) async {
    final rig = await pumpQueue(tester);
    await rig.settle(tester);

    expect(find.byType(EmptyState), findsOneWidget);
    await rig.close(tester);
  });

  testWidgets('does not create the controller', (tester) async {
    final rig = PlayerRig(ids: ids);
    final container = await tester.pumpApp(
      const Scaffold(body: QueueView()),
      overrides: rig.overrides,
    );
    await rig.settle(tester);

    expect(find.byType(EmptyState), findsOneWidget);
    expect(container.read(playbackControllerProvider.exists), isFalse);
    await rig.close(tester);
  });

  testWidgets('a 5,000-entry queue builds only the visible rows', (
    tester,
  ) async {
    final rig = await pumpQueue(tester, rigIds: ['q0', 'q1']);
    await rig.start(
      tester,
      items: [for (var i = 0; i < 5000; i++) playerItem('q$i')],
      play: false,
    );

    expect(rig.controller.snapshot.queue.items, hasLength(5000));
    expect(find.byType(TrackRow).evaluate().length, lessThan(40));
    expect(find.text('Song q4999'), findsNothing);
    await rig.close(tester);
  });

  testWidgets('rows offer remove and move as semantics actions', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final rig = await pumpQueue(tester);
    await rig.start(tester, ids: ids, play: false);

    final row = inRow('c', find.byType(TrackRow));
    final node = tester.getSemantics(row);
    final labels = node
        .getSemanticsData()
        .customSemanticsActionIds!
        .map((id) => CustomSemanticsAction.getAction(id)!.label)
        .toList();
    expect(
      labels,
      unorderedEquals(['Remove from queue', 'Move up', 'Move down']),
    );

    node.owner!.performAction(
      node.id,
      SemanticsAction.customAction,
      CustomSemanticsAction.getIdentifier(
        const CustomSemanticsAction(label: 'Move down'),
      ),
    );
    await rig.settle(tester);
    expect(playOrderIds(rig), ['a', 'b', 'd', 'c', 'e']);
    await rig.close(tester);
    handle.dispose();
  });

  for (final theme in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('meets the guidelines (${theme.name})', (tester) async {
      final rig = PlayerRig(ids: ids);
      final container = await tester.pumpApp(
        const Scaffold(body: QueueView()),
        theme: theme,
        overrides: rig.overrides,
      );
      container.read(playbackControllerProvider);
      await rig.start(tester, ids: ids, play: false);

      await expectMeetsGuidelines(tester);
      await rig.close(tester);
    });
  }
}
