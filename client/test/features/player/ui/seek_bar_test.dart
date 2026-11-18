// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/shared/util/duration_format.dart';

import '../../../helpers/pump_app.dart';

const _length = Duration(minutes: 3, seconds: 41);
const double _width = 300;

void main() {
  late List<Duration> seeks;

  setUp(() => seeks = []);

  Widget bar({
    Duration position = const Duration(minutes: 1, seconds: 5),
    Duration buffered = Duration.zero,
    Duration? duration = _length,
    EngineStatus status = EngineStatus.ready,
    bool playing = false,
    bool reduceMotion = false,
  }) => Center(
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: SizedBox(
          width: _width,
          child: SeekBar(
            position: position,
            buffered: buffered,
            duration: duration,
            status: status,
            playing: playing,
            onSeek: seeks.add,
            showTimes: true,
          ),
        ),
      ),
    ),
  );

  Finder track() => find.byKey(SeekBar.barKey);

  double trackWidth(WidgetTester tester) => tester.getSize(track()).width;

  /// The track, then the buffered range, then the played part: the bar
  /// at [index] in that order is painted in [color] up to [right].
  PaintPattern barOf(int index, Color color, double right) {
    final pattern = paints;
    for (var i = 0; i < index; i++) {
      pattern.rrect();
    }
    return pattern..rrect(
      color: color,
      rrect: RRect.fromLTRBR(
        0,
        (SeekBar.height - SeekBar.trackHeight) / 2,
        right,
        (SeekBar.height + SeekBar.trackHeight) / 2,
        const Radius.circular(SeekBar.trackHeight / 2),
      ),
    );
  }

  testWidgets('fill is proportional to the position', (tester) async {
    await tester.pumpApp(bar(position: const Duration(seconds: 221 ~/ 4)));
    final colors = tester.element(track()).colors;
    final width = trackWidth(tester);

    expect(
      tester.renderObject(track()),
      barOf(2, colors.brand, width * 55 / 221),
    );
  });

  testWidgets('buffered range is drawn in lineStrong', (tester) async {
    await tester.pumpApp(bar(buffered: const Duration(minutes: 2)));
    final colors = tester.element(track()).colors;
    final width = trackWidth(tester);

    expect(
      tester.renderObject(track()),
      barOf(1, colors.lineStrong, width * 120 / 221),
    );
  });

  testWidgets('label advances between snapshots while playing', (tester) async {
    await tester.pumpApp(bar(playing: true));
    expect(find.text('1:05'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('1:07'), findsOneWidget);
    expect(tester.getSemantics(track()), isSemantics(value: '1:07 of 3:41'));
  });

  testWidgets('a new snapshot moves the label to its position', (tester) async {
    await tester.pumpApp(bar(playing: true));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('1:08'), findsOneWidget);

    await tester.pumpApp(
      bar(position: const Duration(minutes: 2), playing: true),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('2:00'), findsOneWidget);
  });

  for (final (name, status, playing) in [
    ('paused', EngineStatus.ready, false),
    ('buffering', EngineStatus.buffering, true),
  ]) {
    testWidgets('does not advance while $name', (tester) async {
      await tester.pumpApp(bar(status: status, playing: playing));

      await tester.pump(const Duration(seconds: 3));

      expect(find.text('1:05'), findsOneWidget);
    });
  }

  testWidgets('does not interpolate with reduced motion', (tester) async {
    await tester.pumpApp(bar(playing: true, reduceMotion: true));

    await tester.pump(const Duration(seconds: 3));

    expect(find.text('1:05'), findsOneWidget);
  });

  testWidgets('drag shows the dragged position and seeks once on release', (
    tester,
  ) async {
    await tester.pumpApp(bar());
    final left = tester.getTopLeft(track());
    final width = trackWidth(tester);

    final gesture = await tester.startGesture(
      left + Offset(width * 0.25, SeekBar.height / 2),
    );
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveTo(left + Offset(width / 2, SeekBar.height / 2));
    await tester.pump();

    expect(find.text(formatTrackDuration(_length * 0.5)), findsOneWidget);
    expect(seeks, isEmpty);

    await gesture.up();
    await tester.pump();

    expect(seeks, hasLength(1));
    expect(
      seeks.single.inMilliseconds,
      closeTo((_length * 0.5).inMilliseconds, 1),
    );
  });

  testWidgets('arrows seek 5 s and clamp at both ends', (tester) async {
    await tester.pumpApp(bar());
    Focus.of(tester.element(track())).requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(seeks, const [Duration(seconds: 70), Duration(seconds: 65)]);

    seeks.clear();
    await tester.pumpApp(bar(position: const Duration(seconds: 2)));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(seeks, const [Duration.zero]);

    seeks.clear();
    await tester.pumpApp(bar(position: const Duration(seconds: 219)));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(seeks, const [_length]);
  });

  testWidgets('semantics: a slider at "1:05 of 3:41"', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(bar());

    expect(
      tester.getSemantics(track()),
      isSemantics(
        isSlider: true,
        isEnabled: true,
        label: 'Seek',
        value: '1:05 of 3:41',
        increasedValue: '1:10 of 3:41',
        decreasedValue: '1:00 of 3:41',
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );

    tester.semantics.performAction(
      find.semantics.byLabel('Seek'),
      SemanticsAction.increase,
    );
    expect(seeks, const [Duration(seconds: 70)]);
    handle.dispose();
  });

  testWidgets('unknown duration: disabled, no thumb, no seek', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(bar(duration: null));

    expect(
      tester.getSemantics(track()),
      isSemantics(
        isSlider: true,
        isEnabled: false,
        hasIncreaseAction: false,
        hasDecreaseAction: false,
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: tester.getCenter(track()));
    await tester.pump();
    expect(tester.renderObject(track()), isNot(paints..circle()));

    await tester.tap(track());
    expect(seeks, isEmpty);
    handle.dispose();
  });

  testWidgets('thumb shows on hover only', (tester) async {
    await tester.pumpApp(bar());
    expect(tester.renderObject(track()), isNot(paints..circle()));

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: tester.getCenter(track()));
    await tester.pump();

    expect(tester.renderObject(track()), paints..circle());
  });
}
