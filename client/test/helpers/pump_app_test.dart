// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/shared/clock.dart';

import 'fake_clock.dart';
import 'pump_app.dart';

/// Captures the [BuildContext] of the pumped child.
class _Probe extends StatelessWidget {
  const new(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(context);
    return const SizedBox.expand();
  }
}

Future<BuildContext> _pumpProbe(
  WidgetTester tester, {
  Size size = TestSizes.compact,
  ThemeMode theme = ThemeMode.dark,
  bool highContrast = false,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
}) async {
  late BuildContext captured;
  await tester.pumpApp(
    _Probe((context) => captured = context),
    size: size,
    theme: theme,
    highContrast: highContrast,
    locale: locale,
    textScale: textScale,
  );
  return captured;
}

void main() {
  group('pumpApp', () {
    for (final size in [
      TestSizes.compact,
      TestSizes.medium,
      TestSizes.expanded,
    ]) {
      testWidgets('the surface is $size at a pixel ratio of 1', (tester) async {
        final context = await _pumpProbe(tester, size: size);
        expect(MediaQuery.sizeOf(context), size);
        expect(MediaQuery.devicePixelRatioOf(context), 1.0);
        expect(tester.getSize(find.byType(_Probe)), size);
      });
    }

    testWidgets('dark theme gives a dark Theme', (tester) async {
      final context = await _pumpProbe(tester);
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(context.colors, SoundspanColors.dark);
    });

    testWidgets('light theme gives a light Theme', (tester) async {
      final context = await _pumpProbe(tester, theme: ThemeMode.light);
      expect(Theme.of(context).brightness, Brightness.light);
      expect(context.colors, SoundspanColors.light);
    });

    testWidgets('highContrast selects the dark high-contrast colours', (
      tester,
    ) async {
      final dark = await _pumpProbe(tester, highContrast: true);
      expect(dark.colors, SoundspanColors.darkHighContrast);
    });

    testWidgets('highContrast selects the light high-contrast colours', (
      tester,
    ) async {
      final light = await _pumpProbe(
        tester,
        theme: ThemeMode.light,
        highContrast: true,
      );
      expect(light.colors, SoundspanColors.lightHighContrast);
    });

    testWidgets('textScale is visible through MediaQuery', (tester) async {
      final context = await _pumpProbe(tester, textScale: 2);
      expect(MediaQuery.textScalerOf(context).scale(10), 20);
    });

    testWidgets('locale reaches Localizations', (tester) async {
      final context = await _pumpProbe(tester);
      expect(Localizations.localeOf(context), const Locale('en'));
    });

    testWidgets('returns the container of the pumped tree', (tester) async {
      late BuildContext captured;
      final container = await tester.pumpApp(
        _Probe((context) => captured = context),
      );
      expect(ProviderScope.containerOf(captured), same(container));
    });

    testWidgets('a caller override wins over the default', (tester) async {
      final mine = FakeClock(start: DateTime.utc(2031));
      final container = await tester.pumpApp(
        const SizedBox(),
        overrides: [clockProvider.overrideWithValue(mine)],
      );
      expect(container.read(clockProvider), same(mine));
    });
  });

  group('after a pumpApp test', () {
    late Size defaultSize;
    late double defaultRatio;

    setUpAll(() {
      final view = TestWidgetsFlutterBinding.ensureInitialized()
          .platformDispatcher
          .implicitView!;
      defaultSize = view.physicalSize;
      defaultRatio = view.devicePixelRatio;
    });

    testWidgets('pumps at the expanded size with high contrast', (
      tester,
    ) async {
      await _pumpProbe(
        tester,
        size: TestSizes.expanded,
        highContrast: true,
        textScale: 2,
      );
      expect(tester.view.physicalSize, TestSizes.expanded);
    });

    testWidgets('the next test sees the default surface', (tester) async {
      expect(tester.view.physicalSize, defaultSize);
      expect(tester.view.devicePixelRatio, defaultRatio);
      expect(
        tester.platformDispatcher.accessibilityFeatures.highContrast,
        isFalse,
      );
      expect(tester.platformDispatcher.textScaleFactor, 1.0);
    });
  });

  group('fonts', () {
    testWidgets('text renders with Montserrat, not the test font', (
      tester,
    ) async {
      const sample = 'Listen together, anywhere.';
      Future<double> widthIn(String family) async {
        final key = GlobalKey();
        await tester.pumpApp(
          Center(
            child: Text(
              sample,
              key: key,
              style: TextStyle(fontFamily: family, fontSize: 10),
            ),
          ),
        );
        return tester.getSize(find.byKey(key)).width;
      }

      final montserrat = await widthIn('Montserrat');
      // The test font gives every glyph the width of the font size.
      final testFont = await widthIn('FlutterTest');
      expect(testFont, sample.length * 10);
      expect(montserrat, isNot(testFont));
    });
  });
}
