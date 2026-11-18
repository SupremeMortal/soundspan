// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/widgets/code_cells.dart';

import '../../helpers/golden.dart';

void main() {
  for (final (name, value, error) in [
    ('empty', null, null),
    ('partly_filled', 'ABC', null),
    (
      'error',
      'ABC234',
      'That code has expired. Generate a new code in the web UI.',
    ),
  ]) {
    goldenMatrix(
      'code_cells.$name',
      sizes: const [Size(390, 160)],
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topCenter,
          child: CodeCells(
            initialValue: value,
            errorText: error,
            onChanged: (_) {},
            onCompleted: (_) {},
          ),
        ),
      ),
    );
  }
}
