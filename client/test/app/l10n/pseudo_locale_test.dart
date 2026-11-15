// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/app_locales.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/app/shell/app_shell.dart';
import 'package:soundspan/app/shell/avatar_menu.dart';
import 'package:soundspan/app/shell/top_bar.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/features/settings/settings.dart';
import 'package:soundspan/shared/widgets/wordmark.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_root.dart';

final Profile _profile = Profile(
  id: 'p1',
  baseUrl: Uri.parse('https://music.example.com'),
  displayName: 'music.example.com',
  userId: 'user-p1',
  username: 'ada',
  role: 'user',
  authKind: AuthKind.password,
  deviceId: 'device-p1',
  credentialCreatedAt: DateTime.utc(2025),
  state: ProfileState.active,
  lastUsedAt: DateTime.utc(2025),
);

final List<Override> _overrides = [
  profilesProvider.overrideWith((ref) => Stream.value([_profile])),
  initialActiveProfileIdProvider.overrideWithValue('p1'),
];

Widget _shell() => AppShell(
  selectedIndex: 0,
  onDestinationSelected: (_) {},
  onSearch: (_) {},
  onBack: () {},
  child: const PlaceholderScreen('Home', branchRoot: true),
);

const List<Size> _sizes = [
  TestSizes.compact,
  TestSizes.medium,
  TestSizes.expanded,
];

/// The English name of the pseudo-locale in the language list.
final String _pseudoName = lookupAppLocalizations(pseudoLocale)
    .settingsLanguageName;

void main() {
  for (final size in _sizes) {
    for (final textScale in [1.0, 2.0]) {
      testWidgets('the shell at ${size.width.toInt()} in en_XA at text scale '
          '$textScale lays out without overflow errors', (tester) async {
        await tester.pumpApp(
          _shell(),
          size: size,
          locale: pseudoLocale,
          textScale: textScale,
          overrides: _overrides,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final l10n = lookupAppLocalizations(pseudoLocale);
        expect(find.textContaining(l10n.navHome), findsWidgets);
      });
    }
  }

  for (final size in [TestSizes.compact, TestSizes.expanded]) {
    testWidgets(
      'settings (appearance and servers) in en_XA at ${size.width.toInt()} '
      'lay out without overflow',
      (tester) async {
        final root = await tester.pumpSoundspanApp(
          stored: StoredProfile.signedIn,
          size: size,
        );
        root.container.read(routerProvider).go(SettingsSection.appearance.path);
        await tester.pumpAndSettle();
        await tester.tap(find.text(_pseudoName));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final l10n = lookupAppLocalizations(pseudoLocale);
        expect(find.text(l10n.settingsThemeTitle), findsOneWidget);

        root.container.read(routerProvider).go(SettingsSection.servers.path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.text(l10n.settingsServersAccount('ada', 'music.example.com')),
          findsOneWidget,
        );
      },
    );
  }

  group('in a language other than English', () {
    for (final size in _sizes) {
      testWidgets('the shell at ${size.width.toInt()} in ar builds without '
          'exceptions and NavigationRail finds MaterialLocalizations', (
        tester,
      ) async {
        await tester.pumpApp(
          _shell(),
          size: size,
          locale: const Locale('ar'),
          overrides: _overrides,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final context = tester.element(find.byType(AdaptiveShell));
        expect(Localizations.localeOf(context), const Locale('ar'));
        expect(Directionality.of(context), TextDirection.rtl);
        // The app's messages fall back to English.
        expect(AppLocalizations.of(context).navHome, 'Home');
        final materialLocalizations = MaterialLocalizations.of(context);
        // material_ui's own Arabic localizations, not the English default.
        expect(
          materialLocalizations.backButtonTooltip,
          isNot(const DefaultMaterialLocalizations().backButtonTooltip),
        );
        if (find.byType(NavigationRail).evaluate().isNotEmpty) {
          final rail = tester.element(find.byType(NavigationRail));
          expect(MaterialLocalizations.of(rail), same(materialLocalizations));
        }
      });
    }
  });

  group('in RTL', () {
    testWidgets('the navigation rail is on the right', (tester) async {
      await tester.pumpApp(
        _shell(),
        size: TestSizes.medium,
        locale: const Locale('ar'),
        overrides: _overrides,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final rail = tester.getRect(find.byType(NavigationRail));
      expect(rail.right, TestSizes.medium.width);
      expect(
        tester.getRect(find.byType(PlaceholderScreen)).right,
        lessThanOrEqualTo(rail.left),
      );
    });

    testWidgets('the sidebar is on the right and the top bar order is '
        'mirrored', (tester) async {
      await tester.pumpApp(
        _shell(),
        size: TestSizes.expanded,
        locale: const Locale('ar'),
        overrides: _overrides,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final sidebar = tester.getRect(find.byKey(AdaptiveShell.sidebarKey));
      expect(sidebar.left, greaterThan(TestSizes.expanded.width / 2));
      expect(
        tester.getRect(find.byType(PlaceholderScreen)).right,
        lessThanOrEqualTo(sidebar.left),
      );

      // Start to end: wordmark, back, search, avatar; right to left on
      // screen.
      final wordmark = tester.getCenter(find.byType(Wordmark)).dx;
      final back = tester.getCenter(find.byTooltip('Back')).dx;
      final search = tester.getCenter(find.byKey(TopBar.searchFieldKey)).dx;
      final avatar = tester.getCenter(find.byKey(AvatarButton.buttonKey)).dx;
      expect(wordmark, greaterThan(back));
      expect(back, greaterThan(search));
      expect(search, greaterThan(avatar));
    });
  });

  group('the language list', () {
    Future<void> openAppearance(WidgetTester tester, String channel) async {
      final root = await tester.pumpSoundspanApp(
        stored: StoredProfile.signedIn,
        overrides: [buildChannelProvider.overrideWithValue(channel)],
      );
      root.container.read(routerProvider).go(SettingsSection.appearance.path);
      await tester.pumpAndSettle();
    }

    testWidgets('offers en_XA on the dev channel', (tester) async {
      await openAppearance(tester, 'dev');
      expect(find.text('English'), findsOneWidget);
      expect(find.text(_pseudoName), findsOneWidget);
    });

    testWidgets('does not offer en_XA on stable', (tester) async {
      await openAppearance(tester, 'stable');
      expect(find.text('English'), findsOneWidget);
      expect(find.text(_pseudoName), findsNothing);
    });

    test('appLocalesFor includes en_XA only on dev', () {
      expect(appLocalesFor('dev'), contains(pseudoLocale));
      expect(appLocalesFor('stable'), isNot(contains(pseudoLocale)));
      expect(appLocalesFor('stable'), contains(const Locale('en')));
    });
  });

  test('every message in app_en.arb has a description', () {
    final arb = jsonDecode(
      File('lib/app/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, Object?>;
    final messages = arb.keys.where((key) => !key.startsWith('@'));
    expect(messages, isNotEmpty);
    for (final key in messages) {
      final metadata = arb['@$key'];
      expect(metadata, isA<Map<String, Object?>>(), reason: key);
      final description = (metadata! as Map<String, Object?>)['description'];
      expect(description, isA<String>(), reason: key);
      expect((description! as String).trim(), isNotEmpty, reason: key);
    }
  });
}
