// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/features/album/album.dart';
import 'package:soundspan/shared/widgets/media_card.dart';

import '../../../features/detail_fixtures.dart';
import '../../../helpers/play_rig.dart';
import '../../../helpers/pump_app.dart';
import 'selection_harness.dart';

Future<void> _pumpAlbum(WidgetTester tester, PlayRig rig) => pumpDetail(
  tester,
  underShellShortcuts(const AlbumScreen(albumId: 'al-1')),
  size: TestSizes.expanded,
  repositories: albumRepositories([fixtureTrack(1), fixtureTrack(2)]),
  overrides: rig.overrides,
);

void main() {
  final linux = TargetPlatformVariant.only(TargetPlatform.linux);

  testWidgets('the Menu key opens the menu of the focused row at the row', (
    tester,
  ) async {
    final rig = PlayRig();
    await _pumpAlbum(tester, rig);

    await click(tester, 'Song 1.2');
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await tester.pumpAndSettle();

    expect(find.text('Play now'), findsOneWidget);
    final row = tester.getRect(rowOf('Song 1.2'));
    final menu = tester.getTopLeft(find.text('Play now'));
    expect(menu.dy, greaterThanOrEqualTo(row.top));

    await tester.tap(find.text('Play now'));
    await rig.settle(tester);
    expect(rig.current, 'p-1-2');
    await rig.close(tester);
  }, variant: linux);

  testWidgets('Shift+F10 opens the menu of the focused row', (tester) async {
    final rig = PlayRig();
    await _pumpAlbum(tester, rig);

    await click(tester, 'Song 1.1');
    await pressWith(
      tester,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.f10,
    );
    await tester.pumpAndSettle();

    expect(find.text('Play now'), findsOneWidget);
    expect(find.text('Go to artist'), findsOneWidget);
    await rig.close(tester);
  }, variant: linux);

  testWidgets('the Menu key opens the menu of the focused card below it', (
    tester,
  ) async {
    final positions = <Offset?>[];
    await tester.pumpApp(
      underShellShortcuts(
        Center(
          child: SizedBox(
            width: 160,
            child: MediaCard(
              title: 'Abbey Road',
              subtitle: 'The Beatles',
              artworkRef: 'cover-1',
              onTap: () {},
              onMenu: positions.add,
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await pressWith(
      tester,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.f10,
    );

    final card = tester.getRect(find.byType(MediaCard));
    expect(positions, [card.bottomLeft, card.bottomLeft]);
  }, variant: linux);
}
