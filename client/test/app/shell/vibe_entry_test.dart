// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/features/vibe/vibe.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_root.dart';

class _FixedCapabilities extends ServerCapabilitiesNotifier {
  new(this._value);

  final ServerCapabilities _value;

  @override
  ServerCapabilities build() => _value;
}

ServerCapabilities _capabilities({required bool audioAnalysis}) =>
    ServerCapabilities(
      serverVersion: Version.tryParse('2.7.0'),
      hasP6SelfRevoke: true,
      hasP7PlayMarker: true,
      hasP8PlayedAt: true,
      audioAnalysis: audioAnalysis,
    );

void main() {
  group('sidebar at 1440', () {
    testWidgets('has Vibe below Explore, which opens it in the selected '
        'branch, when the server has audio analysis', (tester) async {
      final root = await tester.pumpSoundspanApp(
        stored: StoredProfile.signedIn,
        size: TestSizes.expanded,
        overrides: [
          serverCapabilitiesProvider.overrideWith(
            () => _FixedCapabilities(_capabilities(audioAnalysis: true)),
          ),
        ],
      );
      final item = find.byKey(AdaptiveShell.vibeKey);
      expect(find.descendant(of: item, matching: find.text('Vibe')), findsOne);
      expect(
        tester.getTopLeft(item).dy,
        greaterThan(tester.getTopLeft(find.text('Explore').first).dy),
      );

      await tester.tap(item);
      await tester.pumpAndSettle();
      expect(locationOf(root), '/home/vibe');
    });

    testWidgets('has no Vibe without audio analysis', (tester) async {
      await tester.pumpSoundspanApp(
        stored: StoredProfile.signedIn,
        size: TestSizes.expanded,
        overrides: [
          serverCapabilitiesProvider.overrideWith(
            () => _FixedCapabilities(_capabilities(audioAnalysis: false)),
          ),
        ],
      );

      expect(find.byKey(AdaptiveShell.vibeKey), findsNothing);
      expect(find.text('Explore'), findsWidgets);
    });
  });

  group('Home card', () {
    Future<void> pump(
      WidgetTester tester, {
      required bool audioAnalysis,
      Size size = TestSizes.compact,
    }) => tester.pumpApp(
      WindowClassScope(
        windowClass: windowClassOf(size),
        child: const Scaffold(body: VibeCard()),
      ),
      size: size,
      overrides: [
        serverCapabilitiesProvider.overrideWith(
          () => _FixedCapabilities(_capabilities(audioAnalysis: audioAnalysis)),
        ),
      ],
    );

    testWidgets('shows at 390 and 800 with audio analysis', (tester) async {
      await pump(tester, audioAnalysis: true);
      expect(find.text('Vibe'), findsOneWidget);

      await pump(tester, audioAnalysis: true, size: TestSizes.medium);
      expect(find.text('Vibe'), findsOneWidget);
    });

    testWidgets('is empty at 390 without audio analysis', (tester) async {
      await pump(tester, audioAnalysis: false);
      expect(find.text('Vibe'), findsNothing);
    });

    testWidgets('is empty at 1440, where the sidebar has the entry', (
      tester,
    ) async {
      await pump(tester, audioAnalysis: true, size: TestSizes.expanded);
      expect(find.text('Vibe'), findsNothing);
    });
  });
}
