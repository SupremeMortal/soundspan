// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/profile/server_admission_gate.dart';
import 'package:soundspan/features/connect/ui/api_key_form.dart';

import '../../features/connect/ui/api_key_fakes.dart';
import '../../features/connect/ui/device_link_fakes.dart';
import '../../helpers/golden.dart';
import '../../helpers/pump_app.dart';

void main() {
  goldenMatrix(
    'api_key_form',
    sizes: const [TestSizes.compact, TestSizes.expanded],
    overrides: [apiKeySignInProvider.overrideWithValue(FakeApiKeySignIn())],
    builder: (_) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ApiKeyForm(
            baseUrl: Uri.parse(linkBase),
            onSignedIn: (_) async {},
          ),
        ),
      ),
    ),
  );
}
