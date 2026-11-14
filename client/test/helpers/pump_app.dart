// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/theme.dart';
import 'package:soundspan/shared/clock.dart';

import 'fake_clock.dart';

/// Logical sizes for the three window classes.
abstract final class TestSizes {
  /// A compact (phone) window.
  static const compact = Size(390, 844);

  /// A medium (tablet portrait) window.
  static const medium = Size(800, 1280);

  /// An expanded (desktop) window.
  static const expanded = Size(1440, 900);
}

/// Pumps a widget inside the soundspan app scaffolding.
extension PumpApp on WidgetTester {
  /// Pumps [child] as the home of a `MaterialApp` with the four
  /// `SoundspanTheme` variants, inside a provider scope, and returns that
  /// scope's container.
  ///
  /// The view is [size] at a device pixel ratio of 1.0; [theme] picks dark
  /// or light, [highContrast] the high-contrast variant. The surface and the
  /// platform values are reset when the test ends. The clock is a
  /// [FakeClock] ([clock], or a new one); [overrides] are applied after the
  /// defaults and win over them.
  Future<ProviderContainer> pumpApp(
    Widget child, {
    Size size = TestSizes.compact,
    ThemeMode theme = ThemeMode.dark,
    bool highContrast = false,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    List<Override> overrides = const [],
    FakeClock? clock,
  }) async {
    view
      ..physicalSize = size
      ..devicePixelRatio = 1.0;
    addTearDown(view.reset);
    platformDispatcher
      ..textScaleFactorTestValue = textScale
      ..accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
        highContrast: highContrast,
      );
    addTearDown(platformDispatcher.clearAllTestValues);

    final defaults = <Override>[
      clockProvider.overrideWithValue(clock ?? FakeClock()),
    ];
    final container = ProviderContainer(
      overrides: [
        for (final override in defaults)
          if (!overrides.any((o) => identical(o.origin, override.origin)))
            override,
        ...overrides,
      ],
    );
    addTearDown(container.dispose);

    await pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: SoundspanTheme.light,
          darkTheme: SoundspanTheme.dark,
          highContrastTheme: SoundspanTheme.lightHighContrast,
          highContrastDarkTheme: SoundspanTheme.darkHighContrast,
          themeMode: theme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      ),
    );
    return container;
  }
}
