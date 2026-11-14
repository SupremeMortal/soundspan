// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/storage/app/app_database.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/paths/paths.dart';

/// Where the app's files live. Bootstrap overrides it (doc 02, step 6).
final Provider<AppPaths> appPathsProvider = Provider<AppPaths>(
  (ref) => throw UnimplementedError('appPathsProvider is set by bootstrap'),
);

/// How databases are opened. Bootstrap overrides it (doc 02, step 6).
final Provider<DatabaseOpener> databaseOpenerProvider =
    Provider<DatabaseOpener>(
      (ref) => throw UnimplementedError(
        'databaseOpenerProvider is set by bootstrap',
      ),
    );

/// The opened `app.db`. Bootstrap overrides it (doc 02, step 6).
final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider is set by bootstrap'),
);

/// The app settings in [appDatabaseProvider].
final Provider<AppSettingsStore> appSettingsProvider =
    Provider<AppSettingsStore>(
      (ref) => AppSettingsStore(ref.watch(appDatabaseProvider)),
    );
