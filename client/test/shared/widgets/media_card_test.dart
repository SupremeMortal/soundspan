// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/focus_ring.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/mosaic_artwork.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';

void main() {
  Widget card({
    String title = 'Abbey Road',
    String subtitle = 'The Beatles',
    VoidCallback? onTap,
    VoidCallback? onPlay,
    ArtworkShape shape = ArtworkShape.square,
  }) => Center(
    child: SizedBox(
      width: 160,
      child: MediaCard(
        title: title,
        subtitle: subtitle,
        artworkRef: 'cover-1',
        shape: shape,
        onTap: onTap,
        onPlay: onPlay,
      ),
    ),
  );

  Future<TestGesture> hover(WidgetTester tester) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(MediaCard)));
    await tester.pump();
    return mouse;
  }

  final playButton = find.byTooltip('Play');

  testWidgets('hover shows the play button only when onPlay is set', (
    tester,
  ) async {
    var plays = 0;
    await tester.pumpApp(card(onTap: () {}, onPlay: () => plays++));
    expect(playButton, findsNothing);

    final mouse = await hover(tester);
    expect(playButton, findsOneWidget);
    final card_ = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MediaCard),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final context = tester.element(find.byType(MediaCard));
    expect(
      (card_.decoration as BoxDecoration).color,
      context.colors.surfaceHover,
    );
    await tester.tap(playButton);
    expect(plays, 1);

    await mouse.moveTo(Offset.zero);
    await tester.pump();
    expect(playButton, findsNothing);
  });

  testWidgets('hover shows no play button without onPlay', (tester) async {
    await tester.pumpApp(card(onTap: () {}));
    await hover(tester);

    expect(playButton, findsNothing);
  });

  testWidgets('tap calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpApp(card(onTap: () => taps++));

    await tester.tap(find.text('Abbey Road'));
    expect(taps, 1);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('merged semantics label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(card(onTap: () {}));

    expect(
      tester.getSemantics(find.bySemanticsLabel('Abbey Road, The Beatles')),
      isSemantics(
        label: 'Abbey Road, The Beatles',
        isButton: true,
        hasTapAction: true,
      ),
    );
    expect(find.bySemanticsLabel('Abbey Road'), findsNothing);
    handle.dispose();
  });

  testWidgets('not a button without onTap', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(card());

    expect(
      tester.getSemantics(find.bySemanticsLabel('Abbey Road, The Beatles')),
      isSemantics(label: 'Abbey Road, The Beatles', isButton: false),
    );
    await expectMeetsGuidelines(tester);
    handle.dispose();
  });

  testWidgets('focus shows the ring', (tester) async {
    var taps = 0;
    await tester.pumpApp(card(onTap: () => taps++));
    final ring = find.byKey(FocusRingLayer.paintKey);
    expect(ring, paintsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    final context = tester.element(find.byType(MediaCard));
    // 2 px ring, 2 px outside the card.
    expect(
      ring,
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          tester.getRect(find.byType(MediaCard)).inflate(3),
          const Radius.circular(FocusRingLayer.radius),
        ),
        color: context.colors.brand,
        strokeWidth: 2,
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });

  testWidgets('long title truncates to one line at text scale 2.0 without '
      'overflow', (tester) async {
    const title =
        'A very long album title that never fits on one line of a card';
    await tester.pumpApp(
      Builder(
        builder: (context) => Center(
          child: SizedBox(
            width: 160,
            height: MediaCard.extentFor(context, width: 160),
            child: const MediaCard(
              title: title,
              subtitle: 'An equally long artist name for the subtitle line',
              artworkRef: 'cover-1',
            ),
          ),
        ),
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(find.text(title));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(find.text(title)).height, 40);
  });

  testWidgets('the skeleton has the outer size of a card', (tester) async {
    await tester.pumpApp(
      Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            card(),
            const SizedBox(width: 160, child: MediaCardSkeleton()),
          ],
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(MediaCardSkeleton)),
      tester.getSize(find.byType(MediaCard)),
    );
    final context = tester.element(find.byType(MediaCard));
    expect(
      tester.getSize(find.byType(MediaCard)).height,
      MediaCard.extentFor(context, width: 160),
    );
  });

  testWidgets('an artist card is round', (tester) async {
    await tester.pumpApp(card(shape: ArtworkShape.circle));

    expect(
      tester.widget<Artwork>(find.byType(Artwork)).shape,
      ArtworkShape.circle,
    );
  });

  testWidgets('mosaicRefs show a mosaic of the covers in place of artworkRef', (
    tester,
  ) async {
    const refs = ['c1', 'c2', 'c3', 'c4'];
    await tester.pumpApp(
      const Center(
        child: SizedBox(
          width: 160,
          child: MediaCard(
            title: 'Road trip',
            subtitle: '12 songs',
            artworkRef: null,
            mosaicRefs: refs,
          ),
        ),
      ),
    );

    final mosaic = tester.widget<MosaicArtwork>(find.byType(MosaicArtwork));
    expect(mosaic.refs, refs);
    expect(mosaic.size, 160 - MediaCard.padding * 2);
    expect(find.byType(Artwork), findsNWidgets(4));
  });
}
