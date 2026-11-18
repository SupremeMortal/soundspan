// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/shared/widgets/action_bar.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';

Future<void> _pump(
  WidgetTester tester,
  ActionBar bar, {
  Size size = TestSizes.compact,
  double textScale = 1.0,
}) => tester.pumpApp(
  Builder(
    builder: (context) => WindowClassScope(
      windowClass: windowClassOf(MediaQuery.sizeOf(context)),
      child: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: bar),
      ),
    ),
  ),
  size: size,
  textScale: textScale,
);

void main() {
  testWidgets('every button calls its callback', (tester) async {
    final calls = <String>[];
    Offset? menuAt;
    await _pump(
      tester,
      ActionBar(
        onPlay: () => calls.add('play'),
        onShuffle: () => calls.add('shuffle'),
        onToggleLike: () => calls.add('like'),
        onAddToPlaylist: () => calls.add('add'),
        onMenu: (position) {
          calls.add('menu');
          menuAt = position;
        },
      ),
    );
    for (final key in [
      ActionBar.playKey,
      ActionBar.shuffleKey,
      ActionBar.likeKey,
      ActionBar.addToPlaylistKey,
      ActionBar.menuKey,
    ]) {
      await tester.tap(find.byKey(key));
    }
    expect(calls, ['play', 'shuffle', 'like', 'add', 'menu']);
    expect(
      menuAt,
      tester.getBottomLeft(find.byKey(ActionBar.menuKey)) +
          Offset(tester.getSize(find.byKey(ActionBar.menuKey)).width / 2, 0),
    );
    expect(find.text('Play'), findsOneWidget);
    expect(find.byTooltip('Shuffle'), findsOneWidget);
    expect(find.byTooltip('Like'), findsOneWidget);
    expect(find.byTooltip('Add to playlist'), findsOneWidget);
    expect(find.byTooltip('More options'), findsOneWidget);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('Play is an accent pill', (tester) async {
    await _pump(tester, ActionBar(onPlay: () {}));
    final button = tester.widget<FilledButton>(find.byKey(ActionBar.playKey));
    final context = tester.element(find.byKey(ActionBar.playKey));
    expect(
      button.style!.backgroundColor!.resolve(const {}),
      context.colors.accent,
    );
    expect(button.style!.shape!.resolve(const {}), isA<StadiumBorder>());
  });

  testWidgets('buttons without a callback are left out', (tester) async {
    await _pump(tester, ActionBar(onPlay: () {}, onMenu: (_) {}));
    expect(find.byKey(ActionBar.playKey), findsOneWidget);
    expect(find.byKey(ActionBar.menuKey), findsOneWidget);
    expect(find.byKey(ActionBar.shuffleKey), findsNothing);
    expect(find.byKey(ActionBar.likeKey), findsNothing);
    expect(find.byKey(ActionBar.addToPlaylistKey), findsNothing);
  });

  testWidgets('a liked album shows Remove like', (tester) async {
    await _pump(tester, ActionBar(liked: true, onToggleLike: () {}));
    expect(find.byTooltip('Remove like'), findsOneWidget);
  });

  testWidgets('wraps instead of overflowing at text scale 2.0', (tester) async {
    await _pump(
      tester,
      ActionBar(
        onPlay: () {},
        onShuffle: () {},
        onToggleLike: () {},
        onAddToPlaylist: () {},
        onMenu: (_) {},
      ),
      size: const Size(240, 600),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.byKey(ActionBar.menuKey)).dy,
      greaterThan(tester.getTopLeft(find.byKey(ActionBar.playKey)).dy),
    );
  });
}
