// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/playback/stream_quality_policy.dart';
import 'package:soundspan/core/profile/settings/user_settings.dart';
import 'package:soundspan/features/settings/ui/playback_settings_view_model.dart';
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

    List<_Option<StreamQualityOption>> qualityOptions() => [
      for (final option in StreamQualityOption.values)
        _Option(
          option,
          option.label(l10n),
          caption: option == StreamQualityOption.serverDefault
              ? l10n.settingsPlaybackQualityServerDefaultCaption
              : null,
        ),
    ];

    Widget qualityRow(String title, String key, StreamQualityOption value) =>
        _ChoiceRow<StreamQualityOption>(
          title: title,
          value: value,
          options: qualityOptions(),
          onSelected: (option) => writer.setQuality(key, option),
        );

    final levellingValue = levelling;
    final levellingRow = _ChoiceRow<LoudnessMode>(
      title: l10n.settingsPlaybackLevelling,
      value: levellingValue,
      options: [
        for (final mode in levellingOptions)
          _Option(mode, levellingLabel(l10n, mode)),
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
        _Caption(l10n.settingsPlaybackQualityCaption),
        if (online)
          levellingRow
        else
          Tooltip(
            message: l10n.settingsPlaybackLevellingOffline,
            child: levellingRow,
          ),
        _ChoiceRow<int>(
          title: l10n.settingsPlaybackSkipInterval,
          value: settings.skipSeconds,
          options: [
            for (final seconds in skipIntervalOptions)
              _Option(seconds, l10n.settingsPlaybackSkipSeconds(seconds)),
          ],
          onSelected: writer.setSkipSeconds,
        ),
        _ChoiceRow<double>(
          title: l10n.settingsPlaybackSpeed,
          value: settings.podcastSpeed,
          options: [
            for (final speed in podcastSpeedOptions)
              _Option(speed, speedLabel(l10n, speed)),
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

/// One choice of a [_ChoiceRow].
final class _Option<T> {
  const new(this.value, this.label, {this.caption});

  final T value;
  final String label;
  final String? caption;
}

/// A settings row showing [value]'s label as its subtitle (a skeleton
/// while [value] is null) that opens the single-choice list of [options].
class _ChoiceRow<T extends Object> extends StatelessWidget {
  const new({
    required this.title,
    required this.value,
    required this.options,
    required this.onSelected,
    this.enabled = true,
    this.skeletonKey,
  });

  final String title;
  final T? value;
  final List<_Option<T>> options;
  final Future<void> Function(T value) onSelected;
  final bool enabled;
  final Key? skeletonKey;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    final current = options.where((option) => option.value == value);
    return ListTile(
      title: Text(title),
      subtitle: value == null
          ? _Skeleton(key: skeletonKey)
          : Text(current.isEmpty ? '' : current.first.label),
      enabled: enabled,
      minTileHeight: Sizes.touchTarget,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => unawaited(_open(context)),
    );
  }

  Future<void> _open(BuildContext context) async {
    final chosen = await switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => _sheet(context),
      _ => _menu(context),
    };
    if (chosen != null) await onSelected(chosen);
  }

  Future<T?> _sheet(BuildContext context) => showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.x16,
              0,
              Spacing.x16,
              Spacing.x8,
            ),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: context.typography.subtitle.copyWith(
                  color: context.colors.content,
                ),
              ),
            ),
          ),
          for (final option in options)
            Semantics(
              inMutuallyExclusiveGroup: true,
              checked: option.value == value,
              child: ListTile(
                title: Text(option.label),
                subtitle: option.caption == null ? null : Text(option.caption!),
                selected: option.value == value,
                minTileHeight: Sizes.touchTarget,
                trailing: option.value == value
                    ? Icon(Icons.check_rounded, color: context.colors.brand)
                    : null,
                onTap: () => Navigator.of(context).pop(option.value),
              ),
            ),
        ],
      ),
    ),
  );

  Future<T?> _menu(BuildContext context) {
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset(0, box.size.height), ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    return showMenu<T>(
      context: context,
      position: position,
      items: [
        for (final option in options)
          CheckedPopupMenuItem<T>(
            value: option.value,
            checked: option.value == value,
            child: option.caption == null
                ? Text(option.label)
                : ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option.label),
                    subtitle: Text(option.caption!),
                  ),
          ),
      ],
    );
  }
}

/// The placeholder of a row's value: a `surfaceHighlight` bar.
class _Skeleton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        width: 96,
        height: 12,
        margin: const EdgeInsets.symmetric(vertical: Spacing.x4),
        decoration: BoxDecoration(
          color: context.colors.surfaceHighlight,
          borderRadius: BorderRadius.circular(Spacing.x4),
        ),
      ),
    ),
  );
}

/// A caption under a group of rows.
class _Caption extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Spacing.x16,
      Spacing.x4,
      Spacing.x16,
      Spacing.x8,
    ),
    child: Text(
      text,
      style: context.typography.caption.copyWith(
        color: context.colors.contentSecondary,
      ),
    ),
  );
}
