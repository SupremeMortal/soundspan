// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// The real app plays an album with the real engine on a desktop runner (doc
// 11, Integration (desktop)), driven by the keyboard shortcuts and the player
// bar. Run by the desktop-integration jobs of
// .github/workflows/client-device-tests.yml:
//
//   flutter test integration_test/desktop/playback_smoke_test.dart -d <os>
//
// mpv's audio output is the device harness's (doc 06): the PulseAudio null
// sink the Linux job starts, and mpv's null output on Windows.

@Tags(['desktop'])
library;

import 'dart:io' show Platform;

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/features/player/ui/player_bar.dart';

import '../support/desktop_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('an album started from its page plays with the real engine; '
      'Space pauses and resumes, Ctrl+Right (Cmd+Right on macOS) advances '
      'to the next track, and the player bar pauses, resumes and advances', (
    tester,
  ) async {
    final server = (await tester.runAsync(DesktopApiServer.start))!;
    addTearDown(server.close);
    final app = await startDesktopApp(tester, server);
    final l10n = lookupAppLocalizations(const Locale('en'));
    final first = DesktopApiServer.tracks[0];
    final second = DesktopApiServer.tracks[1];
    final third = DesktopApiServer.tracks[2];

    app.container.read(routerProvider).go('/album/${DesktopApiServer.albumId}');
    await pumpUntil(
      tester,
      () => find.text(first.title).evaluate().isNotEmpty,
      reason: 'the album page lists its tracks',
    );
    await tester.tap(find.text(first.title));

    final controller = app.container
        .read(profileRuntimeProvider)
        .container!
        .read(playbackControllerProvider);
    addTearDown(controller.pause);
    await pumpUntil(
      tester,
      () =>
          controller.snapshot.playing &&
          controller.snapshot.position > const Duration(milliseconds: 500),
      reason: 'the first track plays',
    );
    final before = controller.snapshot.position;
    await pumpUntil(
      tester,
      () =>
          controller.snapshot.position >
          before + const Duration(milliseconds: 500),
      reason: 'the position advances',
    );
    expect(
      server.requested,
      contains(startsWith('GET /api/playback/stream/t.${first.id}')),
    );

    final bar = find.byType(PlayerBar);
    expect(
      find.descendant(of: bar, matching: find.text(first.title)),
      findsOneWidget,
    );

    // Space pauses and resumes; the player bar follows.
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await pumpUntil(
      tester,
      () =>
          !controller.snapshot.playing &&
          find
              .descendant(of: bar, matching: find.byTooltip(l10n.playerPlay))
              .evaluate()
              .isNotEmpty,
      reason: 'Space pauses',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await pumpUntil(
      tester,
      () =>
          controller.snapshot.playing &&
          find
              .descendant(of: bar, matching: find.byTooltip(l10n.playerPause))
              .evaluate()
              .isNotEmpty,
      reason: 'Space resumes',
    );

    // Ctrl+Right (Cmd+Right on macOS) advances to the next track.
    final primary = Platform.isMacOS
        ? LogicalKeyboardKey.metaLeft
        : LogicalKeyboardKey.controlLeft;
    await tester.sendKeyDownEvent(primary);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(primary);
    await pumpUntil(
      tester,
      () => find
          .descendant(of: bar, matching: find.text(second.title))
          .evaluate()
          .isNotEmpty,
      reason: 'the shortcut advances and the player bar shows the next track',
    );
    await pumpUntil(
      tester,
      () =>
          controller.snapshot.playing &&
          controller.snapshot.position > const Duration(milliseconds: 500),
      reason: 'the next track plays',
    );

    // The player bar's own controls: pause, resume and next.
    await tester.tap(
      find.descendant(of: bar, matching: find.byTooltip(l10n.playerPause)),
    );
    await pumpUntil(
      tester,
      () =>
          !controller.snapshot.playing &&
          find
              .descendant(of: bar, matching: find.byTooltip(l10n.playerPlay))
              .evaluate()
              .isNotEmpty,
      reason: 'the player bar pauses',
    );
    await tester.tap(
      find.descendant(of: bar, matching: find.byTooltip(l10n.playerPlay)),
    );
    await pumpUntil(
      tester,
      () =>
          controller.snapshot.playing &&
          find
              .descendant(of: bar, matching: find.byTooltip(l10n.playerPause))
              .evaluate()
              .isNotEmpty,
      reason: 'the player bar resumes',
    );
    await tester.tap(
      find.descendant(of: bar, matching: find.byTooltip(l10n.playerNext)),
    );
    await pumpUntil(
      tester,
      () => find
          .descendant(of: bar, matching: find.text(third.title))
          .evaluate()
          .isNotEmpty,
      reason: 'the player bar shows the track after that',
    );
    await pumpUntil(
      tester,
      () =>
          controller.snapshot.playing &&
          controller.snapshot.position > const Duration(milliseconds: 500),
      reason: 'that track plays',
    );
  });
}
