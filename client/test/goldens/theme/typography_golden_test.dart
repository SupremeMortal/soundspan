// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';

import '../../helpers/golden.dart';

/// One line per type style, named.
class _TypeSheet extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final t = context.typography;
    final styles = {
      'display': t.display,
      'headline': t.headline,
      'headlineCompact': t.headlineCompact,
      'title': t.title,
      'subtitle': t.subtitle,
      'body': t.body,
      'bodySmall': t.bodySmall,
      'caption': t.caption,
      'overline': t.overline,
      'mono': t.mono,
    };
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final MapEntry(key: name, value: style) in styles.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '$name: Sound spans 0123456789',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.copyWith(color: context.colors.content),
              ),
            ),
        ],
      ),
    );
  }
}

void main() {
  goldenMatrix(
    'typography',
    sizes: const [Size(800, 480)],
    builder: (_) => const _TypeSheet(),
  );
  goldenMatrix(
    'typography',
    sizes: const [Size(800, 640)],
    themes: const [ThemeMode.dark],
    textScales: const [2],
    builder: (_) => const _TypeSheet(),
  );
}
