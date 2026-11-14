// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/widgets/wordmark.dart';

import '../../helpers/golden.dart';

void main() {
  goldenMatrix(
    'wordmark',
    sizes: const [Size(800, 200)],
    builder: (_) => const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Wordmark(), SizedBox(height: 16), Wordmark(height: 56)],
      ),
    ),
  );
}
