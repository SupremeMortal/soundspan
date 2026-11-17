// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Keeps the operating system's downloads notification in step with one
/// profile's queue (doc 07, Transfers; doc 10, Android).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/downloads/download_notification_policy.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/device_info/device_info.dart';
import 'package:soundspan/platform/download_notifier/download_notifier.dart';
import 'package:soundspan/platform/notifications/local_notifications.dart';

/// The `device_settings` key that records the answer to the notification
/// permission asked when a download first started: JSON `true` when
/// granted, `false` when denied. Once set, downloads never ask again.
const String downloadsNotificationsAskedKey = 'downloads.notificationsAsked';

/// The first Android API level with a runtime notification permission
/// (Android 13).
const int _notificationPermissionSdk = 33;

/// The texts of the downloads notification in English; the app overrides
/// them with the user's language.
final Provider<DownloadNotificationTexts> downloadNotificationTextsProvider =
    Provider<DownloadNotificationTexts>(
      (ref) => DownloadNotificationTexts(
        title: (count) =>
            count == 1 ? 'Downloading 1 item' : 'Downloading $count items',
        finished: 'Downloads finished',
      ),
    );

/// Tracks the batch of one profile's downloads and applies its
/// [DownloadNotificationPlan] through the [DownloadNotifier].
///
/// A batch begins when an item becomes active (queued, running or
/// verifying) while none was, and ends when none is left. Items that
/// leave the active set during a batch count as completed.
class DownloadBatchNotices {
  /// Creates the notices of profile `profileId`; `texts` is read each
  /// time a plan is made, so a change of language applies to the next one.
  new({
    required this._profileId,
    required this._notifier,
    required this._settings,
    required this._notifications,
    required this._androidSdkVersion,
    required this._texts,
  });

  static final AppLogger _log = AppLogger.scope('Downloads');

  final String _profileId;
  final DownloadNotifier _notifier;
  final DeviceSettingsDao _settings;
  final LocalNotifications _notifications;
  final AndroidSdkVersion _androidSdkVersion;
  final DownloadNotificationTexts Function() _texts;

  final Set<String> _batch = {};
  Future<void>? _asking;
  ({bool foreground, String title, double progress})? _applied;

  /// Asks for the notification permission the first time a download starts
  /// on Android 13 or later, unless the answer is already recorded under
  /// [downloadsNotificationsAskedKey]. Downloads never wait for it.
  Future<void> downloadStarting() => _asking ??= _ask();

  Future<void> _ask() async {
    try {
      final sdk = await _androidSdkVersion();
      if (sdk == null || sdk < _notificationPermissionSdk) return;
      if (await _settings.read(downloadsNotificationsAskedKey) is bool) return;
      // Recorded before asking, so a dismissed dialog is not asked again.
      await _settings.write(downloadsNotificationsAskedKey, false);
      final granted = await _notifications.requestPermission();
      await _settings.write(downloadsNotificationsAskedKey, granted);
    } on Object catch (error, stackTrace) {
      _log.warning(
        'The notification permission was not requested',
        const {},
        error,
        stackTrace,
      );
    }
  }

  /// Applies the plan of the batch whose items still to finish are
  /// [active]. Nothing is applied while the plan is unchanged.
  Future<void> update(Iterable<DownloadItem> active) async {
    final rows = active.toList();
    final keys = {for (final row in rows) row.itemKey};
    if (keys.isEmpty) {
      _batch.clear();
      _applied = null;
      return;
    }
    _batch.addAll(keys);
    final batch = DownloadBatch.fromItems([
      for (final row in rows)
        DownloadBatchItem(
          expectedBytes: row.expectedBytes,
          receivedBytes: row.receivedBytes,
        ),
      for (final _ in _batch.difference(keys))
        const DownloadBatchItem(expectedBytes: null, completed: true),
    ]);
    final stored = await _settings.read(downloadsNotificationsAskedKey);
    final plan = planFor(
      batch,
      texts: _texts(),
      notificationsGranted: stored is! bool || stored,
    );
    final applied = (
      foreground: plan.runInForeground,
      title: plan.title,
      progress: plan.progress,
    );
    if (applied == _applied) return;
    try {
      await _notifier.apply(_profileId, plan);
      _applied = applied;
    } on Object catch (error, stackTrace) {
      _log.warning(
        'The downloads notification was not updated',
        const {},
        error,
        stackTrace,
      );
    }
  }
}
