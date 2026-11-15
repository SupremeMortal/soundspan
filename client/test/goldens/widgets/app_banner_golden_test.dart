// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/widgets/app_banner.dart';

import '../../helpers/golden.dart';

void main() {
  // Offline, link expiring with an action and dismiss, and a server notice
  // with dismiss.
  goldenMatrix(
    'app_banner',
    sizes: const [Size(390, 320), Size(800, 240), Size(1440, 240)],
    builder: (_) => Column(
      children: [
        const AppBanner(
          kind: AppBannerKind.offline,
          message: 'You’re offline. Showing what is saved on this device.',
        ),
        const SizedBox(height: 16),
        AppBanner(
          kind: AppBannerKind.linkExpiring,
          message: 'This device’s link expires in 3 days.',
          actionLabel: 'Re-link',
          onAction: () {},
          onDismiss: () {},
        ),
        const SizedBox(height: 16),
        AppBanner(
          kind: AppBannerKind.serverNotice,
          message: 'This server is newer than this app was tested with.',
          onDismiss: () {},
        ),
      ],
    ),
  );
}
