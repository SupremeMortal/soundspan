// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../helpers/golden.dart';

void main() {
  // Offline, server error and not found, side by side.
  goldenMatrix(
    'error_view',
    sizes: const [Size(390, 900), Size(800, 900), Size(1440, 900)],
    builder: (_) => Column(
      children: [
        for (final error in const <ApiException>[
          Offline(),
          ServerError(status: 500),
          NotFound(status: 404),
        ])
          Expanded(
            child: ErrorView(error: error, onRetry: () {}),
          ),
      ],
    ),
  );
}
