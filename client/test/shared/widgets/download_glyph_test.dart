// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/shared/widgets/download_glyph.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    DownloadGlyphState state, {
    VoidCallback? onTap,
  }) => tester.pumpApp(
    Center(
      child: DownloadGlyph(key: const Key('glyph'), state: state, onTap: onTap),
    ),
  );

  final labels = <DownloadGlyphState, String>{
    DownloadGlyphState.queued: 'Waiting to download',
    const DownloadGlyphState.running(0.42): 'Downloading, 42 percent',
    const DownloadGlyphState.running(null): 'Downloading',
    DownloadGlyphState.completed: 'Downloaded',
    DownloadGlyphState.failed: 'Download failed',
    DownloadGlyphState.unavailable: 'Not available for download',
  };

  for (final MapEntry(key: state, value: label) in labels.entries) {
    testWidgets('$state renders and is labelled "$label"', (tester) async {
      await pump(tester, state);

      expect(find.byKey(const Key('glyph')), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const Key('glyph'))),
        isSemantics(label: label),
      );
      await expectMeetsGuidelines(tester);
    });
  }

  testWidgets('none takes no space and has no label', (tester) async {
    await pump(tester, DownloadGlyphState.none);

    expect(tester.getSize(find.byKey(const Key('glyph'))), Size.zero);
    expect(find.bySemanticsLabel(RegExp('.')), findsNothing);
  });

  testWidgets('colours come from the tokens', (tester) async {
    await pump(tester, DownloadGlyphState.completed);
    final colors = tester.element(find.byType(DownloadGlyph)).colors;
    expect(tester.widget<Icon>(find.byType(Icon)).color, colors.positive);

    await pump(tester, DownloadGlyphState.failed);
    expect(tester.widget<Icon>(find.byType(Icon)).color, colors.danger);

    await pump(tester, DownloadGlyphState.unavailable);
    expect(
      tester.widget<Icon>(find.byType(Icon)).color,
      colors.contentDisabled,
    );

    await pump(tester, DownloadGlyphState.queued);
    expect(
      tester.widget<Icon>(find.byType(Icon)).color,
      colors.contentSecondary,
    );

    await pump(tester, const DownloadGlyphState.running(0.5));
    final ring = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(ring.color, colors.brand);
    expect(ring.value, 0.5);
  });

  testWidgets('the size-unknown ring is indeterminate', (tester) async {
    await pump(tester, const DownloadGlyphState.running(null));

    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      isNull,
    );
  });

  testWidgets('a tappable failed glyph is a labelled button of the minimum '
      'target that calls onTap', (tester) async {
    var taps = 0;
    await pump(tester, DownloadGlyphState.failed, onTap: () => taps++);

    expect(
      tester.getSemantics(find.byKey(const Key('glyph'))),
      isSemantics(label: 'Download failed', isButton: true, hasTapAction: true),
    );
    await expectMeetsGuidelines(tester);

    await tester.tap(find.byKey(const Key('glyph')));
    expect(taps, 1);
  });

  test('values compare by content', () {
    expect(
      const DownloadGlyphState.running(0.5),
      const DownloadGlyphState.running(0.5),
    );
    expect(
      const DownloadGlyphState.running(0.5),
      isNot(const DownloadGlyphState.running(0.6)),
    );
  });
}
