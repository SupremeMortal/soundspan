// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/playback/stream_quality_policy.dart';
import 'package:soundspan/core/profile/settings/user_settings.dart';
import 'package:soundspan/features/settings/ui/playback_settings_view_model.dart';
import 'package:soundspan/features/settings/ui/settings_rows.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan_api/soundspan_api.dart' show ApiException;

/// Settings → Playback: stream quality per connection type, the
/// server-stored volume levelling mode, and the skip interval and default
/// speed of podcasts (doc 09, Settings). Reads the profile scope.
///
/// Each row opens a single-choice list: a bottom sheet on touch platforms
/// and a menu elsewhere.
class PlaybackSettingsScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  /// The placeholder of the levelling value while none is known.
  static const Key levellingSkeletonKey = ValueKey<String>(
    'playback-settings-levelling-skeleton',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(playbackDeviceSettingsProvider);
    final writer = ref.watch(playbackSettingsWriterProvider);
    final mobileData = ref.watch(platformCapabilitiesProvider).hasMobileData;
    final levelling = ref.watch(levellingSettingProvider);
    final online =
        (ref.watch(reachabilityStateProvider).value ??
            ref.watch(reachabilityProvider).current) ==
        Reachability.online;

    List<SettingsOption<StreamQualityOption>> qualityOptions() => [
      for (final option in StreamQualityOption.values)
        SettingsOption(
          option,
          option.label(l10n),
          caption: option == StreamQualityOption.serverDefault
              ? l10n.settingsPlaybackQualityServerDefaultCaption
              : null,
        ),
    ];

    Widget qualityRow(String title, String key, StreamQualityOption value) =>
        SettingsChoiceRow<StreamQualityOption>(
          title: title,
          value: value,
          options: qualityOptions(),
          onSelected: (option) => writer.setQuality(key, option),
        );

    final levellingValue = levelling;
    final levellingRow = SettingsChoiceRow<LoudnessMode>(
      title: l10n.settingsPlaybackLevelling,
      value: levellingValue,
      options: [
        for (final mode in levellingOptions)
          SettingsOption(mode, levellingLabel(l10n, mode)),
      ],
      enabled: online && levellingValue != null,
      skeletonKey: levellingSkeletonKey,
      onSelected: (mode) => _selectLevelling(context, ref, mode),
    );

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Spacing.x8),
      children: [
        qualityRow(
          mobileData
              ? l10n.settingsPlaybackQualityWifi
              : l10n.settingsPlaybackQualitySingle,
          qualityWifiKey,
          settings.wifi,
        ),
        if (mobileData)
          qualityRow(
            l10n.settingsPlaybackQualityCellular,
            qualityCellularKey,
            settings.cellular,
          ),
        SettingsCaption(l10n.settingsPlaybackQualityCaption),
        if (online)
          levellingRow
        else
          Tooltip(
            message: l10n.settingsPlaybackLevellingOffline,
            child: levellingRow,
          ),
        SettingsChoiceRow<int>(
          title: l10n.settingsPlaybackSkipInterval,
          value: settings.skipSeconds,
          options: [
            for (final seconds in skipIntervalOptions)
              SettingsOption(
                seconds,
                l10n.settingsPlaybackSkipSeconds(seconds),
              ),
          ],
          onSelected: writer.setSkipSeconds,
        ),
        SettingsChoiceRow<double>(
          title: l10n.settingsPlaybackSpeed,
          value: settings.podcastSpeed,
          options: [
            for (final speed in podcastSpeedOptions)
              SettingsOption(speed, speedLabel(l10n, speed)),
          ],
          onSelected: writer.setPodcastSpeed,
        ),
      ],
    );
  }

  static Future<void> _selectLevelling(
    BuildContext context,
    WidgetRef ref,
    LoudnessMode mode,
  ) async {
    if (ref.read(levellingSettingProvider) == mode) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failed = AppLocalizations.of(context).settingsPlaybackLevellingFailed;
    try {
      await ref.read(levellingSettingProvider.notifier).select(mode);
    } on ApiException {
      messenger?.showSnackBar(SnackBar(content: Text(failed)));
    }
  }
}
