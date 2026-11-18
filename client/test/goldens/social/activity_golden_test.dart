// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart' show find;
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/app_shell.dart';
import 'package:soundspan/app/shell/avatar_menu.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/realtime/presence_controller.dart';
import 'package:soundspan/features/player/player.dart';

import '../../features/player/ui/player_rig.dart';
import '../../features/social/ui/presence_fakes.dart';
import '../../helpers/golden.dart';
import '../../helpers/pump_app.dart';

/// The right panel showing Activity.
class _ActivityOpen extends RightPanelNotifier {
  @override
  RightPanel build() => RightPanel.activity;
}

void main() {
  goldenMatrix(
    'activity_panel',
    builder: (_) => AppShell(
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      onSearch: (_) {},
      child: const SizedBox.expand(),
    ),
    sizes: const [TestSizes.expanded],
    overrides: [
      FakePresenceController(const PresenceState(roster: threeUsers))
          .providerOverride,
      capabilitiesOverride(),
      playbackControllerProvider.overrideWith((ref) {
        final controller = PlayerRig().controller;
        ref.onDispose(controller.dispose);
        return controller;
      }),
      initialActiveProfileIdProvider.overrideWithValue(null),
      rightPanelProvider.overrideWith(_ActivityOpen.new),
    ],
  );

  goldenMatrix(
    'activity_sheet',
    builder: (_) => const WindowClassScope(
      windowClass: WindowClass.compact,
      child: Scaffold(body: Center(child: AvatarButton())),
    ),
    sizes: const [TestSizes.compact],
    overrides: [
      FakePresenceController(const PresenceState(roster: threeUsers))
          .providerOverride,
      capabilitiesOverride(),
      profilesProvider.overrideWithValue(const AsyncData(<Profile>[])),
      initialActiveProfileIdProvider.overrideWithValue(null),
    ],
    act: (tester) async {
      await tester.tap(find.byKey(AvatarButton.buttonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activity'));
    },
  );
}
