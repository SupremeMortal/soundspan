// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/widgets/download_glyph.dart';

import '../../helpers/golden.dart';

void main() {
  // The indeterminate ring (running, size unknown) animates forever, so it
  // has no settled image; its rendering is covered by the widget test.
  goldenMatrix(
    'download_glyph',
    sizes: const [Size(320, 80)],
    builder: (_) => Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final state in [
            DownloadGlyphState.queued,
            const DownloadGlyphState.running(0.35),
            DownloadGlyphState.completed,
            DownloadGlyphState.failed,
            DownloadGlyphState.unavailable,
          ])
            Padding(
              padding: const EdgeInsets.all(8),
              child: DownloadGlyph(state: state),
            ),
          DownloadGlyph(state: DownloadGlyphState.failed, onTap: () {}),
        ],
      ),
    ),
  );
}
