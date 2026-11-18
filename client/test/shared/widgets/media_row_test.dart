// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/media_row.dart';
import 'package:soundspan/shared/widgets/mosaic_artwork.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';

void main() {
  Widget row({
    String title = 'Radiohead',
    String? subtitle = 'Artist',
    ArtworkShape shape = ArtworkShape.square,
    List<String>? mosaicRefs,
    VoidCallback? onTap,
    VoidCallback? onPlay,
    void Function(Offset? position)? onMenu,
  }) => Material(
    child: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: MediaRow.rowHeight,
        child: MediaRow(
          title: title,
          subtitle: subtitle,
          artworkRef: 'cover-1',
          shape: shape,
          mosaicRefs: mosaicRefs,
          onTap: onTap,
          onPlay: onPlay,
          onMenu: onMenu,
        ),
      ),
    ),
  );

  testWidgets('an artist row has circular artwork, its title and subtitle', (
    tester,
  ) async {
    await tester.pumpApp(row(shape: ArtworkShape.circle));

    final artwork = tester.widget<Artwork>(find.byType(Artwork));
    expect(artwork.shape, ArtworkShape.circle);
    expect(artwork.size, MediaRow.artworkSize);
    expect(find.text('Radiohead'), findsOneWidget);
    expect(find.text('Artist'), findsOneWidget);
  });

  testWidgets('a playlist row shows a mosaic in place of the artwork', (
    tester,
  ) async {
    await tester.pumpApp(row(mosaicRefs: const ['a', 'b', 'c', 'd']));

    expect(find.byType(MosaicArtwork), findsOneWidget);
    // Every cover is a tile of the mosaic; there is no single artwork.
    expect(
      find.descendant(
        of: find.byType(MosaicArtwork),
        matching: find.byType(Artwork),
      ),
      findsNWidgets(find.byType(Artwork).evaluate().length),
    );
  });

  testWidgets('tapping the row opens it and the play button plays it', (
    tester,
  ) async {
    var opened = 0;
    var played = 0;
    await tester.pumpApp(row(onTap: () => opened++, onPlay: () => played++));

    await tester.tap(find.byKey(MediaRow.playKey));
    expect((opened, played), (0, 1));
    await tester.tap(find.text('Radiohead'));
    expect((opened, played), (1, 1));
  });

  testWidgets('without callbacks there is no play or overflow button', (
    tester,
  ) async {
    await tester.pumpApp(row());

    expect(find.byKey(MediaRow.playKey), findsNothing);
    expect(find.byKey(MediaRow.overflowKey), findsNothing);
  });

  testWidgets('the overflow button, a long press and a secondary click '
      'open the menu', (tester) async {
    final positions = <Offset?>[];
    await tester.pumpApp(row(onTap: () {}, onMenu: positions.add));

    await tester.tap(find.byKey(MediaRow.overflowKey));
    expect(positions, hasLength(1));
    expect(positions.single, isNotNull);

    await tester.longPress(find.text('Radiohead'));
    expect(positions, hasLength(2));
    expect(positions.last, isNull);

    final at = tester.getCenter(find.text('Radiohead'));
    await tester.tapAt(at, buttons: kSecondaryButton);
    await tester.pump();
    expect(positions, hasLength(3));
    expect(positions.last, at);
  });

  testWidgets('screen readers get a More options action', (tester) async {
    final handle = tester.ensureSemantics();
    var menus = 0;
    await tester.pumpApp(row(onTap: () {}, onMenu: (_) => menus++));

    final node = tester.getSemantics(find.byType(MediaRow));
    expect(node.getSemanticsData().customSemanticsActionIds, isNotEmpty);
    handle.dispose();
  });

  testWidgets('meets the guidelines', (tester) async {
    await tester.pumpApp(row(onTap: () {}, onPlay: () {}, onMenu: (_) {}));
    await expectMeetsGuidelines(tester);
  });
}
