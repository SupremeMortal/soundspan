// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// The real app on an Android emulator against the contract server (doc 11,
// Integration (mobile)): sign in, play, background, pause and resume from
// the notification, and the play reported. Run by the patrol-android job of
// .github/workflows/client-device-tests.yml:
//
//   patrol test --target integration_test/patrol/playback_background_test.dart \
//       --dart-define=E2E_SERVER=http://10.0.2.2:3030 \
//       --dart-define=E2E_USERNAME=<user> --dart-define=E2E_PASSWORD=<password>
//
// Widgets are found by their keys; the album is found by its fixture title.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:patrol/patrol.dart';
import 'package:soundspan/app/app.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/bootstrap.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/features/connect/ui/address_screen.dart';
import 'package:soundspan/features/connect/ui/probe_screen.dart';
import 'package:soundspan/features/connect/ui/sign_in_screen.dart';
import 'package:soundspan/features/home/ui/home_screen.dart';
import 'package:soundspan/features/library/ui/library_screen.dart';
import 'package:soundspan/features/player/ui/mini_player.dart';
import 'package:soundspan/features/player/ui/player_item.dart';
import 'package:soundspan/shared/widgets/action_bar.dart';

const _server = String.fromEnvironment('E2E_SERVER');
const _username = String.fromEnvironment('E2E_USERNAME');
const _password = String.fromEnvironment('E2E_PASSWORD');

/// The fixture album whose first track runs 30 seconds
/// (contract_test/fixtures/library.json); the albums sorted before it have
/// 3-second tracks, too short for the background steps.
const _albumTitle = 'First Light';

const _wait = Duration(seconds: 30);

void main() {
  patrolTest(
    'sign in, play, background, pause and resume from the notification, '
    'and the play is reported',
    timeout: const Timeout(Duration(minutes: 10)),
    config: const PatrolTesterConfig(
      existsTimeout: _wait,
      visibleTimeout: _wait,
      settlePolicy: SettlePolicy.noSettle,
      printLogs: true,
    ),
    ($) async {
      expect(_server, isNotEmpty, reason: 'E2E_SERVER is set');
      // bootstrap routes framework errors to the app's logger; the test's
      // own handler is put back so an error fails the test.
      final testOnError = FlutterError.onError;
      await bootstrap();
      FlutterError.onError = testOnError;

      // 1. Fresh install: the address; the probe reaches ready (a cleartext
      // private host is shown with Continue before sign-in).
      await $(AddressScreen.addressFieldKey).enterText(_server);
      await $(AddressScreen.submitKey).tap();
      await $(ProbeScreen.continueKey).waitUntilVisible();
      await $(ProbeScreen.continueKey).tap();

      // 2. Password sign-in; the shell shows Home.
      await $(SignInScreen.usernameKey).enterText(_username);
      await $(SignInScreen.passwordKey).enterText(_password);
      await $(SignInScreen.submitKey).tap();
      await $(AdaptiveShell).waitUntilVisible();
      await $(HomeScreen).waitUntilVisible();

      // 3. Library → Albums → the album; Play.
      await $(AdaptiveShell.destinationKey(ShellDestination.library)).tap();
      await $(LibraryScreen.tabKey(LibraryTab.albums)).tap();
      await $(_albumTitle).scrollTo().tap();
      await $(ActionBar.playKey).tap();

      final container = ProviderScope.containerOf(
        $.tester.element(find.byType(SoundspanApp)),
      );
      PlaybackSnapshot snapshot() => container
          .read(profileRuntimeProvider)
          .container!
          .read(playbackControllerProvider)
          .snapshot;

      // 4. The notification permission, asked on the first play.
      if (await $.platform.mobile.isPermissionDialogVisible(
        timeout: const Duration(seconds: 5),
      )) {
        await $.platform.mobile.grantPermissionWhenInUse();
      }

      await _until($, () => snapshot().playing, reason: 'playback starts');
      await $(MiniPlayer.playPauseKey)
          .$(Icons.pause_rounded)
          .waitUntilVisible();
      final started = snapshot().position;
      await _until(
        $,
        () => snapshot().position >= started + const Duration(seconds: 2),
        reason: 'the position advances by 2 seconds',
      );
      final first = snapshot().current!;
      final title = first.playerTitle;
      final artist = first.playerSubtitle;

      // 5. Home; the notification in the shade shows the track.
      await $.platform.mobile.pressHome();
      await Future<void>.delayed(const Duration(seconds: 5));
      await $.platform.mobile.openNotifications();
      await $.platform.android.waitUntilVisible(
        AndroidSelector(text: title),
        timeout: _wait,
      );
      // System UI draws the media notification as its media player, which
      // getNotifications does not list; that its Pause pauses this app
      // (step 6) shows it is soundspan's.

      // 6. Pause from the notification; the player stays paused.
      await $.platform.android.tap(
        const AndroidSelector(contentDescription: 'Pause'),
        timeout: _wait,
      );
      await $.platform.mobile.closeNotifications();
      await $.platform.mobile.openApp();
      await _until($, () => !snapshot().playing, reason: 'playback pauses');
      await $(MiniPlayer.playPauseKey)
          .$(Icons.play_arrow_rounded)
          .waitUntilVisible();
      final paused = snapshot().position;
      await _hold($, const Duration(seconds: 3));
      expect(
        snapshot().position - paused,
        lessThanOrEqualTo(const Duration(seconds: 1)),
        reason: 'the position holds while paused',
      );

      // 7. Play from the notification; playback resumes.
      await $.platform.mobile.openNotifications();
      await $.platform.android.tap(
        const AndroidSelector(contentDescription: 'Play'),
        timeout: _wait,
      );
      await $.platform.mobile.closeNotifications();
      await $.platform.mobile.openApp();
      await _until($, () => snapshot().playing, reason: 'playback resumes');
      await $(MiniPlayer.playPauseKey)
          .$(Icons.pause_rounded)
          .waitUntilVisible();
      final resumed = snapshot().position;
      await _until(
        $,
        () => snapshot().position > resumed + const Duration(seconds: 1),
        reason: 'the position advances after resuming',
      );

      // 8. The next track; the play of the first is reported.
      await $(MiniPlayer.nextKey).tap();
      await _until(
        $,
        () => snapshot().current?.queueItemId != first.queueItemId,
        reason: 'the next track is current',
      );
      await _untilReported(artist);
    },
  );
}

