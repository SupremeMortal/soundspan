// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide RepeatMode;
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
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
    ThemeMode theme = ThemeMode.dark,
  }) async {
    rig ??= PlayerRig();
    await tester.pumpApp(
      const Align(alignment: Alignment.bottomCenter, child: PlayerBar()),
      size: TestSizes.expanded,
      theme: theme,
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
    expect(
      tester.getSize(find.byType(PlayerBar)).height,
      PlayerBar.minHeightFor(pointer: false),
    );
    await rig.close(tester);
  });

  testWidgets('with touch input play/pause keeps its 48 px circle', (
    tester,
  ) async {
    final rig = await pumpBar(tester);

    expect(
      tester.getSize(find.byKey(PlayerTransport.playPauseKey)),
      const Size.square(PlayerBar.playButtonSize),
    );
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

  group('an episode', () {
    Future<PlayerRig> pumpEpisode(
      WidgetTester tester, {
      MemoryDeviceSettings? settings,
    }) async {
      final rig = PlayerRig(ids: const ['e', 'a'], settings: settings);
      await pumpBar(tester, rig: rig, start: false);
      await rig.start(tester, items: [playerEpisode('e')]);
      return rig;
    }

    testWidgets('shows skip and speed and hides shuffle, repeat, previous '
        'and next', (tester) async {
      final rig = await pumpEpisode(tester);

      expect(find.text('Episode e'), findsOneWidget);
      expect(find.text('The Show'), findsOneWidget);
      expect(find.byTooltip('Skip back 15 seconds'), findsOneWidget);
      expect(find.byTooltip('Skip forward 15 seconds'), findsOneWidget);
      expect(find.byKey(PlayerTransport.speedKey), findsOneWidget);
      expect(find.text('1×'), findsOneWidget);
      for (final tooltip in ['Shuffle', 'Previous', 'Next', 'Repeat']) {
        expect(find.byTooltip(tooltip), findsNothing, reason: tooltip);
      }
      await rig.close(tester);
    });

    testWidgets('a track shows the opposite', (tester) async {
      final rig = await pumpBar(tester);

      expect(find.byTooltip('Shuffle'), findsOneWidget);
      expect(find.byTooltip('Next'), findsOneWidget);
      expect(find.byKey(PlayerTransport.speedKey), findsNothing);
      expect(find.byTooltip('Skip forward 15 seconds'), findsNothing);
      await rig.close(tester);
    });

    testWidgets('skip buttons seek by the stored interval, named in their '
        'labels', (tester) async {
      final settings = MemoryDeviceSettings()
        ..values['playback.skipSeconds'] = 5;
      final rig = PlayerRig(ids: const ['e'], settings: settings);
      await pumpBar(tester, rig: rig, start: false);
      await rig.settle(tester);
      await rig.start(tester, items: [playerEpisode('e')], play: false);

      final semantics = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byTooltip('Skip forward 5 seconds')),
        isA<SemanticsNode>().having(
          (n) => n.tooltip,
          'tooltip',
          'Skip forward 5 seconds',
        ),
      );
      expect(
        tester.getSemantics(find.byTooltip('Skip back 5 seconds')),
        isA<SemanticsNode>().having(
          (n) => n.tooltip,
          'tooltip',
          'Skip back 5 seconds',
        ),
      );
      semantics.dispose();
      await tester.tap(find.byTooltip('Skip forward 5 seconds'));
      await rig.settle(tester);
      expect(rig.harness.calls.last, 'seek(0:00:05.000000)');

      await tester.tap(find.byTooltip('Skip back 5 seconds'));
      await rig.settle(tester);
      expect(rig.harness.calls.last, 'seek(0:00:00.000000)');
      await rig.close(tester);
    });

    testWidgets('the speed menu stores and applies the speed', (tester) async {
      final settings = MemoryDeviceSettings();
      final rig = PlayerRig(ids: const ['e'], settings: settings);
      await pumpBar(tester, rig: rig, start: false);
      await rig.start(tester, items: [playerEpisode('e')], play: false);

      await tester.tap(find.byKey(PlayerTransport.speedKey));
      await tester.pumpAndSettle();
      for (final label in ['0.5×', '0.75×', '1.25×', '2.5×', '3×']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      await tester.tap(find.text('1.5×'));
      await tester.pumpAndSettle();

      expect(settings.values['playback.speed.podcast'], 1.5);
      expect(rig.engine.speed, 1.5);
      expect(find.text('1.5×'), findsOneWidget);
      await rig.close(tester);
    });

    testWidgets('meets the guidelines', (tester) async {
      final rig = await pumpEpisode(tester);

      await expectMeetsGuidelines(tester);
      await rig.close(tester);
    });
  });

  for (final theme in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('meets the guidelines (${theme.name})', (tester) async {
      final rig = await pumpBar(tester, play: false, theme: theme);

      // The artist line is `bodySmall` in `contentSecondary` on
      // `surfaceRaised`, a pair the token table allows at 4.5:1. In light the
      // contrast sampler cannot measure its thin glyphs (doc 11, Golden
      // Tests), so that node alone is exempt there.
      final artist = find.text('The Band a');
      final context = tester.element(artist);
      expect(
        tester.widget<Text>(artist).style?.color,
        context.colors.contentSecondary,
      );
      await expectMeetsGuidelines(
        tester,
        contrastSamplingExempt: [if (theme == ThemeMode.light) artist],
      );
      await rig.close(tester);
    });
  }

  group('with pointer input', () {
    // Reset in the test's own tear-down: the binding checks it is unset
    // before group tear-downs run.
    void usePointer() {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
    }

    const transport = Size.square(PlayerBar.pointerTransportSize);

    testWidgets('play/pause, previous and next are the same 32 px square', (
      tester,
    ) async {
      usePointer();
      final rig = await pumpBar(tester);

      for (final key in [
        PlayerTransport.previousKey,
        PlayerTransport.playPauseKey,
        PlayerTransport.nextKey,
      ]) {
        expect(tester.getSize(find.byKey(key)), transport, reason: '$key');
      }
      for (final tooltip in ['Shuffle', 'Repeat']) {
        expect(tester.getSize(find.byTooltip(tooltip)), transport);
      }
      // The play glyph matches the other transport glyphs.
      final play = find.descendant(
        of: find.byKey(PlayerTransport.playPauseKey),
        matching: find.byType(Icon),
      );
      expect(tester.getSize(play), const Size.square(24));
      await rig.close(tester);
    });

    testWidgets('the bar is the compact height with the quality badge', (
      tester,
    ) async {
      usePointer();
      final rig = await pumpBar(tester);

      expect(find.byType(QualityBadge), findsOneWidget);
      expect(PlayerBar.minHeightFor(pointer: true), 72);
      expect(
        tester.getSize(find.byType(PlayerBar)).height,
        PlayerBar.minHeightFor(pointer: true),
      );
      expect(
        tester.getSize(find.byType(Artwork)),
        const Size.square(PlayerBar.pointerArtworkSize),
      );
      await rig.close(tester);
    });

    testWidgets('the loading ring still rings the smaller circle', (
      tester,
    ) async {
      usePointer();
      final rig = PlayerRig();
      rig.engine.sources[uriOf('a')] = const FakeSource(
        duration: Duration(seconds: 10),
        bufferedAhead: Duration(seconds: 1),
      );
      await pumpBar(tester, rig: rig);
      await rig.controller.seek(const Duration(seconds: 5));
      await rig.settle(tester);

      expect(tester.getSize(find.byKey(PlayPauseButton.ringKey)), transport);
      await rig.close(tester);
    });

    testWidgets('an episode lines up skip, play/pause and speed', (
      tester,
    ) async {
      usePointer();
      final rig = PlayerRig(ids: const ['e', 'a']);
      await pumpBar(tester, rig: rig, start: false);
      await rig.start(tester, items: [playerEpisode('e')]);

      for (final finder in [
        find.byTooltip('Skip back 15 seconds'),
        find.byKey(PlayerTransport.playPauseKey),
        find.byTooltip('Skip forward 15 seconds'),
      ]) {
        expect(tester.getSize(finder), transport);
      }
      expect(
        tester.getSize(find.byKey(PlayerTransport.speedKey)).height,
        PlayerBar.pointerTransportSize,
      );
      expect(
        tester.getSize(find.byType(PlayerBar)).height,
        PlayerBar.minHeightFor(pointer: true),
      );
      await rig.close(tester);
    });

    testWidgets('meets the pointer tap-target guideline', (tester) async {
      usePointer();
      final rig = await pumpBar(tester, play: false);

      final handle = tester.ensureSemantics();
      final evaluation = await const MinimumTapTargetGuideline(
        size: Size.square(Sizes.pointerTarget),
        link: 'doc 09: 32 × 32 pointer target',
      ).evaluate(tester);
      handle.dispose();
      expect(evaluation.passed, isTrue, reason: evaluation.reason);
      await rig.close(tester);
    });
  });
}
