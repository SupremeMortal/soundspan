// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/golden.dart';

/// The bundled font families tests render with, by asset.
const Map<String, String> _fonts = {
  'Montserrat': 'assets/fonts/Montserrat-VariableFont_wght.ttf',
  'Turret Road': 'assets/fonts/TurretRoad-ExtraBold.ttf',
  'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
};

/// Loads the real fonts, then runs every test under the soundspan
/// [AlchemistConfig].
///
/// Goldens are compared only on Linux: elsewhere golden tests still build
/// and pump, but the comparison is skipped and nothing is written.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final MapEntry(key: family, value: asset) in _fonts.entries) {
    await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
  }
  if (!Platform.isLinux) {
    goldenFileComparator = SkippingGoldenComparator();
  }
  await AlchemistConfig.runWithConfig(
    config: soundspanAlchemistConfig,
    run: testMain,
  );
}
