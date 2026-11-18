// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/profile/settings/settings_repository.dart';
import 'package:soundspan/core/profile/settings/user_settings.dart';

final AppLogger _log = AppLogger.scope('Settings');

/// The [SettingsRepository] of the profile scope.
final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>(
      (ref) => SettingsRepository(ref.watch(soundspanApiProvider).rest.session),
      dependencies: [soundspanApiProvider],
    );

/// Holds the user's last known [LoudnessMode] for the profile session.
///
/// The settings are fetched once when the notifier is built. Until they
/// have loaded, and when the fetch fails, the mode is [LoudnessMode.off].
class LoudnessModeNotifier extends Notifier<LoudnessMode> {
  /// Whether [setLoudnessMode] was called; a later fetch result is older.
  bool _changed = false;

  /// Whether the mode came from the server, by the fetch or through
  /// [setLoudnessMode]; until then the state is the [LoudnessMode.off]
  /// placeholder.
  bool get loaded => _loaded;
  bool _loaded = false;

  @override
  LoudnessMode build() {
    unawaited(_load(ref.watch(settingsRepositoryProvider)));
    return LoudnessMode.off;
  }

  Future<void> _load(SettingsRepository repository) async {
    final UserSettings settings;
    try {
      settings = await repository.fetch();
    } on Object catch (error) {
      _log.info('Loading the loudness mode failed', {'error': '$error'});
      return;
    }
    if (ref.mounted && !_changed) {
      _loaded = true;
      state = settings.loudnessMode;
    }
  }

  /// Makes [mode] the known mode, after the settings screen saved it.
  void setLoudnessMode(LoudnessMode mode) {
    _changed = true;
    _loaded = true;
    state = mode;
  }
}

/// The user's levelling mode in the profile scope; [LoudnessMode.off]
/// until the settings have loaded.
final NotifierProvider<LoudnessModeNotifier, LoudnessMode>
loudnessModeProvider = NotifierProvider<LoudnessModeNotifier, LoudnessMode>(
  LoudnessModeNotifier.new,
  dependencies: [settingsRepositoryProvider],
);
