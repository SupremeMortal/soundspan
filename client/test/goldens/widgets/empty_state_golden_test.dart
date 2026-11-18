// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';

import '../../helpers/golden.dart';

void main() {
  goldenMatrix(
    'empty_state',
    sizes: const [Size(390, 320), Size(800, 320), Size(1440, 320)],
    builder: (_) => EmptyState(
      icon: Icons.library_music_rounded,
      message: 'Your library is empty. Add music on the server to see it here.',
      actionLabel: 'Refresh',
      onAction: () {},
    ),
  );
}
