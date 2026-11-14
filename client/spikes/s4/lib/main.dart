// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/widgets.dart';

/// Spike S4 harness app; the integration test drives the media controls.
void main() {
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: Text('spike s4')),
    ),
  );
}
