// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide RepeatMode;
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/quality_badge.dart';

import '../../../core/playback/controller/controller_harness.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/memory_device_settings.dart';
import '../../../helpers/pump_app.dart';
import 'player_rig.dart';

void main() {
  Future<PlayerRig> pumpBar(
    WidgetTester tester, {
    PlayerRig? rig,
    bool start = true,
    bool play = true,
  }) async {
    rig ??= PlayerRig();
    await tester.pumpApp(
      const Align(alignment: Alignment.bottomCenter, child: PlayerBar()),
      size: TestSizes.expanded,
      overrides: rig.overrides,
    );
    if (start) await rig.start(tester, play: play);
    return rig;
  }

  testWidgets('shows the current item: title, artist, artwork, badge', (
    tester,
  ) async {
    final rig = await pumpBar(tester);

    expect(find.text('Song a'), findsOneWidget);
    expect(find.text('The Band a'), findsOneWidget);
    expect(tester.widget<Artwork>(find.byType(Artwork)).ref, 'cover-a');
    expect(
      find.descendant(
        of: find.byType(QualityBadge),
        matching: find.text('FLAC · 16/44.1 kHz'),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(find.byType(PlayerBar)).height, PlayerBar.minHeight);
    await rig.close(tester);
  });

  testWidgets('transport buttons call the controller', (tester) async {
    final rig = await pumpBar(tester);
    final calls = rig.harness.calls;

    await tester.tap(find.byTooltip('Pause'));
    await rig.settle(tester);
    expect(rig.controller.snapshot.playing, isFalse);
    expect(find.byTooltip('Play'), findsOneWidget);

    await tester.tap(find.byTooltip('Play'));
    await rig.settle(tester);
    expect(rig.controller.snapshot.playing, isTrue);

    await tester.tap(find.byTooltip('Next'));
    await rig.settle(tester);
    expect(rig.controller.snapshot.current?.queueItemId, 'b');
    expect(find.text('Song b'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous'));
    await rig.settle(tester);
    expect(rig.controller.snapshot.current?.queueItemId, 'a');

    await tester.tap(find.byTooltip('Shuffle'));
    await rig.settle(tester);
    expect(rig.controller.snapshot.queue.isShuffled, isTrue);
    expect(calls, contains('play'));
    await rig.close(tester);
  });

  testWidgets('repeat cycles off, all, one, off', (tester) async {
    final rig = await pumpBar(tester);
    RepeatMode repeat() => rig.controller.snapshot.queue.repeat;

    expect(repeat(), RepeatMode.off);
    await tester.tap(find.byTooltip('Repeat'));
    await rig.settle(tester);
    expect(repeat(), RepeatMode.all);
    await tester.tap(find.byTooltip('Repeat all'));
    await rig.settle(tester);
    expect(repeat(), RepeatMode.one);
    await tester.tap(find.byTooltip('Repeat one'));
    await rig.settle(tester);
    expect(repeat(), RepeatMode.off);
    await rig.close(tester);
  });

  testWidgets('buffering with the play intent shows the ring', (tester) async {
    final rig = PlayerRig();
    rig.engine.sources[uriOf('a')] = const FakeSource(
      duration: Duration(seconds: 10),
      bufferedAhead: Duration(seconds: 1),
    );
    await pumpBar(tester, rig: rig);
    expect(find.byKey(PlayPauseButton.ringKey), findsNothing);

    await rig.controller.seek(const Duration(seconds: 5));
    await rig.settle(tester);

    expect(rig.controller.snapshot.status, EngineStatus.buffering);
    expect(find.byKey(PlayPauseButton.ringKey), findsOneWidget);
    await rig.close(tester);
  });

  testWidgets('volume slider sets the volume, which survives a restart', (
    tester,
  ) async {
    final settings = MemoryDeviceSettings();
    final rig = await pumpBar(tester, rig: PlayerRig(settings: settings));
    final slider = find.byType(Slider);
    expect(tester.widget<Slider>(slider).value, 1.0);

    await tester.tapAt(tester.getCenter(slider));
    await rig.settle(tester);

    final set = rig.controller.volume;
    expect(set, closeTo(0.5, 0.1));
    expect(tester.widget<Slider>(slider).value, set);
    await rig.close(tester);

    final restarted = await pumpBar(tester, rig: PlayerRig(settings: settings));
    expect(tester.widget<Slider>(find.byType(Slider)).value, set);
    await restarted.close(tester);
  });

  testWidgets('position updates do not rebuild the bar', (tester) async {
    final rig = await pumpBar(tester);
    final title = tester.widget<Text>(find.text('Song a'));
    final elapsedBefore = find.text('0:00');
    expect(elapsedBefore, findsOneWidget);

    for (var i = 0; i < 10; i++) {
      await rig.advance(tester, const Duration(milliseconds: 300));
    }

    expect(find.text('0:03'), findsOneWidget);
    expect(identical(tester.widget<Text>(find.text('Song a')), title), isTrue);
    await rig.close(tester);
  });

  testWidgets('empty queue renders nothing', (tester) async {
    final rig = await pumpBar(tester, start: false);
    await rig.settle(tester);

    expect(tester.getSize(find.byType(PlayerBar)), Size.zero);
    expect(find.byType(IconButton), findsNothing);
    await rig.close(tester);
  });

  testWidgets('meets the guidelines', (tester) async {
    final rig = await pumpBar(tester, play: false);

    await expectMeetsGuidelines(tester);
    await rig.close(tester);
  });
}
