// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart' show PointerDeviceKind, kSecondaryButton;
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/queue/queue_reducer.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/shared/actions/track_actions.dart';
import 'package:soundspan/shared/providers/play_actions.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import '../../detail_fixtures.dart';
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
      unorderedEquals([
        'Add to queue',
        'More options',
        'Remove from queue',
        'Move up',
        'Move down',
      ]),
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

  group('track menu', () {
    /// Shows the queue under a router whose album and artist pages are
    /// placeholders, and creates the controller.
    Future<PlayerRig> pumpRouted(WidgetTester tester) async {
      final rig = PlayerRig(ids: ids);
      final notices = StreamController<PlayNotice>.broadcast();
      addTearDown(notices.close);
      await pumpDetail(
        tester,
        const Scaffold(body: QueueView()),
        overrides: [
          ...rig.overrides,
          playNoticesProvider.overrideWithValue(notices),
        ],
      );
      ProviderScope.containerOf(tester.element(find.byType(QueueView)))
          .read(playbackControllerProvider);
      await rig.start(
        tester,
        items: [for (final id in ids) playerItem(id, albumId: 'al-$id')],
        play: false,
      );
      return rig;
    }

    /// The menu entry ids shown, in order.
    List<String> entries() => [
      for (final element
          in find
              .byWidgetPredicate(
                (widget) =>
                    widget.key is ValueKey<String> &&
                    (widget.key! as ValueKey<String>).value.startsWith('menu.'),
              )
              .evaluate())
        (element.widget.key! as ValueKey<String>).value.substring(5),
    ];

    const trackMenu = [
      MenuIds.playNow,
      MenuIds.playNext,
      MenuIds.addToQueue,
      MenuIds.addToPlaylist,
      MenuIds.like,
      MenuIds.goToAlbum,
      MenuIds.share,
    ];

    Future<void> dismiss(WidgetTester tester) async {
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
    }

    testWidgets('the overflow button, a long press and a secondary click '
        'open it on a next-up row', (tester) async {
      final rig = await pumpRouted(tester);

      await tester.tap(inRow('c', find.byKey(TrackRow.overflowKey)));
      await tester.pumpAndSettle();
      expect(entries(), trackMenu);
      await dismiss(tester);

      await tester.longPress(inRow('c', find.text('Song c')));
      await tester.pumpAndSettle();
      expect(entries(), trackMenu);
      await dismiss(tester);

      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      addTearDown(mouse.removePointer);
      await mouse.down(tester.getCenter(inRow('c', find.text('Song c'))));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(entries(), trackMenu);
      await dismiss(tester);

      // None of them played the row.
      expect(rig.controller.snapshot.current?.queueItemId, 'a');
      await rig.close(tester);
    });

    testWidgets('the now-playing row has no menu', (tester) async {
      final rig = await pumpRouted(tester);

      expect(inRow('a', find.byKey(TrackRow.overflowKey)), findsNothing);
      await rig.close(tester);
    });

    testWidgets('Play next queues the track after the current one', (
      tester,
    ) async {
      final rig = await pumpRouted(tester);

      await tester.tap(inRow('e', find.byKey(TrackRow.overflowKey)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('menu.${MenuIds.playNext}')));
      await rig.settle(tester);
      await tester.pumpAndSettle();

      expect(titles(tester), [
        'Song a',
        'Song e',
        'Song b',
        'Song c',
        'Song d',
        'Song e',
      ]);
      await rig.close(tester);
    });

    testWidgets('Go to album opens the album of the row', (tester) async {
      final rig = await pumpRouted(tester);

      await tester.tap(inRow('d', find.byKey(TrackRow.overflowKey)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('menu.${MenuIds.goToAlbum}')));
      await tester.pumpAndSettle();

      expect(find.text('album page al-d'), findsOneWidget);
      await rig.close(tester);
    });

    testWidgets('the Add to queue and More options actions work', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final rig = await pumpRouted(tester);

      void perform(String id, String label) {
        final node = tester.getSemantics(inRow(id, find.byType(TrackRow)));
        node.owner!.performAction(
          node.id,
          SemanticsAction.customAction,
          CustomSemanticsAction.getIdentifier(
            CustomSemanticsAction(label: label),
          ),
        );
      }

      perform('b', 'Add to queue');
      await rig.settle(tester);
      await tester.pumpAndSettle();
      expect(rig.controller.snapshot.queue.items, hasLength(6));
      expect(titles(tester).last, 'Song b');

      perform('c', 'More options');
      await tester.pumpAndSettle();
      expect(entries(), trackMenu);
      await dismiss(tester);
      await rig.close(tester);
      handle.dispose();
    });

    testWidgets('an episode entry has no track menu', (tester) async {
      final rig = await pumpQueue(tester, rigIds: ['a', 'x']);
      await rig.start(
        tester,
        items: [playerItem('a'), playerEpisode('x')],
        play: false,
      );

      expect(inRow('x', find.byKey(TrackRow.overflowKey)), findsNothing);
      await tester.longPress(inRow('x', find.text('Episode x')));
      await tester.pumpAndSettle();
      expect(entries(), isEmpty);
      await rig.close(tester);
    });
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
