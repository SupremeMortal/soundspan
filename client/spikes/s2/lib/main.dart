// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/widgets.dart';

/// Spike S2 harness app; the integration test drives the player.
void main() {
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: Text('spike s2')),
    ),
  );
}
