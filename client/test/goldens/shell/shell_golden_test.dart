// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/shell/app_shell.dart';
import 'package:soundspan/app/shell/avatar_menu.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';

import '../../helpers/golden.dart';
import '../../helpers/pump_app.dart';

Profile _profile(String id, String host, String username, int minutes) =>
    Profile(
      id: id,
      baseUrl: Uri.parse('https://$host'),
      displayName: host,
      userId: 'user-$id',
      username: username,
      role: 'user',
      authKind: AuthKind.password,
      deviceId: 'device-$id',
      credentialCreatedAt: DateTime.utc(2025),
      state: ProfileState.active,
      lastUsedAt: DateTime.utc(2025).add(Duration(minutes: minutes)),
    );

final List<Profile> _profiles = [
  _profile('p1', 'music.example.com', 'ada', 2),
  _profile('p2', 'friends.example.org', 'ada', 1),
];

final List<Override> _overrides = [
  profilesProvider.overrideWith((ref) => Stream.value(_profiles)),
  initialActiveProfileIdProvider.overrideWithValue('p1'),
];

Widget _shell(BuildContext context) => AppShell(
  selectedIndex: 0,
  onDestinationSelected: (_) {},
  onSearch: (_) {},
  onBack: () {},
  child: const PlaceholderScreen('Home', branchRoot: true),
);

void main() {
  goldenMatrix('shell', builder: _shell, overrides: _overrides);

  goldenMatrix(
    'shell',
    builder: _shell,
    overrides: _overrides,
    sizes: const [TestSizes.compact, TestSizes.expanded],
    themes: const [ThemeMode.dark],
    textScales: const [2.0],
  );

  goldenMatrix(
    'shell_avatar_menu',
    builder: _shell,
    overrides: _overrides,
    sizes: const [TestSizes.compact, TestSizes.expanded],
    themes: const [ThemeMode.dark],
    act: (tester) => tester.tap(find.byKey(AvatarButton.buttonKey)),
  );
}
