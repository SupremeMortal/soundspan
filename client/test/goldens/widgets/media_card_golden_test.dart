// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/media_card.dart';

import '../../helpers/golden.dart';

const Key _hoveredKey = ValueKey('hovered');

void main() {
  // Default, focused (the first focusable card), hovered with play, artist
  // and skeleton.
  goldenMatrix(
    'media_card',
    sizes: const [Size(390, 720), Size(800, 560), Size(1440, 300)],
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          const SizedBox(
            width: 160,
            child: MediaCard(
              title: 'Abbey Road',
              subtitle: 'The Beatles',
              artworkRef: 'album-1',
            ),
          ),
          SizedBox(
            width: 160,
            child: MediaCard(
              title: 'Kind of Blue',
              subtitle: 'Miles Davis',
              artworkRef: 'album-2',
              onTap: () {},
            ),
          ),
          SizedBox(
            width: 160,
            child: MediaCard(
              key: _hoveredKey,
              title: 'A title far too long for one line',
              subtitle: 'An artist with a long name',
              artworkRef: 'album-3',
              onTap: () {},
              onPlay: () {},
            ),
          ),
          const SizedBox(
            width: 160,
            child: MediaCard(
              title: 'Nina Simone',
              subtitle: 'Artist',
              artworkRef: 'artist-1',
              shape: ArtworkShape.circle,
            ),
          ),
          const SizedBox(width: 160, child: MediaCardSkeleton()),
        ],
      ),
    ),
    act: (tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byKey(_hoveredKey)));
    },
  );
}
