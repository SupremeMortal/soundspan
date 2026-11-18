// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The download-notification seam (doc 02, Platform Seams; doc 07,
/// Transfers): applies a [DownloadNotificationPlan] to the transfers of a
/// profile.
///
/// On Android and iOS it configures `background_downloader`'s group
/// notification and Android foreground mode; desktop shows no download
/// notification and web has no downloads, so both do nothing.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/downloads/download_notification_policy.dart';
import 'package:soundspan/platform/download_notifier/download_notifier_web.dart'
    if (dart.library.io) 'package:soundspan/platform/download_notifier/download_notifier_io.dart';

export 'download_notifier_web.dart'
    if (dart.library.io) 'download_notifier_io.dart'
    show createDownloadNotifier;

/// Shows the progress of a profile's downloads and decides whether they run
/// as a foreground service.
abstract interface class DownloadNotifier {
  /// Applies [plan] to the transfers of profile [profileId], the group
  /// `p:<profileId>`; it holds for transfers that start afterwards.
  Future<void> apply(String profileId, DownloadNotificationPlan plan);
}

/// A [DownloadNotifier] that shows nothing: desktop and web.
final class NoopDownloadNotifier implements DownloadNotifier {
  /// Creates the no-op notifier.
  const new();

  @override
  Future<void> apply(String profileId, DownloadNotificationPlan plan) async {}
}

/// The root-scope [DownloadNotifier] of the platform; tests override it.
final Provider<DownloadNotifier> downloadNotifierProvider =
    Provider<DownloadNotifier>((ref) => createDownloadNotifier());
