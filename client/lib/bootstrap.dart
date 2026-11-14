// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:soundspan/app/app.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/logging/console_log_sink.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/storage/app/app_database.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/log_sink/log_sink.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan/platform/secrets/secrets.dart';

final AppLogger _log = AppLogger.scope('App');

/// A task that runs after the first frame without blocking the UI (doc 02,
/// Bootstrap Sequence, step 8).
typedef PostFirstFrameTask = Future<void> Function(ProviderContainer root);

/// The tasks [bootstrap] starts, in parallel, after the first frame. Later
/// features append theirs.
final List<PostFirstFrameTask> postFirstFrameTasks = [];

/// Starts the app (doc 02, Bootstrap Sequence): error hooks, paths,
/// logging, `app.db`, the root container and the active profile, then
/// `runApp` and the [postFirstFrameTasks].
Future<void> bootstrap() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      installErrorHooks();
      if (kIsWeb) usePathUrlStrategy();
      final paths = await resolveAppPaths();
      AppLogging.configure(
        sinks: [
          if (kDebugMode) ConsoleLogSink(),
          createPersistentLogSink(directory: kIsWeb ? null : paths.logs),
        ],
        releaseMode: kReleaseMode,
      );
      final root = await createRootContainer(paths: paths);
      runApp(
        UncontrolledProviderScope(container: root, child: const SoundspanApp()),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final task in postFirstFrameTasks) {
          unawaited(
            task(root).catchError((Object error, StackTrace stackTrace) {
              _log.severe('Start-up task failed', const {}, error, stackTrace);
            }),
          );
        }
      });
    },
    (error, stackTrace) =>
        _log.severe('Uncaught error', const {}, error, stackTrace),
  );
}

/// Routes framework and uncaught platform errors to the logger. Nothing is
/// sent off the device.
void installErrorHooks() {
  FlutterError.onError = (details) {
    _log.severe(
      'Framework error',
      {if (details.library != null) 'library': details.library},
      details.exception,
      details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    _log.severe('Uncaught error', const {}, error, stackTrace);
    return true;
  };
}

/// The `User-Agent` of API requests: `soundspan-client/<version> (<os>)`.
String userAgentFor(String version, {String? os}) =>
    'soundspan-client/$version (${os ?? currentOsName()})';

/// The name of the operating system the app runs on, lower case, or `web`.
String currentOsName() => kIsWeb
    ? 'web'
    : switch (defaultTargetPlatform) {
        TargetPlatform.android => 'android',
        TargetPlatform.iOS => 'ios',
        TargetPlatform.macOS => 'macos',
        TargetPlatform.windows => 'windows',
        TargetPlatform.linux => 'linux',
        TargetPlatform.fuchsia => 'fuchsia',
      };

/// Builds the root [ProviderContainer] (doc 02, steps 3, 4 and 6) and
/// activates the stored active profile.
///
/// The container overrides the paths, the database opener, the opened
/// `app.db`, the secret store and the `User-Agent`, and seeds the active
/// profile id from the app settings. Each of them is the platform's unless
/// passed in, so tests build the same container over in-memory storage; an
/// [appDatabase] passed in is not closed with the container. [overrides] are
/// added last. When the stored profile cannot be activated, the failure is
/// logged and no profile is active.
Future<ProviderContainer> createRootContainer({
  AppPaths? paths,
  DatabaseOpener? databaseOpener,
  AppDatabase? appDatabase,
  SecretStore? secretStore,
  String? userAgent,
  List<Override> overrides = const [],
}) async {
  final resolvedPaths = paths ?? await resolveAppPaths();
  final opener = databaseOpener ?? createDatabaseOpener(resolvedPaths);
  final database =
      appDatabase ?? AppDatabase(opener.open(const AppDatabaseTarget()));
  final activeId = await AppSettingsStore(database)
      .read(AppSettingKeys.activeProfileId);

  final root = ProviderContainer(
    overrides: [
      appPathsProvider.overrideWithValue(resolvedPaths),
      databaseOpenerProvider.overrideWithValue(opener),
      appDatabaseProvider.overrideWith((ref) {
        if (appDatabase == null) {
          ref.onDispose(() => unawaited(database.close()));
        }
        return database;
      }),
      secretStoreProvider.overrideWithValue(secretStore ?? createSecretStore()),
      userAgentProvider.overrideWithValue(
        userAgent ?? userAgentFor((await PackageInfo.fromPlatform()).version),
      ),
      initialActiveProfileIdProvider.overrideWithValue(activeId),
      ...overrides,
    ],
  );
  try {
    await root.read(profileRuntimeProvider).start();
  } on Object catch (error, stackTrace) {
    _log.severe(
      'Could not activate the stored profile',
      {'profileId': activeId},
      error,
      stackTrace,
    );
  }
  return root;
}
