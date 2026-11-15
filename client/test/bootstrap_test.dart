// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:soundspan/bootstrap.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/capability_refresher.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';

import 'core/logging/recording_sink.dart';
import 'core/profile/profile_harness.dart' show RecordingAppPaths;
import 'helpers/fake_desktop_shell.dart';
import 'helpers/in_memory_database_opener.dart';
import 'helpers/in_memory_secret_store.dart';
import 'helpers/test_root.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('createRootContainer over in-memory storage yields working '
      'providers', () async {
    PackageInfo.setMockInitialValues(
      appName: 'soundspan',
      packageName: 'app.soundspan',
      version: '1.2.3',
      buildNumber: '4',
      buildSignature: '',
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final opener = InMemoryDatabaseOpener();

    final root = await createRootContainer(
      paths: RecordingAppPaths(),
      databaseOpener: opener,
      secretStore: InMemorySecretStore(),
    );
    addTearDown(() async {
      await root.read(profileRuntimeProvider).dispose();
      root.dispose();
    });

    final rows = await root
        .read(appDatabaseProvider)
        .customSelect('SELECT 1 AS one')
        .get();
    expect(rows.single.read<int>('one'), 1);
    expect(opener.opened, contains(const AppDatabaseTarget()));
    expect(
      root.read(profileRuntimeProvider).state.value,
      ProfileRuntimeState.none,
    );
    expect(root.read(userAgentProvider), 'soundspan-client/1.2.3 (linux)');
  });

  test('a stored active profile is active before the first frame', () async {
    final root = await TestRoot.create(stored: StoredProfile.signedIn);
    addTearDown(root.dispose);

    final runtime = root.container.read(profileRuntimeProvider);
    expect(runtime.state.value, ProfileRuntimeActive(root.profileId!));
    expect(runtime.container, isNotNull);
  });

  test('an error reported to FlutterError.onError reaches the logger', () {
    final previousFlutter = FlutterError.onError;
    final previousPlatform = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = previousFlutter;
      PlatformDispatcher.instance.onError = previousPlatform;
      AppLogging.reset();
    });
    final sink = RecordingSink();
    AppLogging.configure(sinks: [sink], releaseMode: false);

    installErrorHooks();
    FlutterError.reportError(
      FlutterErrorDetails(exception: StateError('boom'), library: 'test'),
    );
    final handled = PlatformDispatcher.instance.onError!(
      ArgumentError('async boom'),
      StackTrace.current,
    );

    expect(handled, isTrue);
    expect(sink.entries.map((e) => (e.level, e.error)), [
      ('severe', 'Bad state: boom'),
      ('severe', 'Invalid argument(s): async boom'),
    ]);
    expect(sink.entries.first.fields, {'library': 'test'});
  });

  test('the capability refresh starts after the first frame', () {
    expect(postFirstFrameTasks, contains(startCapabilityRefresh));
  });

  test('userAgentFor names the version and the operating system', () {
    expect(userAgentFor('0.1.0', os: 'web'), 'soundspan-client/0.1.0 (web)');
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(currentOsName(), 'ios');
  });

  test('restoreWindow restores the saved bounds on a desktop', () async {
    final shell = FakeDesktopShell();
    final root = await TestRoot.create(
      overrides: [
        desktopShellProvider.overrideWithValue(shell),
        platformCapabilitiesProvider.overrideWithValue(
          PlatformCapabilities.windowsAndLinux,
        ),
      ],
    );
    addTearDown(root.dispose);
    const saved = WindowBounds(left: 10, top: 20, width: 900, height: 700);
    await AppSettingsStore(root.container.read(appDatabaseProvider))
        .write(AppSettingKeys.windowBounds, saved);

    await restoreWindow(root.container);

    expect(shell.bounds, saved);
    expect(shell.shown, isTrue);
  });

  test('a window that cannot be restored is logged, not thrown', () async {
    final sink = RecordingSink();
    AppLogging.configure(sinks: [sink], releaseMode: false);
    addTearDown(AppLogging.reset);
    final root = await TestRoot.create(
      overrides: [
        desktopShellProvider.overrideWithValue(_FailingShell()),
        platformCapabilitiesProvider.overrideWithValue(
          PlatformCapabilities.windowsAndLinux,
        ),
      ],
    );
    addTearDown(root.dispose);

    await restoreWindow(root.container);

    expect(
      sink.entries.map((e) => (e.level, e.message)),
      contains(('severe', 'Could not restore the window')),
    );
  });
}

class _FailingShell extends FakeDesktopShell {
  @override
  Future<void> init() async => throw StateError('no window');
}
