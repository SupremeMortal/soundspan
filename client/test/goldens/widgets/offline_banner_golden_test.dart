// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/shared/widgets/offline_banner.dart';

import '../../helpers/fake_reachability.dart';
import '../../helpers/golden.dart';

void main() {
  for (final state in [
    Reachability.noNetwork,
    Reachability.serverUnreachable,
    Reachability.forcedOffline,
  ]) {
    goldenMatrix(
      'offline_banner.${state.name}',
      sizes: const [Size(390, 120), Size(1440, 120)],
      overrides: [
        reachabilityProvider.overrideWithValue(
          FakeReachability(initial: state),
        ),
      ],
      builder: (_) =>
          const Align(alignment: Alignment.topCenter, child: OfflineBanner()),
    );
  }
}
