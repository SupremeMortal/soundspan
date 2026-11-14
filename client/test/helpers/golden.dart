// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:alchemist/alchemist.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/extensions.dart';

import 'pump_app.dart';

/// The [AlchemistConfig] every test runs under (`flutter_test_config.dart`).
///
/// One image set exists, rendered with real fonts on Linux and stored beside
/// each test under `goldens/`. The obscured-text CI variant is off.
final AlchemistConfig soundspanAlchemistConfig = AlchemistConfig(
  platformGoldensConfig: PlatformGoldensConfig(
    platforms: {HostPlatform.linux},
    filePathResolver: (fileName, _) => goldenPath(fileName),
  ),
  ciGoldensConfig: const CiGoldensConfig(enabled: false),
);

/// The path, relative to the test file, of the golden image [fileName].
String goldenPath(String fileName) => 'goldens/$fileName.png';

/// A comparator for hosts other than Linux: every comparison passes and
/// nothing is written, so golden tests still build and pump.
class SkippingGoldenComparator extends GoldenFileComparator {
  /// Creates the comparator.
  new();

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async => true;

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {}
}

/// The file name, without extension, of one image of a [goldenMatrix]:
/// `<name>.<width>.<theme>[.x<scale>][.<locale>]`.
///
/// The scale is left out at 1.0 and the locale at `en`. The theme is `dark`
/// or `light`, with `-hc` for the high-contrast variant.
String goldenFileName(
  String name, {
  required Size size,
  required ThemeMode theme,
  bool highContrast = false,
  double textScale = 1.0,
  Locale locale = const Locale('en'),
}) {
  final scale = textScale == textScale.roundToDouble()
      ? textScale.toInt().toString()
      : textScale.toString();
  return [
    name,
    size.width.toInt(),
    '${theme.name}${highContrast ? '-hc' : ''}',
    if (textScale != 1.0) 'x$scale',
    if (locale != const Locale('en')) locale.toLanguageTag(),
  ].join('.');
}

/// Declares one golden test, tagged `golden`, per combination of [sizes],
/// [themes], [highContrast], [textScales] and [locales].
///
/// Each image is the whole surface: [builder]'s widget pumped with
/// [PumpApp.pumpApp] on the theme's `ground` colour. Files are named by
/// [goldenFileName] and stored under `goldens/` beside the test.
void goldenMatrix(
  String name, {
  required WidgetBuilder builder,
  List<Size> sizes = const [
    TestSizes.compact,
    TestSizes.medium,
    TestSizes.expanded,
  ],
  List<ThemeMode> themes = const [ThemeMode.dark, ThemeMode.light],
  List<bool> highContrast = const [false],
  List<double> textScales = const [1.0],
  List<Locale> locales = const [Locale('en')],
}) {
  for (final size in sizes) {
    for (final theme in themes) {
      for (final contrast in highContrast) {
        for (final textScale in textScales) {
          for (final locale in locales) {
            final fileName = goldenFileName(
              name,
              size: size,
              theme: theme,
              highContrast: contrast,
              textScale: textScale,
              locale: locale,
            );
            testWidgets(fileName, tags: ['golden'], (tester) async {
              final boundary = GlobalKey();
              await tester.pumpApp(
                RepaintBoundary(
                  key: boundary,
                  child: Builder(
                    builder: (context) => Material(
                      color: context.colors.ground,
                      child: builder(context),
                    ),
                  ),
                ),
                size: size,
                theme: theme,
                highContrast: contrast,
                textScale: textScale,
                locale: locale,
              );
              await tester.pumpAndSettle();
              await expectLater(
                find.byKey(boundary),
                matchesGoldenFile(goldenPath(fileName)),
              );
            });
          }
        }
      }
    }
  }
}
