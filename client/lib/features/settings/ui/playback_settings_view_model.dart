// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/podcast_settings.dart';
import 'package:soundspan/core/playback/stream_quality_policy.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/settings/settings_providers.dart';
import 'package:soundspan/core/profile/settings/user_settings.dart';
import 'package:soundspan_api/soundspan_api.dart' show ApiException;

final AppLogger _log = AppLogger.scope('Settings');

/// A stream quality choice and the string stored for it in
/// `quality.wifi` and `quality.cellular` (doc 05).
enum StreamQualityOption {
  /// The quality saved on the server applies.
  serverDefault,

  /// The original file.
  original,

  /// High.
  high,

  /// Medium.
  medium,

  /// Low.
  low;

  /// The stored string.
  String get stored => this == serverDefault ? serverDefaultQuality : name;

  /// The option of a stored value; anything unknown is [serverDefault].
  static StreamQualityOption fromStored(Object? stored) => values.firstWhere(
    (option) => option.stored == stored,
    orElse: () => serverDefault,
  );

  /// The localized label.
  String label(AppLocalizations l10n) => switch (this) {
    serverDefault => l10n.settingsPlaybackQualityServerDefault,
    original => l10n.settingsPlaybackQualityOriginal,
    high => l10n.settingsPlaybackQualityHigh,
    medium => l10n.settingsPlaybackQualityMedium,
    low => l10n.settingsPlaybackQualityLow,
  };
}

/// The skip intervals of episodes the user can choose, in seconds.
const List<int> skipIntervalOptions = [5, 10, 15, 30, 45, 60];

/// The skip interval while `playback.skipSeconds` is unset.
const int defaultSkipSeconds = 15;

/// The default episode speeds the user can choose.
const List<double> podcastSpeedOptions = [
  0.5,
  0.75,
  1,
  1.25,
  1.5,
  1.75,
  2,
  2.5,
  3,
];

/// The episode speed while `playback.speed.podcast` is unset.
const double defaultPodcastSpeed = 1;

/// The levelling modes the user can choose.
const List<LoudnessMode> levellingOptions = [
  LoudnessMode.off,
  LoudnessMode.track,
  LoudnessMode.album,
  LoudnessMode.auto,
];

/// The skip interval a stored value stands for; anything but one of
/// [skipIntervalOptions] is [defaultSkipSeconds].
int skipSecondsFromStored(Object? stored) => switch (stored) {
  final num seconds when skipIntervalOptions.contains(seconds) =>
    seconds.toInt(),
  _ => defaultSkipSeconds,
};

/// The episode speed a stored value stands for; anything but one of
/// [podcastSpeedOptions] is [defaultPodcastSpeed].
double podcastSpeedFromStored(Object? stored) => switch (stored) {
  final num speed when podcastSpeedOptions.contains(speed.toDouble()) =>
    speed.toDouble(),
  _ => defaultPodcastSpeed,
};

/// The localized label of [speed], such as `1.25×`.
String speedLabel(AppLocalizations l10n, double speed) =>
    l10n.settingsPlaybackSpeedValue(speed);

/// The localized label of a levelling [mode].
String levellingLabel(AppLocalizations l10n, LoudnessMode mode) =>
    switch (mode) {
      LoudnessMode.off => l10n.settingsPlaybackLevellingOff,
      LoudnessMode.track => l10n.settingsPlaybackLevellingTrack,
      LoudnessMode.album => l10n.settingsPlaybackLevellingAlbum,
      LoudnessMode.auto => l10n.settingsPlaybackLevellingAuto,
      LoudnessMode.unknown => l10n.settingsPlaybackLevellingUnknown,
    };

/// The device-stored playback settings of the active profile.
@immutable
final class PlaybackDeviceSettings {
  /// Creates the settings.
  const new({
    required this.wifi,
    required this.cellular,
    required this.skipSeconds,
    required this.podcastSpeed,
  });

  /// The stream quality on Wi-Fi and every connection that is not cellular.
  final StreamQualityOption wifi;

  /// The stream quality on mobile data.
  final StreamQualityOption cellular;

  /// The skip interval of episodes, in seconds.
  final int skipSeconds;

  /// The default speed of episodes.
  final double podcastSpeed;
}

/// The decoded value of one `device_settings` key, now and after every
/// change.
final StreamProviderFamily<Object?, String> deviceSettingProvider =
    StreamProvider.autoDispose.family<Object?, String>(
      (ref, key) => ref.watch(deviceSettingsDaoProvider).watch(key),
      dependencies: [deviceSettingsDaoProvider],
    );

