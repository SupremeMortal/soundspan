// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// The engine conformance suite against the real engine of the device it
// runs on, with tones from a local tone server. Run by the jobs of
// .github/workflows/client-device-tests.yml:
//
//   flutter test integration_test/engine_conformance_test.dart -d <device>
//
// and on the web, with `dart tool/tone_server.dart` running:
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/engine_conformance_test.dart -d chrome \
//     --dart-define=TONE_SERVER=<address printed by the tone server>

@Tags(['engine'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/core/playback/engine_conformance.dart';
import 'support/device_engine_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late DeviceEngineSetup setup;
  setUpAll(() async => setup = await DeviceEngineSetup.start());
  tearDownAll(() => setup.close());

  runEngineConformance(
    'device',
    () => setup.harness(),
    declare: (description, body) => testWidgets(
      description,
      (_) => body(),
      timeout: const Timeout(Duration(minutes: 2)),
    ),
  );
}
