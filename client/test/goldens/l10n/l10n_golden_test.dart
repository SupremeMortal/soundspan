// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/app_locales.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/shell/app_shell.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';

import '../../helpers/golden.dart';
import '../../helpers/track_row_samples.dart';

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

final List<Override> _overrides = [
  profilesProvider.overrideWith(
    (ref) => Stream.value([
      _profile('p1', 'music.example.com', 'ada', 2),
      _profile('p2', 'friends.example.org', 'ada', 1),
    ]),
  ),
  initialActiveProfileIdProvider.overrideWithValue('p1'),
];

Widget _shell(BuildContext context) => AppShell(
  selectedIndex: 0,
  onDestinationSelected: (_) {},
  onSearch: (_) {},
  onBack: () {},
  child: PlaceholderScreen(
    AppLocalizations.of(context).navHome,
    branchRoot: true,
  ),
);

void main() {
  // The shell in the pseudo-locale and right to left (`ar`: framework
  // localizations and direction, English app messages), at every width in
  // both themes.
  goldenMatrix(
    'shell',
    builder: _shell,
    overrides: _overrides,
    locales: const [pseudoLocale, Locale('ar')],
  );
  // Track rows with an index, with a thumbnail and disabled, in the same two
  // locales, compact and expanded (with the album column), dark only.
  goldenMatrix(
    'track_row',
    sizes: const [Size(390, 320), Size(1440, 320)],
    themes: const [ThemeMode.dark],
    builder: trackRowSamples,
    locales: const [pseudoLocale, Locale('ar')],
  );
}
