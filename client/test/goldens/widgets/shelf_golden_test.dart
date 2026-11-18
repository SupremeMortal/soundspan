// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/shelf.dart';

import '../../helpers/golden.dart';

void main() {
  goldenMatrix(
    'shelf',
    sizes: const [Size(390, 320), Size(800, 320), Size(1440, 320)],
    builder: (context) => WindowClassScope(
      windowClass: windowClassOf(MediaQuery.sizeOf(context)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Align(
          alignment: Alignment.topCenter,
          child: Shelf(
            title: 'Recently added',
            itemCount: 12,
            onShowAll: () {},
            itemBuilder: (context, index) => MediaCard(
              title: 'Album $index',
              subtitle: 'Artist $index',
              artworkRef: 'cover-$index',
              shape: index == 2 ? ArtworkShape.circle : ArtworkShape.square,
              onTap: () {},
            ),
          ),
        ),
      ),
    ),
  );
}
