// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/app/shell/app_shell.dart';
import 'package:soundspan/app/shell/avatar_menu.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/realtime/presence_controller.dart';
import 'package:soundspan/core/realtime/presence_models.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/features/social/social.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../../helpers/fake_reachability.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import '../../player/ui/player_rig.dart';
import 'presence_fakes.dart';

void main() {
  /// Pumps the Activity panel content alone.
  Future<FakePresenceController> pumpView(
    WidgetTester tester, {
    PresenceState state = const PresenceState(roster: threeUsers),
    bool federation = false,
    FakeReachability? reachability,
  }) async {
    final controller = FakePresenceController(state);
    await tester.pumpApp(
      const Scaffold(body: ActivityPanel()),
      size: const Size(360, 800),
      overrides: [
        controller.providerOverride,
        capabilitiesOverride(federation: federation),
        if (reachability != null)
          reachabilityProvider.overrideWithValue(reachability),
      ],
    );
    await tester.pumpAndSettle();
    return controller;
  }

  group('at 1440', () {
    Future<(PlayerRig, FakePresenceController)> pumpShell(
      WidgetTester tester,
    ) async {
      final rig = PlayerRig();
      final controller = FakePresenceController(
        const PresenceState(roster: threeUsers),
      );
      final container = await tester.pumpApp(
        AppShell(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          onSearch: (_) {},
          child: const Center(child: Text('content')),
        ),
        size: TestSizes.expanded,
        overrides: [
          ...rig.overrides,
          controller.providerOverride,
          capabilitiesOverride(),
          initialActiveProfileIdProvider.overrideWithValue(null),
        ],
      );
      container.read(playbackControllerProvider);
      await rig.start(tester, play: false);
      await tester.pumpAndSettle();
      return (rig, controller);
    }

    testWidgets('the top-bar toggle opens Activity in the right panel and '
        'replaces the queue; closing it calls close', (tester) async {
      final (rig, controller) = await pumpShell(tester);
      final panel = find.byKey(AdaptiveShell.rightPanelKey);

      await tester.tap(find.byTooltip('Queue'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: panel, matching: find.byType(QueueView)),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Activity'));
      await tester.pumpAndSettle();
      expect(tester.getSize(panel).width, AdaptiveShell.rightPanelWidth);
      expect(
        find.descendant(of: panel, matching: find.byType(ActivityPanel)),
        findsOneWidget,
      );
      expect(find.byType(QueueView), findsNothing);
      expect(
        find.descendant(of: panel, matching: find.text('Ana')),
        findsOneWidget,
      );
      expect(controller.opens, 1);
      expect(controller.closes, 0);

      await tester.tap(find.byTooltip('Activity'));
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
      expect(controller.closes, 1);
      await rig.close(tester);
    });
  });

  testWidgets('at 390 the avatar-sheet entry opens the Activity sheet', (
    tester,
  ) async {
    final controller = FakePresenceController(
      const PresenceState(roster: threeUsers),
    );
    await tester.pumpApp(
      const WindowClassScope(
        windowClass: WindowClass.compact,
        child: Scaffold(body: Center(child: AvatarButton())),
      ),
      overrides: [
        controller.providerOverride,
        capabilitiesOverride(),
        profilesProvider.overrideWithValue(const AsyncData(<Profile>[])),
        initialActiveProfileIdProvider.overrideWithValue(null),
      ],
    );

    await tester.tap(find.byKey(AvatarButton.buttonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();

    expect(find.byType(ActivitySheet), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(controller.opens, 1);

    Navigator.of(tester.element(find.byType(ActivitySheet))).pop();
    await tester.pumpAndSettle();
    expect(controller.closes, 1);
  });

  testWidgets('rows show the status and the track with its artwork', (
    tester,
  ) async {
    await pumpView(tester);

    expect(find.text('On this server'), findsOneWidget);
    expect(find.text('Playing'), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Idle'), findsOneWidget);
    expect(find.text('Blue Hour · The Lanterns'), findsOneWidget);
    expect(find.text('Low Tide · Harbour'), findsOneWidget);
    expect(find.byType(Artwork), findsNWidgets(2));
    expect(
      tester.getSize(find.byType(Artwork).first),
      const Size.square(ActivityView.artworkSize),
    );
    expect(find.text('On connected servers'), findsNothing);
  });

  const withPeers = PresenceState(roster: PresenceRoster(peers: onePeer));

  testWidgets('without federation the peers section is left out', (
    tester,
  ) async {
    await pumpView(tester, state: withPeers);
    expect(find.text('On connected servers'), findsNothing);
    expect(find.text('Nia'), findsNothing);
    expect(find.text('Nobody else is online'), findsOneWidget);
  });

  testWidgets('with federation and no peers the peers section is left out', (
    tester,
  ) async {
    await pumpView(tester, federation: true);
    expect(find.text('On connected servers'), findsNothing);
  });

  testWidgets('with federation the peers section lists the peers', (
    tester,
  ) async {
    await pumpView(tester, state: withPeers, federation: true);
    expect(find.text('On connected servers'), findsOneWidget);
    expect(find.text('Nia'), findsOneWidget);
    expect(find.text('Playing on North'), findsOneWidget);
    expect(find.text('Far · Band'), findsOneWidget);
  });

  testWidgets('loading shows skeleton rows', (tester) async {
    await pumpView(tester, state: const PresenceState(loading: true));
    expect(find.byKey(ActivityView.skeletonKey), findsOneWidget);
    expect(find.text('Nobody else is online'), findsNothing);
  });

  testWidgets('an empty roster says nobody else is online', (tester) async {
    await pumpView(
      tester,
      state: const PresenceState(roster: PresenceRoster()),
    );
    expect(find.text('Nobody else is online'), findsOneWidget);
    expect(find.text('On this server'), findsNothing);
  });

  testWidgets('offline shows the offline empty state', (tester) async {
    await pumpView(
      tester,
      reachability: FakeReachability(initial: Reachability.noNetwork),
    );
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    expect(find.text('Ana'), findsNothing);
  });

  testWidgets('an error without a roster offers Retry', (tester) async {
    final controller = await pumpView(
      tester,
      state: const PresenceState(
        failed: true,
        error: api.ServerError(status: 500),
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(controller.retries, 1);
  });

  testWidgets('a failed refetch keeps the last roster', (tester) async {
    final controller = await pumpView(tester);
    controller.emit(
      const PresenceState(
        roster: threeUsers,
        failed: true,
        error: api.ServerError(status: 500),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
  });

  testWidgets('each row is one semantics node; guidelines pass', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpView(
      tester,
      federation: true,
      state: PresenceState(roster: threeUsersAndPeer),
    );

    for (final label in [
      'Ana, playing Blue Hour by The Lanterns',
      'Ben, paused on Low Tide by Harbour',
      'Cy, Idle',
      'Nia, playing Far by Band, on North',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    await expectMeetsGuidelines(tester);
    handle.dispose();
  });
}
