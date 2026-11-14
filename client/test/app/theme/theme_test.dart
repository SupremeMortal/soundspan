// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/theme.dart';
import 'package:soundspan/main.dart';

Future<BuildContext> _pumpThemed(WidgetTester tester, ThemeData theme) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  testWidgets('dark theme exposes the dark surfaceRaised', (tester) async {
    final context = await _pumpThemed(tester, SoundspanTheme.dark);
    expect(context.colors.surfaceRaised, SoundspanColors.dark.surfaceRaised);
    expect(context.colors.surfaceRaised.toARGB32(), 0xFF0F0F0F);
  });

  testWidgets('light theme exposes the light surfaceRaised', (tester) async {
    final context = await _pumpThemed(tester, SoundspanTheme.light);
    expect(context.colors.surfaceRaised.toARGB32(), 0xFFFAFAFA);
  });

  test('each theme uses Material 3, its scheme and ground as background', () {
    final themes = {
      SoundspanTheme.dark: (SoundspanColors.dark, Brightness.dark),
      SoundspanTheme.light: (SoundspanColors.light, Brightness.light),
      SoundspanTheme.darkHighContrast: (
        SoundspanColors.darkHighContrast,
        Brightness.dark,
      ),
      SoundspanTheme.lightHighContrast: (
        SoundspanColors.lightHighContrast,
        Brightness.light,
      ),
    };
    for (final MapEntry(key: theme, value: (colors, brightness))
        in themes.entries) {
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, brightness);
      expect(theme.extension<SoundspanColors>(), colors);
      expect(theme.scaffoldBackgroundColor, colors.ground);
      expect(theme.colorScheme.primary, colors.accent);
    }
  });

  testWidgets('the app resolves the high-contrast dark tokens when the '
      'platform asks for high contrast', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(highContrast: true);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(const SoundspanApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.text('soundspan'));
    expect(context.colors.line, SoundspanColors.darkHighContrast.line);
    expect(context.colors.line.toARGB32(), 0xFF333333);
  });

  testWidgets('the app follows the platform brightness', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(const SoundspanApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.text('soundspan'));
    expect(context.colors, SoundspanColors.light);
  });

  testWidgets('a stock FilledButton paints with accent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SoundspanTheme.dark,
        home: Scaffold(
          body: FilledButton(onPressed: () {}, child: const Text('Play')),
        ),
      ),
    );
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, SoundspanColors.dark.accent);
  });
}
