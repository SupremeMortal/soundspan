// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/downloads/download_notification_policy.dart';
import 'package:soundspan/platform/download_notifier/download_notifier.dart';

/// A [DownloadNotifier] that records every plan it applies (doc 11, Test
/// Doubles).
final class FakeDownloadNotifier implements DownloadNotifier {
  /// Every applied plan with its profile id, oldest first.
  final List<({String profileId, DownloadNotificationPlan plan})> applied = [];

  /// The last plan applied, or null.
  DownloadNotificationPlan? get last =>
      applied.isEmpty ? null : applied.last.plan;

  @override
  Future<void> apply(String profileId, DownloadNotificationPlan plan) async {
    applied.add((profileId: profileId, plan: plan));
  }
}
