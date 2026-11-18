// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/core/downloads/download_quota.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/features/settings/ui/playback_settings_view_model.dart';
import 'package:soundspan/features/settings/ui/settings_rows.dart';
import 'package:soundspan/features/settings/ui/storage_settings_view_model.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/shared/storage/storage_actions.dart';
import 'package:soundspan/shared/storage/storage_usage.dart';
import 'package:soundspan/shared/util/byte_format.dart';

const int _bytesPerMb = 1024 * 1024;

/// Settings → Storage: the download settings, what this server's data uses
/// on the device, the server's offline figures, and clearing the cache
/// (doc 09, Settings; doc 07, Storage Accounting and Quota). Reads the
/// profile scope.
///
/// Without downloads on the platform only the device usage and the cache
/// are shown; without files (web) the device usage is left out too.
class StorageSettingsScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  /// The device-limit slider.
  static const Key deviceLimitSliderKey = ValueKey<String>(
    'storage-settings-device-limit',
  );

  /// The confirm button of the dialogs.
  static const Key confirmKey = ValueKey<String>('storage-settings-confirm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    String size(int bytes) => formatBytes(bytes, locale);
    final canDownload = ref.watch(platformCapabilitiesProvider).canDownload;
    final hasFiles = ref.watch(profileContextProvider).paths != null;
    final usage = ref.watch(storageUsageProvider).value ?? StorageUsage.none;
    final stats = canDownload
        ? ref.watch(serverStorageStatsProvider).value
        : null;

    return ListView(
      padding: const EdgeInsets.only(bottom: Spacing.x16),
      children: [
        if (canDownload) ..._downloads(context, ref, l10n, usage, size),
        if (hasFiles) ...[
          SettingsHeading(l10n.settingsStorageThisDevice),
          _UsageBar(usage),
          _SizeRow(
            title: l10n.settingsStorageUsageDownloads,
            subtitle: l10n.settingsStorageUsageDownloadCount(
              usage.downloadCount,
            ),
            value: size(usage.downloadsBytes),
          ),
          _SizeRow(
            title: l10n.settingsStorageUsageImages,
            value: size(usage.imageCacheBytes),
          ),
          _SizeRow(
            title: l10n.settingsStorageUsageDatabase,
            value: size(usage.databaseBytes),
          ),
          if (usage.freeDiskBytes case final free?)
            _SizeRow(title: l10n.settingsStorageUsageFree, value: size(free)),
        ],
        if (stats != null) ..._server(l10n, stats, size),
        SettingsHeading(l10n.settingsStorageCache),
        ListTile(
          title: Text(l10n.settingsStorageClearCache),
          subtitle: Text(l10n.settingsStorageClearCacheCaption),
          minTileHeight: Sizes.touchTarget,
          onTap: () => unawaited(_clearCache(context, ref)),
        ),
      ],
    );
  }

  List<Widget> _downloads(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    StorageUsage usage,
    String Function(int) size,
  ) {
    final settings = ref.watch(storageDeviceSettingsProvider);
    final writer = ref.watch(storageSettingsWriterProvider);
    final free = usage.freeDiskBytes;
    return [
      SettingsHeading(l10n.settingsStorageDownloads),
      SettingsChoiceRow<StreamQualityOption>(
        title: l10n.settingsStorageDownloadQuality,
        value: settings.downloadQuality,
        options: [
          for (final option in StreamQualityOption.values)
            SettingsOption(
              option,
              option.label(l10n),
              caption: option == StreamQualityOption.serverDefault
                  ? l10n.settingsPlaybackQualityServerDefaultCaption
                  : null,
            ),
        ],
        onSelected: writer.setDownloadQuality,
      ),
      SettingsCaption(l10n.settingsStorageDownloadQualityCaption),
      SwitchListTile(
        title: Text(l10n.settingsStorageWifiOnly),
        value: settings.wifiOnly,
        onChanged: (value) => unawaited(writer.setWifiOnly(wifiOnly: value)),
      ),
      _DeviceLimit(
        steps: offeredDeviceLimitSteps(
          free == null ? null : free + usage.downloadsBytes,
        ),
        limit: settings.deviceLimitBytes ?? defaultDeviceLimitBytes(free),
        usedBytes: usage.downloadsBytes,
        size: size,
        onChanged: writer.setDeviceLimit,
      ),
      ListTile(
        title: Text(
          l10n.settingsStorageRemoveAll,
          style: TextStyle(color: context.colors.danger),
        ),
        minTileHeight: Sizes.touchTarget,
        onTap: () => unawaited(_removeAll(context, ref, usage, size)),
      ),
    ];
  }

  static List<Widget> _server(
    AppLocalizations l10n,
    OfflineStats stats,
    String Function(int) size,
  ) {
    int bytes(double mb) => (mb * _bytesPerMb).round();
    return [
      SettingsHeading(l10n.settingsStorageServer),
      ListTile(
        title: Text(
          l10n.settingsStorageServerUsed(
            size(bytes(stats.usedMb)),
            size(bytes(stats.maxMb)),
          ),
        ),
        subtitle: Text(
          l10n.settingsStorageServerDevice(
            stats.deviceTrackCount,
            size(bytes(stats.deviceUsedMb)),
          ),
        ),
        minTileHeight: Sizes.touchTarget,
      ),
      SettingsCaption(l10n.settingsStorageServerCaption),
    ];
  }

  static Future<void> _removeAll(
    BuildContext context,
    WidgetRef ref,
    StorageUsage usage,
    String Function(int) size,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      context,
      title: l10n.settingsStorageRemoveAllTitle,
      body: l10n.settingsStorageRemoveAllBody(size(usage.downloadsBytes)),
      confirm: l10n.settingsStorageRemoveAllConfirm,
    );
    if (!confirmed) return;
    await ref.read(storageActionsProvider).removeAllDownloads();
    ref.invalidate(storageUsageProvider);
  }

  static Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      context,
      title: l10n.settingsStorageClearCacheTitle,
      body: l10n.settingsStorageClearCacheBody,
      confirm: l10n.settingsStorageClearCacheConfirm,
    );
    if (!confirmed) return;
    await ref.read(storageActionsProvider).clearCache();
    ref.invalidate(storageUsageProvider);
  }

  static Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirm,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.settingsStorageCancel),
              ),
              FilledButton(
                key: confirmKey,
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.danger,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirm),
              ),
            ],
          );
        },
      ) ??
      false;
}

