// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:soundspan/bootstrap.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';

import 'core/logging/recording_sink.dart';
import 'core/profile/profile_harness.dart' show RecordingAppPaths;
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

  test('userAgentFor names the version and the operating system', () {
    expect(userAgentFor('0.1.0', os: 'web'), 'soundspan-client/0.1.0 (web)');
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(currentOsName(), 'ios');
  });
}
