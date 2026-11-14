// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'placeholder_image_provider.dart';

Future<ui.Color> _pixel(ui.Image image) async {
  final bytes = (await image.toByteData())!;
  return ui.Color.fromARGB(
    bytes.getUint8(3),
    bytes.getUint8(0),
    bytes.getUint8(1),
    bytes.getUint8(2),
  );
}

void main() {
  group('PlaceholderImageProvider', () {
    test('the same ref always gives the same colour', () {
      expect(
        const PlaceholderImageProvider('album:42').color,
        const PlaceholderImageProvider('album:42').color,
      );
    });

    test('the colour is picked by the code-unit sum modulo 8', () {
      // 'a' = 97 (97 % 8 = 1), 'b' = 98 (98 % 8 = 2).
      expect(
        const PlaceholderImageProvider('a').color,
        PlaceholderImageProvider.palette[1],
      );
      expect(
        const PlaceholderImageProvider('b').color,
        PlaceholderImageProvider.palette[2],
      );
      expect(
        const PlaceholderImageProvider('a').color,
        isNot(const PlaceholderImageProvider('b').color),
      );
      expect(PlaceholderImageProvider.palette.toSet(), hasLength(8));
    });

    test('equality and hash code are by ref', () {
      expect(
        const PlaceholderImageProvider('x'),
        const PlaceholderImageProvider('x'),
      );
      expect(
        const PlaceholderImageProvider('x').hashCode,
        const PlaceholderImageProvider('x').hashCode,
      );
      expect(
        const PlaceholderImageProvider('x'),
        isNot(const PlaceholderImageProvider('y')),
      );
    });

    testWidgets('resolves synchronously to a flat image of its colour', (
      tester,
    ) async {
      const provider = PlaceholderImageProvider('track:7');
      ImageInfo? info;
      provider
          .resolve(ImageConfiguration.empty)
          .addListener(ImageStreamListener((image, _) => info = image));
      // No pump and no network: the listener has already fired.
      expect(info, isNotNull);
      final color = await tester.runAsync(() => _pixel(info!.image));
      expect(color, provider.color);
    });

    testWidgets('paints inside an Image widget on the first frame', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Image(image: PlaceholderImageProvider('artist:1'), width: 40),
      );
      final raw = tester.widget<RawImage>(find.byType(RawImage));
      expect(raw.image, isNotNull);
    });
  });
}
