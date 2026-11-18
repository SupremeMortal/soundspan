// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// The central promise of downloads on an Android emulator against the
// contract server (doc 07, Transfers; doc 11, Integration (mobile)):
// download, kill the app, relaunch, play offline.
//
// Patrol runs the test inside the app's process, so the test cannot kill
// the app and carry on. The patrol-android job of
// .github/workflows/client-device-tests.yml therefore runs this file twice
// through integration_test/patrol/run_android.sh, keeping the app
// installed between the runs:
//
//   1. E2E_PHASE=download: sign in, open the album, tap Download and wait
//      for its first item to complete.
//   2. `adb shell am force-stop io.soundspan.app` kills the app, and with it
//      the transfers it was running.
//   3. E2E_PHASE=offline: the relaunched app finishes the album; once its
//      glyph shows it completed, airplane mode is enabled, the album plays,
//      its position advances and its quality badge reads "Downloaded".
//      Airplane mode is disabled in tear-down.
//
// Each run also takes --dart-define=E2E_SERVER=http://10.0.2.2:3030,
// E2E_USERNAME and E2E_PASSWORD.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show FlutterError, Locale;
import 'package:patrol/patrol.dart';
import 'package:soundspan/app/app.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/bootstrap.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/features/connect/ui/address_screen.dart';
import 'package:soundspan/features/connect/ui/probe_screen.dart';
import 'package:soundspan/features/connect/ui/sign_in_screen.dart';
import 'package:soundspan/features/downloads/ui/collection_download_button.dart';
import 'package:soundspan/features/library/ui/library_screen.dart';
import 'package:soundspan/shared/widgets/action_bar.dart';
import 'package:soundspan/shared/widgets/download_glyph.dart';
import 'package:soundspan/shared/widgets/quality_badge.dart';

const _server = String.fromEnvironment('E2E_SERVER');
const _username = String.fromEnvironment('E2E_USERNAME');
const _password = String.fromEnvironment('E2E_PASSWORD');
const _phase = String.fromEnvironment('E2E_PHASE');

/// The fixture album downloaded and played
/// (contract_test/fixtures/library.json).
const _albumTitle = 'First Light';

const _wait = Duration(seconds: 30);

/// How long the whole album may take to download after the relaunch.
const _downloadWait = Duration(minutes: 5);

const _config = PatrolTesterConfig(
  existsTimeout: _wait,
  visibleTimeout: _wait,
  settlePolicy: SettlePolicy.noSettle,
  printLogs: true,
);

void main() {
  patrolTest(
    'download an album, kill the app, relaunch and play it offline '
    '(phase $_phase)',
    timeout: const Timeout(Duration(minutes: 15)),
    config: _config,
    ($) async {
      expect(_server, isNotEmpty, reason: 'E2E_SERVER is set');
      expect(
        _phase,
        anyOf('download', 'offline'),
        reason: 'E2E_PHASE is download or offline',
      );
      // bootstrap routes framework errors to the app's logger; the test's
      // own handler is put back so an error fails the test.
      final testOnError = FlutterError.onError;
      await bootstrap();
      FlutterError.onError = testOnError;

      if (_phase == 'download') {
        await _download($);
      } else {
        await _playOffline($);
      }
    },
  );
}

ProviderContainer _profile(PatrolIntegrationTester $) =>
    ProviderScope.containerOf($.tester.element(find.byType(SoundspanApp)))
        .read(profileRuntimeProvider)
        .container!;

Future<void> _openAlbum(PatrolIntegrationTester $) async {
  await $(AdaptiveShell.destinationKey(ShellDestination.library)).tap();
  await $(LibraryScreen.tabKey(LibraryTab.albums)).tap();
  await $(_albumTitle).scrollTo().tap();
}

/// Phase 1: sign in, download the album and wait for its first item.
Future<void> _download(PatrolIntegrationTester $) async {
  await $(AddressScreen.addressFieldKey).enterText(_server);
  await $(AddressScreen.submitKey).tap();
  await $(ProbeScreen.continueKey).waitUntilVisible();
  await $(ProbeScreen.continueKey).tap();
  await $(SignInScreen.usernameKey).enterText(_username);
  await $(SignInScreen.passwordKey).enterText(_password);
  await $(SignInScreen.submitKey).tap();
  await $(AdaptiveShell).waitUntilVisible();

  await _openAlbum($);
  await $(CollectionDownloadButton.downloadKey).tap();

  // The notification permission, asked when the first download starts;
  // downloads run whatever the answer.
  if (await $.platform.mobile.isPermissionDialogVisible(
    timeout: const Duration(seconds: 10),
  )) {
    await $.platform.mobile.grantPermissionWhenInUse();
  }

  final downloads = _profile($).read(downloadControllerProvider);
  await _until(
    $,
    () async {
      final entries = await downloads.watchCollectionEntries().first;
      final album = entries.where((e) => e.kind == CollectionKind.album);
      return album.isNotEmpty && album.first.state.completedCount >= 1;
    },
    timeout: _downloadWait,
    reason: 'the first item of the album completes',
  );
  // The run ends here; run_android.sh force-stops the app.
}

/// Phase 3: the relaunched app completes the album and plays it offline.
Future<void> _playOffline(PatrolIntegrationTester $) async {
  addTearDown(() => $.platform.mobile.disableAirplaneMode());
  await $(AdaptiveShell).waitUntilVisible();
  await _openAlbum($);

  final downloads = _profile($).read(downloadControllerProvider);
  await _until(
    $,
    () async {
      final entries = await downloads.watchCollectionEntries().first;
      final album = entries.where((e) => e.kind == CollectionKind.album);
      if (album.isEmpty) return false;
      final state = album.first.state;
      return state.activeCount == 0 && state.completedCount > 0;
    },
    timeout: _downloadWait,
    reason: 'the album finishes downloading after the relaunch',
  );
  await _until(
    $,
    () async =>
        $(CollectionDownloadButton.removeKey)
            .$(DownloadGlyph)
            .evaluate()
            .map((e) => e.widget as DownloadGlyph)
            .any((glyph) => glyph.state == DownloadGlyphState.completed),
    reason: "the album's glyph shows it completed",
  );

  await $.platform.mobile.enableAirplaneMode();
  await $(ActionBar.playKey).tap();

  PlaybackController controller() =>
      _profile($).read(playbackControllerProvider);
  PlaybackSnapshot snapshot() => controller().snapshot;

  await _until(
    $,
    () async => snapshot().playing,
    reason: 'offline playback starts',
  );
  final started = snapshot().position;
  final item = snapshot().current?.queueItemId;
  await _until(
    $,
    () async =>
        snapshot().current?.queueItemId != item ||
        snapshot().position >= started + const Duration(seconds: 2),
    reason: 'the position advances offline',
  );
  final badge = QualityBadge.textOf(
    lookupAppLocalizations(const Locale('en')),
    snapshot().quality,
  );
  expect(badge, startsWith('Downloaded'), reason: 'the quality badge');
}

/// Pumps until [condition] holds, failing after [timeout].
Future<void> _until(
  PatrolIntegrationTester $,
  Future<bool> Function() condition, {
  required String reason,
  Duration timeout = _wait,
}) async {
  final end = DateTime.now().add(timeout);
  while (!await condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting: $reason');
    await $.pump(const Duration(milliseconds: 500));
  }
}
