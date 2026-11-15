// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/mosaic_artwork.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';

void main() {
  List<Artwork> artworks(WidgetTester tester) =>
      tester.widgetList<Artwork>(find.byType(Artwork)).toList();

  testWidgets('four refs fill a 2 × 2 grid', (tester) async {
    await tester.pumpApp(
      const Center(
        child: MosaicArtwork(refs: ['a', 'b', 'c', 'd', 'e'], size: 160),
      ),
    );

    expect(artworks(tester).map((a) => a.ref), ['a', 'b', 'c', 'd']);
    expect(artworks(tester).map((a) => a.size), everyElement(80));
    expect(
      tester.getTopLeft(find.byType(Artwork).at(3)) -
          tester.getTopLeft(find.byType(Artwork).first),
      const Offset(80, 80),
    );
    expect(tester.getSize(find.byType(MosaicArtwork)), const Size.square(160));
    await expectMeetsGuidelines(tester);
  });

  testWidgets('two refs show the first as one artwork', (tester) async {
    await tester.pumpApp(
      const Center(child: MosaicArtwork(refs: ['a', 'b'], size: 160)),
    );

    expect(artworks(tester).single.ref, 'a');
    expect(artworks(tester).single.size, 160);
  });

  testWidgets('one ref shows that artwork', (tester) async {
    await tester.pumpApp(
      const Center(child: MosaicArtwork(refs: ['a'], size: 160)),
    );

    expect(artworks(tester).single.ref, 'a');
  });

  testWidgets('zero refs show the placeholder', (tester) async {
    await tester.pumpApp(
      const Center(child: MosaicArtwork(refs: [], size: 160)),
    );

    expect(artworks(tester).single.ref, isNull);
    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
  });
}