/// Pumps until [condition] holds, failing after [_wait].
Future<void> _until(
  PatrolIntegrationTester $,
  bool Function() condition, {
  required String reason,
}) async {
  final end = DateTime.now().add(_wait);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting: $reason');
    await $.pump(const Duration(milliseconds: 200));
  }
}

/// Pumps frames for [duration].
Future<void> _hold(PatrolIntegrationTester $, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await $.pump(const Duration(milliseconds: 200));
  }
}

/// Polls `GET /api/library/recently-listened` as the test user for up to
/// 15 seconds until it lists [artist]: the endpoint lists the artists of
/// the user's recent plays, so the first track's play was reported.
Future<void> _untilReported(String artist) async {
  final client = HttpClient();
  try {
    final token = await _login(client);
    final end = DateTime.now().add(const Duration(seconds: 15));
    var last = '';
    while (DateTime.now().isBefore(end)) {
      final request = await client.getUrl(
        Uri.parse('$_server/api/library/recently-listened?limit=10'),
      );
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      final response = await request.close();
      last = await response.transform(utf8.decoder).join();
      final items = (jsonDecode(last) as Map<String, dynamic>)['items'] as List;
      if (items.any((item) => (item as Map)['name'] == artist)) return;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    fail('recently listened never listed "$artist" (last: $last)');
  } finally {
    client.close(force: true);
  }
}

Future<String> _login(HttpClient client) async {
  final request = await client.postUrl(Uri.parse('$_server/api/auth/login'));
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode({'username': _username, 'password': _password}));
  final response = await request.close();
  final body = jsonDecode(
    await response.transform(utf8.decoder).join(),
  ) as Map<String, dynamic>;
  return body['token'] as String;
}