/// The device-limit row: the usage against the limit and a slider over
/// [steps] that stores the chosen step when the drag ends.
class _DeviceLimit extends StatefulWidget {
  const new({
    required this.steps,
    required this.limit,
    required this.usedBytes,
    required this.size,
    required this.onChanged,
  });

  final List<int> steps;
  final int limit;
  final int usedBytes;
  final String Function(int) size;
  final Future<void> Function(int bytes) onChanged;

  @override
  State<_DeviceLimit> createState() => _DeviceLimitState();
}

class _DeviceLimitState extends State<_DeviceLimit> {
  /// The step under the thumb while dragging, else null.
  int? _dragging;

  String _label(AppLocalizations l10n, int step) => step == kNoDeviceLimitBytes
      ? l10n.settingsStorageNoLimit
      : widget.size(step);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = widget.steps;
    final stored = deviceLimitStepIndex(steps, widget.limit);
    final index = _dragging ?? stored;
    final step = steps[index];
    final used = widget.size(widget.usedBytes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: Text(l10n.settingsStorageDeviceLimit),
          subtitle: Text(
            step == kNoDeviceLimitBytes
                ? l10n.settingsStorageDeviceLimitUsageUnlimited(used)
                : l10n.settingsStorageDeviceLimitUsage(
                    used,
                    _label(l10n, step),
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.x8),
          child: Slider(
            key: StorageSettingsScreen.deviceLimitSliderKey,
            value: index.toDouble(),
            max: (steps.length - 1).toDouble(),
            divisions: steps.length - 1,
            label: _label(l10n, step),
            semanticFormatterCallback: (value) =>
                _label(l10n, steps[value.round()]),
            onChanged: (value) => setState(() => _dragging = value.round()),
            onChangeEnd: (value) {
              final chosen = steps[value.round()];
              setState(() => _dragging = null);
              if (value.round() != stored) unawaited(widget.onChanged(chosen));
            },
          ),
        ),
      ],
    );
  }
}

/// A usage row: [title] and an optional [subtitle] with [value] at the end.
class _SizeRow extends StatelessWidget {
  const new({required this.title, required this.value, this.subtitle});

  final String title;
  final String? subtitle;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: Text(
      value,
      style: TextStyle(color: context.colors.contentSecondary),
    ),
  );
}

/// The device usage as one bar: downloads, images and database against
/// what they use plus free space. The rows below carry the figures, so the
/// bar is left out of semantics.
class _UsageBar extends StatelessWidget {
  const new(this.usage);

  final StorageUsage usage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final parts = [
      (usage.downloadsBytes, colors.brand),
      (usage.imageCacheBytes, colors.accent),
      (usage.databaseBytes, colors.contentSecondary),
    ];
    final whole = usage.totalBytes + (usage.freeDiskBytes ?? 0);
    int flex(int bytes) => whole == 0 ? 0 : (bytes * 1000 / whole).ceil();
    final rest = 1000 - parts.fold<int>(0, (sum, part) => sum + flex(part.$1));
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.x16,
          Spacing.x4,
          Spacing.x16,
          Spacing.x8,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Spacing.x4),
          child: SizedBox(
            height: Spacing.x8,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (bytes, color) in parts)
                  if (flex(bytes) > 0)
                    Expanded(
                      flex: flex(bytes),
                      child: ColoredBox(color: color),
                    ),
                if (rest > 0)
                  Expanded(
                    flex: rest,
                    child: ColoredBox(color: colors.surfaceHighlight),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
