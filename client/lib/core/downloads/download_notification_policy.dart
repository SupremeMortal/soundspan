// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// What the operating system shows while downloads run, and whether they run
/// as a foreground service (doc 07, Transfers; doc 10, Android).
///
/// Pure: the `DownloadNotifier` platform seam
/// seam applies the plan through `background_downloader`.
library;

import 'package:flutter/foundation.dart' show immutable;

/// The estimated remaining bytes above which a batch runs as a foreground
/// service on Android: 50 MB.
const int kForegroundThresholdBytes = 50 * 1024 * 1024;

/// The size counted for an item of a batch whose size is not known: 8 MB.
const int kUnknownBatchItemBytes = 8 * 1024 * 1024;

/// The name of the Android notification channel of downloads.
const String kDownloadsChannelName = 'Downloads';

/// How loudly a notification channel interrupts.
enum DownloadChannelImportance {
  /// No sound and no heads-up: progress only.
  low,
}

/// One item of a [DownloadBatch].
@immutable
final class DownloadBatchItem {
  /// Creates the item; [expectedBytes] is null when the size is not known.
  const new({
    required this.expectedBytes,
    this.receivedBytes = 0,
    this.completed = false,
  });

  /// The item's size, when known.
  final int? expectedBytes;

  /// Bytes already on disk.
  final int receivedBytes;

  /// Whether the item finished.
  final bool completed;
}

/// The downloads of one profile that are queued, running or finished since
/// the batch began.
@immutable
final class DownloadBatch {
  /// Creates a batch from its totals.
  const new({
    required this.itemCount,
    required this.completedCount,
    required this.receivedBytes,
    required this.estimatedBytes,
  });

  /// Sums [items]: an item of unknown size counts [kUnknownBatchItemBytes];
  /// a completed item counts towards [completedCount] only.
  factory fromItems(Iterable<DownloadBatchItem> items) {
    var count = 0;
    var completed = 0;
    var received = 0;
    var estimated = 0;
    for (final item in items) {
      count++;
      if (item.completed) {
        completed++;
        continue;
      }
      received += item.receivedBytes;
      estimated += item.expectedBytes ?? kUnknownBatchItemBytes;
    }
    return DownloadBatch(
      itemCount: count,
      completedCount: completed,
      receivedBytes: received,
      estimatedBytes: estimated,
    );
  }

  /// Every item of the batch, completed ones included.
  final int itemCount;

  /// The items that finished.
  final int completedCount;

  /// Bytes received by the items still to finish.
  final int receivedBytes;

  /// The estimated size of the items still to finish.
  final int estimatedBytes;

  /// The bytes still to transfer, never negative.
  int get remainingBytes {
    final remaining = estimatedBytes - receivedBytes;
    return remaining < 0 ? 0 : remaining;
  }
}

/// The localized texts of the downloads notification.
@immutable
final class DownloadNotificationTexts {
  /// Creates the texts.
  const new({required this.title, required this.finished});

  /// The title for a batch of `count` items.
  final String Function(int count) title;

  /// The text shown once every item has finished.
  final String finished;
}

/// What to show for a batch, and how to run it.
@immutable
final class DownloadNotificationPlan {
  /// Creates the plan.
  const new({
    required this.runInForeground,
    required this.title,
    required this.progress,
    required this.finishedText,
    required this.notificationsGranted,
  });

  /// Whether the batch runs as an Android foreground service.
  final bool runInForeground;

  /// "Downloading N items"; never a track or source name.
  final String title;

  /// Completed items over all items, from 0 to 1.
  final double progress;

  /// "Downloads finished".
  final String finishedText;

  /// Whether the user allows notifications. The plan is the same either
  /// way: without the permission the system does not show it, and the
  /// transfers still run.
  final bool notificationsGranted;

  /// The notification channel's name.
  String get channelName => kDownloadsChannelName;

  /// The notification channel's importance.
  DownloadChannelImportance get channelImportance =>
      DownloadChannelImportance.low;
}

/// The notification and foreground plan of [batch] (doc 07, Transfers):
/// foreground when more than [kForegroundThresholdBytes] remain.
DownloadNotificationPlan planFor(
  DownloadBatch batch, {
  required DownloadNotificationTexts texts,
  required bool notificationsGranted,
}) => DownloadNotificationPlan(
  runInForeground: batch.remainingBytes > kForegroundThresholdBytes,
  title: texts.title(batch.itemCount),
  progress: batch.itemCount == 0 ? 0 : batch.completedCount / batch.itemCount,
  finishedText: texts.finished,
  notificationsGranted: notificationsGranted,
);
