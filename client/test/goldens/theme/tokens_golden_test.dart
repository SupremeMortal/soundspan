// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';

import '../../helpers/golden.dart';

/// Every colour token as a swatch with its name and value.
class _TokenSheet extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.typography.body.copyWith(color: colors.content);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final token in SoundspanColorToken.values)
            SizedBox(
              height: 32,
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors[token],
                      border: Border.all(color: colors.lineStrong),
                    ),
                    child: const SizedBox(width: 96, height: 24),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(width: 240, child: Text(token.name, style: style)),
                  Text(
                    '#${colors[token].toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
                    style: style.tabular,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

void main() {
  goldenMatrix(
    'tokens',
    sizes: const [Size(800, 800)],
    highContrast: const [false, true],
    builder: (_) => const _TokenSheet(),
  );
}
