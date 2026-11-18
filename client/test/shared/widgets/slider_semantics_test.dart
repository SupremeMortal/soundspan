// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/features/player/player.dart';

import '../../helpers/pump_app.dart';

void main() {
  const length = Duration(minutes: 3, seconds: 41);

  void act(WidgetTester tester, Finder finder, SemanticsAction action) {
    final node = tester.getSemantics(finder);
    node.owner!.performAction(node.id, action);
  }

  group('SeekBar', () {
    Future<List<Duration>> pumpSeekBar(
      WidgetTester tester,
      Duration position,
    ) async {
      final seeks = <Duration>[];
      await tester.pumpApp(
        Material(
          child: Center(
            child: SizedBox(
              width: 300,
              child: SeekBar(
                position: position,
                duration: length,
                status: EngineStatus.ready,
                playing: false,
                onSeek: seeks.add,
              ),
            ),
          ),
        ),
      );
      return seeks;
    }

    Finder bar() => find.byKey(SeekBar.barKey);

    testWidgets('the value of a 3:41 track at 1:05 reads "1:05 of 3:41"', (
      tester,
    ) async {
      await pumpSeekBar(tester, const Duration(minutes: 1, seconds: 5));
      expect(
        tester.getSemantics(bar()),
        isSemantics(
          isSlider: true,
          label: 'Seek',
          value: '1:05 of 3:41',
          increasedValue: '1:10 of 3:41',
          decreasedValue: '1:00 of 3:41',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
    });

    testWidgets('increase and decrease move 5 seconds', (tester) async {
      final seeks = await pumpSeekBar(
        tester,
        const Duration(minutes: 1, seconds: 5),
      );
      act(tester, bar(), SemanticsAction.increase);
      await tester.pump();
      act(tester, bar(), SemanticsAction.decrease);
      await tester.pump();
      expect(seeks, const [
        Duration(minutes: 1, seconds: 10),
        Duration(minutes: 1, seconds: 5),
      ]);
    });

    testWidgets('decrease clamps at 0 and increase at the duration', (
      tester,
    ) async {
      final atStart = await pumpSeekBar(tester, const Duration(seconds: 2));
      act(tester, bar(), SemanticsAction.decrease);
      await tester.pump();
      expect(atStart, [Duration.zero]);

      final atEnd = await pumpSeekBar(
        tester,
        const Duration(minutes: 3, seconds: 39),
      );
      act(tester, bar(), SemanticsAction.increase);
      await tester.pump();
      expect(atEnd, [length]);
    });
  });

  group('VolumeSlider', () {
    Future<List<double>> pumpVolume(WidgetTester tester, double value) async {
      final changes = <double>[];
      await tester.pumpApp(
        Material(
          child: Center(
            child: SizedBox(
              width: 128,
              child: VolumeSlider(value: value, onChanged: changes.add),
            ),
          ),
        ),
      );
      return changes;
    }

    Finder slider() => find.byType(VolumeSlider);

    testWidgets('is a slider with its value in percent', (tester) async {
      await pumpVolume(tester, 0.5);
      expect(
        tester.getSemantics(slider()),
        isSemantics(
          isSlider: true,
          label: 'Volume',
          value: '50%',
          increasedValue: '55%',
          decreasedValue: '45%',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
    });

    testWidgets('increase and decrease move 5 %', (tester) async {
      final changes = await pumpVolume(tester, 0.5);
      act(tester, slider(), SemanticsAction.increase);
      act(tester, slider(), SemanticsAction.decrease);
      expect(changes, [closeTo(0.55, 1e-9), closeTo(0.45, 1e-9)]);
    });

    testWidgets('decrease clamps at 0 and increase at 100 %', (tester) async {
      final low = await pumpVolume(tester, 0.02);
      act(tester, slider(), SemanticsAction.decrease);
      expect(low, [0.0]);

      final high = await pumpVolume(tester, 0.98);
      act(tester, slider(), SemanticsAction.increase);
      expect(high, [1.0]);
    });
  });
}
