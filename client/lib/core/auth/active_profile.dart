// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/platform/secrets/secrets.dart';
import 'package:soundspan/shared/clock.dart';

/// The active profile id read from the app settings at startup. Bootstrap
/// overrides it before the first read of [activeProfileIdProvider].
final Provider<String?> initialActiveProfileIdProvider = Provider<String?>(
  (ref) => throw UnimplementedError(
    'initialActiveProfileIdProvider is set by bootstrap',
  ),
);

/// The id of the profile the app shows, or null when none is chosen.
class ActiveProfileId extends Notifier<String?> {
  @override
  String? build() => ref.read(initialActiveProfileIdProvider);

  /// Makes [id] the active profile. The `activeProfileId` app setting is
  /// written before the state changes, so a listener never sees an id that
  /// is not persisted.
  Future<void> set(String? id) async {
    await ref
        .read(appSettingsProvider)
        .write(AppSettingKeys.activeProfileId, id);
    state = id;
  }
}

/// The active profile id; persisted in the app settings (doc 02, root
/// scope).
final NotifierProvider<ActiveProfileId, String?> activeProfileIdProvider =
    NotifierProvider<ActiveProfileId, String?>(ActiveProfileId.new);

/// The app's [ProfileRepository] over the root storage providers.
final Provider<ProfileRepository> profileRepositoryProvider =
    Provider<ProfileRepository>(
      (ref) => ProfileRepository(
        ref.watch(appDatabaseProvider),
        ref.watch(secretStoreProvider),
        ref.watch(appPathsProvider),
        ref.watch(databaseOpenerProvider),
        ref.watch(clockProvider),
      ),
    );
