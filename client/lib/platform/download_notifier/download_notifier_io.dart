// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:soundspan/core/downloads/download_notification_policy.dart';
import 'package:soundspan/platform/download_notifier/download_notifier.dart';
import 'package:soundspan/platform/downloader/downloader.dart';

/// The [DownloadNotifier] of the native app: the plugin's notifications on
/// Android and iOS, nothing on desktop.
DownloadNotifier createDownloadNotifier() =>
    Platform.isAndroid || Platform.isIOS
    ? const BackgroundDownloadNotifier()
    : const NoopDownloadNotifier();

/// Applies a plan through `background_downloader` (doc 07, Transfers).
///
/// The plugin posts its notifications on its own channel, named "Downloads"
/// with low importance through its `bg_downloader_notification_channel_name`
/// string, and draws the app's monochrome `ic_stat_soundspan` through the
/// drawable aliases in `res/values/download_notification_icons.xml`. The
/// whole group shares one notification whose progress is the finished tasks
/// over all tasks.
final class BackgroundDownloadNotifier implements DownloadNotifier {
  /// Creates the notifier over the plugin's singleton.
  const new();

  @override
  Future<void> apply(String profileId, DownloadNotificationPlan plan) async {
    final group = downloaderGroup(profileId);
    final downloader = FileDownloader();
    await downloader.configure(
      androidConfig: [(Config.runInForeground, plan.runInForeground)],
    );
    downloader.configureNotificationForGroup(
      group,
      running: TaskNotification(plan.title, ''),
      complete: TaskNotification(plan.finishedText, ''),
      progressBar: true,
      groupNotificationId: group,
    );
  }
}
