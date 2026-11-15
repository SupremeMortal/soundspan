// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/platform/player_engine/player_engine_factory_io.dart';

void main() {
  test('Windows and Linux play through MediaKitEngine', () {
    expect(playerEngineKindFor('windows'), PlayerEngineKind.mediaKit);
    expect(playerEngineKindFor('linux'), PlayerEngineKind.mediaKit);
  });

  test('Android, iOS and macOS play through JustAudioEngine', () {
    expect(playerEngineKindFor('android'), PlayerEngineKind.justAudio);
    expect(playerEngineKindFor('ios'), PlayerEngineKind.justAudio);
    expect(playerEngineKindFor('macos'), PlayerEngineKind.justAudioReloading);
  });

  test('an unknown platform has no engine', () {
    expect(playerEngineKindFor('fuchsia'), isNull);
    expect(() => playerEngineFor('fuchsia'), throwsUnsupportedError);
  });
}
