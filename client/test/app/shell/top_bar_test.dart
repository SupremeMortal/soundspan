// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/top_bar.dart';
import 'package:soundspan/shared/providers/tint.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/fake_tint_extractor.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_root.dart';

void main() {
  IconButton button(WidgetTester tester, String tooltip) =>
      tester.widget<IconButton>(
        find.descendant(
          of: find.byType(TopBar),
          matching: find.byWidgetPredicate(
            (widget) => widget is IconButton && widget.tooltip == tooltip,
          ),
        ),
      );

  bool enabled(WidgetTester tester, String tooltip) =>
      button(tester, tooltip).onPressed != null;

  Future<void> tapButton(WidgetTester tester, String tooltip) async {
    button(tester, tooltip).onPressed!();
    await tester.pumpAndSettle();
  }

  BuildContext screen(WidgetTester tester) =>
      tester.element(find.byType(RouteTitle).last);

  for (final size in [TestSizes.compact, TestSizes.medium]) {
    testWidgets('absent at ${size.width.toInt()}', (tester) async {
      await tester.pumpSoundspanApp(stored: StoredProfile.signedIn, size: size);
      expect(find.byType(TopBar), findsNothing);
      await expectMeetsGuidelines(tester);
    });
  }

  testWidgets('present at 1440', (tester) async {
    await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
    );
    expect(find.byType(TopBar), findsOneWidget);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('submitting "miles" navigates to /search?q=miles', (
    tester,
  ) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
    );
    await tester.enterText(find.byKey(TopBar.searchFieldKey), ' miles ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(locationOf(root), '/search?q=miles');
  });

  testWidgets('submitting an empty search does nothing', (tester) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
    );
    await tester.enterText(find.byKey(TopBar.searchFieldKey), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(locationOf(root), '/home');
  });

  testWidgets('Back and Forward enable and disable correctly', (tester) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
    );
    expect(enabled(tester, 'Back'), isFalse);
    expect(enabled(tester, 'Forward'), isFalse);

    DetailNavigation.openAlbum(screen(tester), 'a1');
    await tester.pumpAndSettle();
    expect(locationOf(root), '/home/album/a1');
    expect(enabled(tester, 'Back'), isTrue);
    expect(enabled(tester, 'Forward'), isFalse);

    await tapButton(tester, 'Back');
    expect(locationOf(root), '/home');
    expect(enabled(tester, 'Back'), isFalse);
    expect(enabled(tester, 'Forward'), isTrue);

    await tapButton(tester, 'Forward');
    expect(locationOf(root), '/home/album/a1');
    expect(enabled(tester, 'Back'), isTrue);
    expect(enabled(tester, 'Forward'), isFalse);

    await tapButton(tester, 'Back');
    expect(enabled(tester, 'Forward'), isTrue);
    DetailNavigation.openArtist(screen(tester), 'r1');
    await tester.pumpAndSettle();
    expect(locationOf(root), '/home/artist/r1');
    expect(enabled(tester, 'Forward'), isFalse);
  });

  testWidgets('Forward keeps a stacked branch', (tester) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
      overrides: [
        ...FakeRepositories().overrides,
        tintExtractorProvider.overrideWithValue(AsyncData(FakeTintExtractor())),
      ],
    );
    DetailNavigation.openAlbum(screen(tester), 'a1');
    await tester.pumpAndSettle();
    DetailNavigation.openArtist(screen(tester), 'r1');
    await tester.pumpAndSettle();
    expect(locationOf(root), '/home/artist/r1');

    await tapButton(tester, 'Back');
    expect(locationOf(root), '/home/album/a1');

    await tapButton(tester, 'Forward');
    expect(locationOf(root), '/home/artist/r1');
    expect(enabled(tester, 'Forward'), isFalse);

    await tapButton(tester, 'Back');
    expect(locationOf(root), '/home/album/a1');

    await tapButton(tester, 'Back');
    expect(locationOf(root), '/home');
    expect(enabled(tester, 'Back'), isFalse);
  });

  testWidgets('a stacked detail tears down under the default harness', (
    tester,
  ) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
    );
    DetailNavigation.openAlbum(screen(tester), 'a1');
    await tester.pumpAndSettle();
    DetailNavigation.openArtist(screen(tester), 'r1');
    await tester.pumpAndSettle();
    expect(locationOf(root), '/home/artist/r1');

    await tapButton(tester, 'Back');
    expect(locationOf(root), '/home/album/a1');

    await tapButton(tester, 'Back');
    expect(locationOf(root), '/home');
  });

  testWidgets('Forward belongs to the branch it was left in', (tester) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
    );
    DetailNavigation.openAlbum(screen(tester), 'a1');
    await tester.pumpAndSettle();
    await tapButton(tester, 'Back');
    expect(enabled(tester, 'Forward'), isTrue);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(locationOf(root), '/library/playlists');
    expect(enabled(tester, 'Forward'), isFalse);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(enabled(tester, 'Forward'), isTrue);
  });
}
