// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/mosaic_artwork.dart';

import '../../helpers/golden.dart';

void main() {
  goldenMatrix(
    'artwork',
    sizes: const [Size(390, 320), Size(800, 320), Size(1440, 320)],
    builder: (_) => const Padding(
      padding: EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          Artwork(ref: 'album-1', size: 120),
          Artwork(ref: 'artist-1', size: 120, shape: ArtworkShape.circle),
          Artwork(ref: null, size: 120),
          Artwork(ref: null, size: 120, shape: ArtworkShape.circle),
          Artwork(ref: 'now-playing', size: 120, radius: 12),
          MosaicArtwork(refs: ['a', 'b', 'cc', 'ddd'], size: 120),
        ],
      ),
    ),
  );
}
