// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/licenses/license_catalog.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/features/settings/settings.dart';

import '../../../../helpers/golden.dart';
import '../../../../helpers/guidelines.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_root.dart';

/// A seeded licence registry.
class FakeLicenseSource implements LicenseSource {
  /// Creates a source yielding [entries], with [titles] as the bundled
  /// components. [pending] holds the licences back until completed; [error]
  /// makes the collection fail.
  new(this.entries, this.titles, {this.pending, this.error});

  final List<LicenseEntry> entries;
  final List<String> titles;
  final Completer<void>? pending;
  Error? error;

  @override
  Stream<LicenseEntry> licenses() async* {
    await pending?.future;
    final error = this.error;
    if (error != null) throw error;
    yield* Stream.fromIterable(entries);
  }

  @override
  Future<List<String>> bundledTitles() async => titles;
}

LicenseEntry _entry(String package, String text) =>
    LicenseEntryWithLineBreaks([package], text);

FakeLicenseSource seededSource({Completer<void>? pending, Error? error}) =>
    FakeLicenseSource(
      [
        _entry('zeta', 'Zeta licence text.'),
        _entry('soundspan', 'GNU GENERAL PUBLIC LICENSE\n\nVersion 3.'),
        _entry('mpv', 'mpv notice.\n\nGNU LESSER GENERAL PUBLIC LICENSE'),
        _entry('Montserrat', 'SIL Open Font License'),
        _entry('alpha', 'Alpha licence one.'),
        _entry('alpha', 'Alpha licence two.'),
        _entry('Beta', 'Beta licence.'),
      ],
      ['Montserrat', 'mpv'],
      pending: pending,
      error: error,
    );

Future<void> pumpLicenses(
  WidgetTester tester,
  LicenseSource source, {
  Size size = TestSizes.compact,
}) async {
  await tester.pumpApp(
    const LicensesScreen(),
    size: size,
    overrides: [licenseSourceProvider.overrideWithValue(source)],
  );
  await tester.pumpAndSettle();
}

double top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  testWidgets('soundspan is first, then the bundled components, then the '
      'packages alphabetically', (tester) async {
    await pumpLicenses(tester, seededSource());
    final order = [
      'soundspan',
      'Fonts and bundled libraries',
      'Montserrat',
      'mpv',
      'Packages',
      'alpha',
      'Beta',
      'zeta',
    ];
    for (var i = 1; i < order.length; i++) {
      expect(
        top(tester, order[i]),
        greaterThan(top(tester, order[i - 1])),
        reason: '${order[i]} after ${order[i - 1]}',
      );
    }
    expect(find.text('2 licences'), findsOneWidget);
    expect(find.text('1 licence'), findsNWidgets(5));
  });

  testWidgets('tapping mpv shows its text', (tester) async {
    await pumpLicenses(tester, seededSource());
    await tester.tap(find.text('mpv'));
    await tester.pumpAndSettle();
    expect(find.text('GNU LESSER GENERAL PUBLIC LICENSE'), findsOneWidget);
    expect(find.text('mpv notice.'), findsOneWidget);
    expect(find.byType(SelectionArea), findsOneWidget);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('a 5,000-paragraph licence builds only the visible '
      'paragraphs', (tester) async {
    final text = [for (var i = 0; i < 5000; i++) 'Paragraph $i.'].join('\n\n');
    await pumpLicenses(
      tester,
      FakeLicenseSource([_entry('huge', text)], const []),
    );
    await tester.tap(find.text('huge'));
    await tester.pumpAndSettle();
    expect(find.text('Paragraph 0.'), findsOneWidget);
    expect(find.text('Paragraph 4999.'), findsNothing);
    expect(
      find.textContaining(RegExp(r'^Paragraph \d+\.$')).evaluate().length,
      lessThan(100),
    );
  });

  testWidgets('shows progress while the licences are collected', (
    tester,
  ) async {
    final pending = Completer<void>();
    await tester.pumpApp(
      const LicensesScreen(),
      overrides: [
        licenseSourceProvider.overrideWithValue(seededSource(pending: pending)),
      ],
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Loading licences'), findsOneWidget);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('soundspan'), findsOneWidget);
  });

  testWidgets('a failure shows an error that can be retried', (tester) async {
    final source = seededSource(error: StateError('broken'));
    await pumpLicenses(tester, source);
    expect(find.text('The licences could not be loaded.'), findsOneWidget);
    expect(find.text('soundspan'), findsNothing);
    await expectMeetsGuidelines(tester);

    source.error = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('soundspan'), findsOneWidget);
  });

  for (final size in [TestSizes.compact, TestSizes.expanded]) {
    testWidgets('meets the guidelines at ${size.width.toInt()}', (
      tester,
    ) async {
      await pumpLicenses(tester, seededSource(), size: size);
      await expectMeetsGuidelines(tester);
    });
  }

  testWidgets('the Licences row in Settings → About opens the screen', (
    tester,
  ) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      overrides: [licenseSourceProvider.overrideWithValue(seededSource())],
    );
    root.container.read(routerProvider).go(SettingsSection.about.path);
    await tester.pumpAndSettle();
    await expectMeetsGuidelines(tester);
    await tester.tap(find.text('Licences'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensesScreen), findsOneWidget);
    expect(find.text('Open-source licences'), findsOneWidget);
    expect(find.text('soundspan'), findsOneWidget);
  });

  testWidgets('${RoutePaths.settingsAboutLicenses} opens the screen', (
    tester,
  ) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      overrides: [licenseSourceProvider.overrideWithValue(seededSource())],
    );
    root.container.read(routerProvider).go(RoutePaths.settingsAboutLicenses);
    await tester.pumpAndSettle();
    expect(find.byType(LicensesScreen), findsOneWidget);
    await tester.tap(find.text('mpv'));
    await tester.pumpAndSettle();
    expect(find.text('mpv notice.'), findsOneWidget);
  });

  goldenMatrix(
    'licenses_screen',
    sizes: const [TestSizes.compact, TestSizes.expanded],
    overrides: [licenseSourceProvider.overrideWithValue(seededSource())],
    builder: (_) => const LicensesScreen(),
  );
}
