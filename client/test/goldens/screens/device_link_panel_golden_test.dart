// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/profile/server_admission_gate.dart';
import 'package:soundspan/features/connect/ui/device_link_panel.dart';
import 'package:soundspan/platform/device_info/device_info.dart';

import '../../features/connect/ui/device_link_fakes.dart';
import '../../helpers/golden.dart';

void main() {
  goldenMatrix(
    'device_link_panel',
    overrides: [
      deviceLinkSignInProvider.overrideWithValue(FakeDeviceLinkSignIn()),
      deviceInfoProvider.overrideWithValue(
        const DeviceInfo(osLabel: 'Linux', isMobile: false, hostName: 'studio'),
      ),
    ],
    builder: (_) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DeviceLinkPanel(
            baseUrl: Uri.parse(linkBase),
            onLinked: (_) async {},
          ),
        ),
      ),
    ),
  );
}
