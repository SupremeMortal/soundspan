// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

import '../../helpers/fakes/fake_download_controller.dart';
import '../../helpers/play_rig.dart';
import '../../helpers/pump_app.dart';

const _spoken = 'Come Together, The Beatles, 3 minutes 41 seconds';

TrackRow _row({
  bool enabled = true,
  bool liked = false,
  PlaybackId? playbackId,
  VoidCallback? onTap,
  VoidCallback? onToggleLike,
  VoidCallback? onAddToQueue,
  void Function(Offset?)? onMenu,
}) => TrackRow(
  title: 'Come Together',
  artist: 'The Beatles',
  duration: const Duration(minutes: 3, seconds: 41),
  leading: const TrackRowLeading.index(1),
  playbackId: playbackId,
  enabled: enabled,
  disabledReason: enabled ? null : 'Not playable',
  liked: liked,
  onTap: onTap ?? () {},
  onToggleLike: onToggleLike,
  onAddToQueue: onAddToQueue,
  onMenu: onMenu,
);

SemanticsNode _node(WidgetTester tester) =>
    tester.getSemantics(find.byType(TrackRow));

List<String> _actionLabels(WidgetTester tester) => [
  for (final id
      in _node(tester).getSemanticsData().customSemanticsActionIds ??
          const <int>[])
    CustomSemanticsAction.getAction(id)!.label!,
];

void _perform(WidgetTester tester, String label) {
  final id = _node(tester)
      .getSemanticsData()
      .customSemanticsActionIds!
      .firstWhere((id) => CustomSemanticsAction.getAction(id)!.label == label);
  final node = _node(tester);
  node.owner!.performAction(node.id, SemanticsAction.customAction, id);
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    TrackRow row, {
    List<Override> overrides = const [],
  }) async {
    await tester.pumpApp(
      Material(
        child: Align(alignment: Alignment.topCenter, child: row),
      ),
      overrides: overrides,
    );
    await tester.pump();
  }

  group('merged label', () {
    testWidgets('a plain row reads title, artist and spoken duration', (
      tester,
    ) async {
      await pump(tester, _row());
      expect(_node(tester), isSemantics(label: _spoken));
    });

    testWidgets('a downloaded row adds "downloaded"', (tester) async {
      final downloads = FakeDownloadController()
        ..setItem(
          const TrackItemKey('p1'),
          itemState(DownloadStatus.completed),
        );
      await pump(
        tester,
        _row(playbackId: const PlaybackId('p1')),
        overrides: downloads.overrides(),
      );
      expect(_node(tester), isSemantics(label: '$_spoken, downloaded'));
    });

    testWidgets('a liked row adds "liked"', (tester) async {
      await pump(tester, _row(liked: true, onToggleLike: () {}));
      expect(_node(tester), isSemantics(label: '$_spoken, liked'));
    });

    testWidgets('the playing row adds "now playing"', (tester) async {
      final rig = PlayRig();
      await pump(
        tester,
        _row(playbackId: const PlaybackId('pb-1')),
        overrides: rig.overrides,
      );
      unawaited(
        rig.controller.playItems([
          const QueueItem.track(
            queueItemId: 'q-1',
            track: Track(
              meta: TrackMeta(
                title: 'Come Together',
                artist: 'The Beatles',
                album: 'Abbey Road',
                durationSec: 221,
              ),
              playbackId: PlaybackId('pb-1'),
            ),
            context: QueueContext(kind: QueueContextKind.album),
          ),
        ]),
      );
      await rig.settle(tester);
      expect(_node(tester), isSemantics(label: '$_spoken, now playing'));
      await rig.close(tester);
    });

    testWidgets('a disabled row ends with its reason, has no tap action and '
        'is marked disabled', (tester) async {
      var taps = 0;
      await pump(
        tester,
        _row(enabled: false, liked: true, onTap: () => taps++),
      );
      expect(
        _node(tester),
        isSemantics(
          label: '$_spoken, liked, Not playable',
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      expect(taps, 0);
    });
  });

  group('custom actions', () {
    testWidgets('each action invokes its callback once', (tester) async {
      var likes = 0;
      var queued = 0;
      var menus = 0;
      await pump(
        tester,
        _row(
          onToggleLike: () => likes++,
          onAddToQueue: () => queued++,
          onMenu: (_) => menus++,
        ),
      );
      expect(_actionLabels(tester), ['Like', 'Add to queue', 'More options']);

      _perform(tester, 'Like');
      _perform(tester, 'Add to queue');
      _perform(tester, 'More options');
      expect((likes, queued, menus), (1, 1, 1));
    });

    testWidgets('a liked row offers "Remove like"', (tester) async {
      await pump(tester, _row(liked: true, onToggleLike: () {}));
      expect(_actionLabels(tester), ['Remove like']);
    });

    testWidgets('an absent capability removes its action', (tester) async {
      await pump(tester, _row(onToggleLike: () {}, onMenu: (_) {}));
      expect(_actionLabels(tester), ['Like', 'More options']);
    });
  });

  testWidgets('a row is exactly one semantics node: the like and overflow '
      'buttons are out of the tree', (tester) async {
    await pump(
      tester,
      _row(onToggleLike: () {}, onAddToQueue: () {}, onMenu: (_) {}),
    );
    final node = _node(tester);
    expect(node.label, _spoken);
    var descendants = 0;
    node.visitChildren((_) {
      descendants++;
      return true;
    });
    expect(descendants, 0);
    expect(find.bySemanticsLabel('Like'), findsNothing);
    expect(find.bySemanticsLabel('More options'), findsNothing);
    expect(find.byTooltip('More options'), findsOneWidget);
  });
}
