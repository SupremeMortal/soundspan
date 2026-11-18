// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/media_card.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/play_rig.dart';
import 'library_harness.dart';

void main() {
  Finder card(String title) =>
      find.ancestor(of: find.text(title), matching: find.byType(MediaCard));

  Finder playButton(Finder card) =>
      find.descendant(of: card, matching: find.byTooltip('Play'));

  FakeLibraryRepository library() {
    final repository = FakeLibraryRepository()..albumList = albums(3);
    repository.albumDetails['al1'] = AlbumDetail(
      album: albums(3)[1],
      tracks: [track(10), track(11, playable: false), track(12)],
      owned: true,
    );
    return repository;
  }

  Future<void> hover(WidgetTester tester, Finder target) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: tester.getCenter(target));
    await tester.pump();
  }

  testWidgets('hovering an album card shows the play button, which plays the '
      'album', (tester) async {
    final rig = PlayRig();
    await tester.pumpLibrary(library: library(), overrides: rig.overrides);
    expect(playButton(card('Album 1')), findsNothing);

    await hover(tester, card('Album 1'));
    expect(playButton(card('Album 1')), findsOneWidget);
    expect(
      tester.getSemantics(playButton(card('Album 1'))),
      isSemantics(tooltip: 'Play', isButton: true),
    );

    await tester.tap(playButton(card('Album 1')));
    await rig.settle(tester);

    expect(rig.queued, ['p10', 'p12']);
    expect(rig.current, 'p10');
    expect(rig.context?.kind, QueueContextKind.album);
    expect(rig.context?.id, 'al1');
    await rig.close(tester);
  });

  testWidgets('keyboard focus shows the play button', (tester) async {
    final rig = PlayRig();
    await tester.pumpLibrary(library: library(), overrides: rig.overrides);
    expect(find.byTooltip('Play'), findsNothing);

    // Tab through the controls until a card has keyboard focus.
    var focused = find.byType(MediaCard).first;
    for (var i = 0; i < 20; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final node = FocusManager.instance.primaryFocus?.context;
      if (node == null) continue;
      final card = node.findAncestorWidgetOfExactType<MediaCard>();
      if (card != null) {
        focused = find.byWidget(card);
        break;
      }
    }

    expect(playButton(focused), findsOneWidget);
    await rig.close(tester);
  });

  testWidgets('an artist card has no play button', (tester) async {
    final rig = PlayRig();
    await tester.pumpLibrary(
      tab: LibraryTab.artists,
      library: FakeLibraryRepository()..artistList = artists(2),
      overrides: rig.overrides,
    );

    await hover(tester, card('Artist 1'));

    expect(tester.widget<MediaCard>(card('Artist 1')).onPlay, isNull);
    expect(playButton(card('Artist 1')), findsNothing);
    await rig.close(tester);
  });
}
