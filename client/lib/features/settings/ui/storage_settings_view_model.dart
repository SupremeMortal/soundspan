// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_quota.dart';
import 'package:soundspan/core/downloads/download_scheduler.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/downloads/offline_repository.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/features/settings/ui/playback_settings_view_model.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';

const int _gb = 1024 * 1024 * 1024;

/// The device limit stored for "No limit": larger than any disk.
const int kNoDeviceLimitBytes = 1 << 50;

/// The steps of the device-limit slider, in bytes, smallest first: 1, 2, 5,
/// 10, 20, 50, 100 and 200 GB, then [kNoDeviceLimitBytes].
const List<int> deviceLimitSteps = [
  1 * _gb,
  2 * _gb,
  5 * _gb,
  10 * _gb,
  20 * _gb,
  50 * _gb,
  100 * _gb,
  200 * _gb,
  kNoDeviceLimitBytes,
];

/// The steps of [deviceLimitSteps] the slider offers: those up to [cap]
/// (free disk space plus what downloads use), and always the smallest and
/// "No limit". Without a [cap] every step is offered.
List<int> offeredDeviceLimitSteps(int? cap) => [
  for (final (index, step) in deviceLimitSteps.indexed)
    if (cap == null || index == 0 || step == kNoDeviceLimitBytes || step <= cap)
      step,
];

/// The position in [steps] that shows [limit]: the largest step not above
/// it, or the first.
int deviceLimitStepIndex(List<int> steps, int limit) {
  var index = 0;
  for (final (i, step) in steps.indexed) {
    if (step <= limit) index = i;
  }
  return index;
}

/// The `Settings → Storage` values stored on this device for the active
/// profile.
@immutable
final class StorageDeviceSettings {
  /// Creates the settings.
  const new({
    required this.downloadQuality,
    required this.wifiOnly,
    required this.deviceLimitBytes,
  });

  /// The quality of new downloads (`quality.download`).
  final StreamQualityOption downloadQuality;

  /// Whether downloads run on Wi-Fi only (`downloads.wifiOnly`, with the
  /// platform default while unset).
  final bool wifiOnly;

  /// The device limit (`downloads.quotaBytes`), or null while unset.
  final int? deviceLimitBytes;
}

/// The storage settings stored on this device for the active profile; a
/// value not read yet shows as its default.
final Provider<StorageDeviceSettings> storageDeviceSettingsProvider =
    Provider.autoDispose<StorageDeviceSettings>((ref) {
      Object? read(String key) => ref.watch(deviceSettingProvider(key)).value;
      final limit = read(downloadsQuotaKey);
      return StorageDeviceSettings(
        downloadQuality: StreamQualityOption.fromStored(
          read(downloadQualityKey),
        ),
        wifiOnly: wifiOnlyFromStored(
          read(downloadsWifiOnlyKey),
          mobileData: ref.watch(platformCapabilitiesProvider).hasMobileData,
        ),
        deviceLimitBytes: limit is num ? limit.toInt() : null,
      );
    }, dependencies: [deviceSettingProvider]);

/// Writes the storage settings.
final class StorageSettingsWriter {
  /// Creates the writer over a provider [_ref].
  new(this._ref);

  final Ref _ref;

  /// Stores the quality of new downloads.
  Future<void> setDownloadQuality(StreamQualityOption option) => _ref
      .read(deviceSettingsDaoProvider)
      .write(downloadQualityKey, option.stored);

  /// Stores whether downloads run on Wi-Fi only; the scheduler follows it.
  Future<void> setWifiOnly({required bool wifiOnly}) => _ref
      .read(deviceSettingsDaoProvider)
      .write(downloadsWifiOnlyKey, wifiOnly);

  /// Stores the device limit and applies it again, so items it now fits
  /// run.
  Future<void> setDeviceLimit(int bytes) async {
    await _ref.read(deviceSettingsDaoProvider).write(downloadsQuotaKey, bytes);
    await _ref.read(downloadControllerProvider).recheckSpace();
  }
}

/// The [StorageSettingsWriter] of the active profile.
final Provider<StorageSettingsWriter> storageSettingsWriterProvider =
    Provider.autoDispose<StorageSettingsWriter>(
      StorageSettingsWriter.new,
      dependencies: [deviceSettingsDaoProvider, downloadControllerProvider],
    );

/// The server's offline storage figures for this device, or null while the
/// server is not reachable. A failed request is an error the screen hides.
final FutureProvider<OfflineStats?> serverStorageStatsProvider =
    FutureProvider.autoDispose<OfflineStats?>((ref) async {
      final online =
          (ref.watch(reachabilityStateProvider).value ??
              ref.watch(reachabilityProvider).current) ==
          Reachability.online;
      if (!online) return null;
      return await ref
          .watch(offlineRepositoryProvider)
          .stats(deviceId: ref.watch(profileContextProvider).profile.deviceId);
    }, dependencies: [offlineRepositoryProvider, profileContextProvider]);