/// The playback settings stored on this device for the active profile;
/// a value not read yet shows as its default.
final Provider<PlaybackDeviceSettings> playbackDeviceSettingsProvider =
    Provider.autoDispose<PlaybackDeviceSettings>((ref) {
      Object? read(String key) => ref.watch(deviceSettingProvider(key)).value;
      return PlaybackDeviceSettings(
        wifi: StreamQualityOption.fromStored(read(qualityWifiKey)),
        cellular: StreamQualityOption.fromStored(read(qualityCellularKey)),
        skipSeconds: skipSecondsFromStored(read(skipSecondsKey)),
        podcastSpeed: podcastSpeedFromStored(read(podcastSpeedKey)),
      );
    }, dependencies: [deviceSettingProvider]);

/// Writes the device-stored playback settings.
final class PlaybackSettingsWriter {
  /// Creates the writer over a provider [_ref].
  new(this._ref);

  final Ref _ref;

  /// Stores [option] under [key] (`quality.wifi` or `quality.cellular`).
  /// The current item is not reloaded; the next resolved source uses it.
  Future<void> setQuality(String key, StreamQualityOption option) =>
      _ref.read(deviceSettingsDaoProvider).write(key, option.stored);

  /// Stores the skip interval of episodes.
  Future<void> setSkipSeconds(int seconds) =>
      _ref.read(deviceSettingsDaoProvider).write(skipSecondsKey, seconds);

  /// Stores the default speed of episodes and applies it to the playing
  /// item when that is an episode.
  Future<void> setPodcastSpeed(double speed) async {
    await _ref.read(deviceSettingsDaoProvider).write(podcastSpeedKey, speed);
    if (_ref.read(playbackControllerProvider.exists)) {
      await _ref.read(playbackControllerProvider).setEpisodeSpeed(speed);
    }
  }
}

/// The [PlaybackSettingsWriter] of the active profile.
final Provider<PlaybackSettingsWriter> playbackSettingsWriterProvider =
    Provider.autoDispose<PlaybackSettingsWriter>(
      PlaybackSettingsWriter.new,
      dependencies: [deviceSettingsDaoProvider, playbackControllerProvider],
    );

/// The user's levelling mode as the settings screen shows it: null until
/// a value is known (doc 09, Settings).
///
/// A value the profile session already loaded is shown at once and the
/// settings are fetched again while the server is reachable. [select]
/// shows the new mode at once and saves it with `POST /settings`; on
/// failure the previous mode comes back and the exception is rethrown.
class LevellingSettingNotifier extends Notifier<LoudnessMode?> {
  /// Counts selections; a fetch answered after one started is older.
  int _selections = 0;

  @override
  LoudnessMode? build() {
    final known = ref.read(loudnessModeProvider.notifier);
    final cached = known.loaded ? ref.read(loudnessModeProvider) : null;
    if (ref.read(reachabilityProvider).isOnline) unawaited(_revalidate());
    return cached;
  }

  Future<void> _revalidate() async {
    final selections = _selections;
    final UserSettings settings;
    try {
      settings = await ref.read(settingsRepositoryProvider).fetch();
    } on ApiException catch (error) {
      _log.info('Loading the settings failed', {'error': '$error'});
      return;
    }
    if (!ref.mounted || selections != _selections) return;
    state = settings.loudnessMode;
  }

  /// Shows [mode] and saves it; afterwards the levelling of the next item
  /// uses it.
  Future<void> select(LoudnessMode mode) async {
    final previous = state;
    _selections++;
    state = mode;
    final UserSettings saved;
    try {
      saved = await ref
          .read(settingsRepositoryProvider)
          .update(loudnessMode: mode);
    } on ApiException {
      if (ref.mounted) state = previous;
      rethrow;
    }
    if (!ref.mounted) return;
    ref.read(loudnessModeProvider.notifier).setLoudnessMode(saved.loudnessMode);
    state = saved.loudnessMode;
  }
}

/// The levelling row's value; see [LevellingSettingNotifier].
final NotifierProvider<LevellingSettingNotifier, LoudnessMode?>
levellingSettingProvider =
    NotifierProvider.autoDispose<LevellingSettingNotifier, LoudnessMode?>(
      LevellingSettingNotifier.new,
      dependencies: [settingsRepositoryProvider, loudnessModeProvider],
    );
