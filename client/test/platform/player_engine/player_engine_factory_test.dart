// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/platform/player_engine/player_engine_factory_io.dart';

void main() {
  test('Windows and Linux have no engine yet', () {
    expect(() => playerEngineFor('windows'), throwsUnsupportedError);
    expect(() => playerEngineFor('linux'), throwsUnsupportedError);
  });

  test('an unknown platform has no engine', () {
    expect(() => playerEngineFor('fuchsia'), throwsUnsupportedError);
  });
}
