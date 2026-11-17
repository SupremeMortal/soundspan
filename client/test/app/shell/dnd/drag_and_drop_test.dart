// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/sidebar_playlists.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/shared/dnd/pointer_draggable.dart';
import 'package:soundspan/shared/widgets/media_card.dart';

import '../shortcuts/selection_harness.dart';
import 'dnd_harness.dart';

void main() {
  final linux = TargetPlatformVariant.only(TargetPlatform.linux);

  group('onto a sidebar playlist', () {
    testWidgets('one unselected track adds it and keeps the selection', (
      tester,
    ) async {
      final rig = await DndRig.pump(tester);
      await click(tester, 'Song 1.2');

      await dragTo(
        tester,
        rowOf('Song 1.1'),
        tester.getCenter(sidebarRow(ownedPlaylist)),
      );
      await rig.play.settle(tester);

      expect(rig.edits, ['add pl-own p-1-1']);
      expect(find.text('Added 1 song to $ownedPlaylist'), findsOneWidget);
      expect(albumSelection(tester), ['Song 1.2']);
      await rig.close(tester);
    }, variant: linux);

    testWidgets('a row of a selection adds the selection in list order', (
      tester,
    ) async {
      final rig = await DndRig.pump(tester);
      await click(tester, 'Song 1.3');
      await click(tester, 'Song 1.1', modifier: LogicalKeyboardKey.shiftLeft);

      await dragTo(
        tester,
        rowOf('Song 1.2'),
        tester.getCenter(sidebarRow(ownedPlaylist)),
      );
      await rig.play.settle(tester);

      expect(rig.edits, ['add pl-own p-1-1,p-1-2,p-1-3']);
      expect(find.text('Added 3 songs to $ownedPlaylist'), findsOneWidget);
      await rig.close(tester);
    }, variant: linux);

    testWidgets('a selection with an unplayable row adds the playable ones', (
      tester,
    ) async {
      final rig = await DndRig.pump(tester, unplayable: true);
      await click(tester, 'Song 1.1');
      await pressWith(
        tester,
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.keyA,
      );
      expect(albumSelection(tester), hasLength(4));

      await dragTo(
        tester,
        rowOf('Song 1.2'),
        tester.getCenter(sidebarRow(ownedPlaylist)),
      );
      await rig.play.settle(tester);

      expect(rig.edits, ['add pl-own p-1-1,p-1-2,p-1-3']);
      await rig.close(tester);
    }, variant: linux);

    testWidgets('an album card adds every track of the album', (tester) async {
      final rig = await DndRig.pump(tester);
      final card = find.widgetWithText(MediaCard, 'Album al-2');
      await tester.ensureVisible(card);
      await tester.pump();

      await dragTo(tester, card, tester.getCenter(sidebarRow(ownedPlaylist)));
      await rig.play.settle(tester);

      expect(rig.edits, ['add pl-own p-2-1,p-2-2']);
      expect(find.text('Added 2 songs to $ownedPlaylist'), findsOneWidget);
      await rig.close(tester);
    }, variant: linux);

    testWidgets('only an owned playlist highlights and accepts a drop', (
      tester,
    ) async {
      final rig = await DndRig.pump(tester);
      final highlight = find.byKey(SidebarPlaylists.dropHighlightKey);

      final gesture = await startDrag(tester, rowOf('Song 1.1'));
      await hover(tester, gesture, tester.getCenter(sidebarRow(ownedPlaylist)));
      expect(highlight, findsOneWidget);
      expect(
        find.ancestor(of: sidebarRow(ownedPlaylist), matching: highlight),
        findsNothing,
      );
      expect(
        tester
            .getRect(highlight)
            .contains(tester.getCenter(sidebarRow(ownedPlaylist))),
        isTrue,
      );
      await hover(tester, gesture, tester.getCenter(sidebarRow('Liked Songs')));
      expect(highlight, findsNothing);
      await hover(tester, gesture, tester.getCenter(sidebarRow(otherPlaylist)));
      expect(highlight, findsNothing);
      await gesture.up();
      await rig.play.settle(tester);

      await dragTo(
        tester,
        rowOf('Song 1.1'),
        tester.getCenter(sidebarRow('Liked Songs')),
      );
      await rig.play.settle(tester);

      expect(rig.edits, isEmpty);
      await rig.close(tester);
    }, variant: linux);
  });

  group('into the queue panel', () {
    testWidgets('between the second and third Next up rows inserts there', (
      tester,
    ) async {
      final rig = await DndRig.pump(tester);
      final playing = rig.play.controller.snapshot.playing;

      await dragTo(tester, rowOf('Song 1.1'), belowQueueRow(tester, 'c'));
      await rig.play.settle(tester);

      expect(rig.play.queued, ['pb-a', 'pb-b', 'pb-c', 'p-1-1', 'pb-d']);
      expect(rig.play.current, 'pb-a');
      expect(rig.play.controller.snapshot.playing, playing);
      await rig.close(tester);
    }, variant: linux);

    testWidgets('on the Now playing section inserts after the current item', (
      tester,
    ) async {
      final rig = await DndRig.pump(tester);

      await dragTo(
        tester,
        rowOf('Song 1.1'),
        tester.getCenter(find.text('Now playing')),
      );
      await rig.play.settle(tester);

      expect(rig.play.queued, ['pb-a', 'p-1-1', 'pb-b', 'pb-c', 'pb-d']);
      expect(rig.play.current, 'pb-a');
      await rig.close(tester);
    }, variant: linux);

    testWidgets('with shuffle on the tracks are next at the drop position', (
      tester,
    ) async {
      final rig = await DndRig.pump(tester, shuffle: true);
      final before = rig.play.queued;
      await click(tester, 'Song 1.1');
      await click(tester, 'Song 1.2', modifier: LogicalKeyboardKey.shiftLeft);

      final second = before[2].substring(3);
      await dragTo(tester, rowOf('Song 1.1'), belowQueueRow(tester, second));
      await rig.play.settle(tester);

      expect(rig.play.queued, [
        ...before.sublist(0, 3),
        'p-1-1',
        'p-1-2',
        ...before.sublist(3),
      ]);
      expect(rig.play.current, before.first);
      await rig.close(tester);
    }, variant: linux);

    testWidgets('on an empty queue starts a paused queue', (tester) async {
      final rig = await DndRig.pump(tester, queued: const []);
      expect(find.text('Nothing is queued'), findsOneWidget);

      await dragTo(
        tester,
        rowOf('Song 1.1'),
        tester.getCenter(find.text('Nothing is queued')),
      );
      await rig.play.settle(tester);

      expect(rig.play.queued, ['p-1-1']);
      expect(rig.play.current, 'p-1-1');
      expect(rig.play.controller.snapshot.playing, isFalse);
      await rig.close(tester);
    }, variant: linux);

    testWidgets('an album card inserts its tracks', (tester) async {
      final rig = await DndRig.pump(tester);
      final card = find.widgetWithText(MediaCard, 'Album al-2');
      await tester.ensureVisible(card);
      await tester.pump();

      await dragTo(tester, card, belowQueueRow(tester, 'b'));
      await rig.play.settle(tester);

      expect(rig.play.queued, [
        'pb-a',
        'pb-b',
        'p-2-1',
        'p-2-2',
        'pb-c',
        'pb-d',
      ]);
      await rig.close(tester);
    }, variant: linux);

    testWidgets('the insertion line shows the nearest gap and leaves', (
      tester,
    ) async {
      final rig = await DndRig.pump(tester);
      final line = find.byKey(QueueView.dropIndicatorKey);

      final gesture = await startDrag(tester, rowOf('Song 1.1'));
      expect(line, findsNothing);
      final gap = belowQueueRow(tester, 'c');
      await hover(tester, gesture, gap + const Offset(0, 10));
      expect(line, findsOneWidget);
      expect(tester.getRect(line).center.dy, closeTo(gap.dy, 1));

      await hover(tester, gesture, belowQueueRow(tester, 'b'));
      expect(
        tester.getRect(line).center.dy,
        closeTo(belowQueueRow(tester, 'b').dy, 1),
      );

      await hover(tester, gesture, tester.getCenter(rowOf('Song 1.3')));
      expect(line, findsNothing);
      await gesture.up();
      await rig.play.settle(tester);
      await rig.close(tester);
    }, variant: linux);

    testWidgets('a drag near the bottom edge scrolls the queue', (
      tester,
    ) async {
      final rig = await DndRig.pump(
        tester,
        queued: [for (var i = 0; i < 40; i++) 'q$i'],
      );
      final panel = find.byType(QueueView);
      final scrollable = find
          .descendant(of: panel, matching: find.byType(Scrollable))
          .first;
      double offset() =>
          tester.state<ScrollableState>(scrollable).position.pixels;
      expect(offset(), 0);

      final gesture = await startDrag(tester, rowOf('Song 1.1'));
      final rect = tester.getRect(panel);
      await hover(tester, gesture, Offset(rect.center.dx, rect.bottom - 10));
      await tester.pump(const Duration(milliseconds: 200));
      expect(offset(), greaterThan(0));

      await hover(tester, gesture, rect.center);
      final stopped = offset();
      await tester.pump(const Duration(milliseconds: 200));
      expect(offset(), stopped);
      await gesture.up();
      await rig.play.settle(tester);
      await rig.close(tester);
    }, variant: linux);
  });

  testWidgets('releasing outside any target changes nothing', (tester) async {
    final rig = await DndRig.pump(tester);
    final before = rig.play.queued;

    await dragTo(
      tester,
      rowOf('Song 1.1'),
      tester.getCenter(rowOf('Song 1.3')),
    );
    await rig.play.settle(tester);

    expect(rig.edits, isEmpty);
    expect(rig.play.queued, before);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('a touch long press opens the menu and starts no drag', (
    tester,
  ) async {
    final rig = await DndRig.pump(tester, queuePanel: false);

    final gesture = await startDrag(
      tester,
      rowOf('Song 1.1'),
      kind: PointerDeviceKind.touch,
    );
    expect(find.byType(DragFeedbackChip), findsNothing);
    await gesture.up();
    await rig.play.settle(tester);

    await tester.longPress(rowOf('Song 1.1'));
    await tester.pumpAndSettle();
    expect(find.byType(DragFeedbackChip), findsNothing);
    expect(find.text('Play next'), findsOneWidget);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('the feedback chip shows a title or the plural count', (
    tester,
  ) async {
    final rig = await DndRig.pump(tester, queuePanel: false);
    final chip = find.byType(DragFeedbackChip);

    var gesture = await startDrag(tester, rowOf('Song 1.1'));
    expect(
      find.descendant(of: chip, matching: find.text('Song 1.1')),
      findsOneWidget,
    );
    await gesture.up();
    await rig.play.settle(tester);

    await click(tester, 'Song 1.1');
    await click(tester, 'Song 1.3', modifier: LogicalKeyboardKey.shiftLeft);
    gesture = await startDrag(tester, rowOf('Song 1.2'));
    expect(
      find.descendant(of: chip, matching: find.text('3 tracks')),
      findsOneWidget,
    );
    await gesture.up();
    await rig.play.settle(tester);
    await rig.close(tester);
  }, variant: linux);
}
