// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Locale;
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/core/downloads/download_notification_policy.dart';

const int _mb = 1024 * 1024;

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  final texts = DownloadNotificationTexts(
    title: l10n.downloadsNotificationTitle,
    finished: l10n.downloadsNotificationFinished,
  );

  DownloadNotificationPlan plan(
    DownloadBatch batch, {
    bool notificationsGranted = true,
  }) =>
      planFor(batch, texts: texts, notificationsGranted: notificationsGranted);

  test('a batch of 49 MB remaining runs in the background', () {
    final result = plan(
      const DownloadBatch(
        itemCount: 1,
        completedCount: 0,
        receivedBytes: 0,
        estimatedBytes: 49 * _mb,
      ),
    );

    expect(result.runInForeground, isFalse);
  });

  test('a batch of 51 MB remaining runs in the foreground', () {
    final result = plan(
      const DownloadBatch(
        itemCount: 2,
        completedCount: 0,
        receivedBytes: 0,
        estimatedBytes: 51 * _mb,
      ),
    );

    expect(result.runInForeground, isTrue);
  });

  test('received bytes count against the remaining size', () {
    final result = plan(
      const DownloadBatch(
        itemCount: 2,
        completedCount: 0,
        receivedBytes: 10 * _mb,
        estimatedBytes: 55 * _mb,
      ),
    );

    expect(result.runInForeground, isFalse);
  });

  test('items of unknown size count 8 MB each: seven of them run in the '
      'foreground', () {
    final batch = DownloadBatch.fromItems([
      for (var i = 0; i < 7; i++) const DownloadBatchItem(expectedBytes: null),
    ]);

    expect(batch.estimatedBytes, 7 * kUnknownBatchItemBytes);
    expect(plan(batch).runInForeground, isTrue);
    expect(
      plan(
        DownloadBatch.fromItems([
          for (var i = 0; i < 6; i++)
            const DownloadBatchItem(expectedBytes: null),
        ]),
      ).runInForeground,
      isFalse,
    );
  });

  test('completed items count towards the progress, not the remaining '
      'size', () {
    final batch = DownloadBatch.fromItems(const [
      DownloadBatchItem(expectedBytes: 40 * _mb, completed: true),
      DownloadBatchItem(expectedBytes: 20 * _mb, receivedBytes: 5 * _mb),
      DownloadBatchItem(expectedBytes: 20 * _mb),
    ]);

    expect(batch.itemCount, 3);
    expect(batch.completedCount, 1);
    final result = plan(batch);
    expect(result.runInForeground, isFalse);
    expect(result.progress, closeTo(1 / 3, 1e-9));
  });

  test('the title is a plural of the item count and names no item', () {
    expect(
      plan(
        const DownloadBatch(
          itemCount: 1,
          completedCount: 0,
          receivedBytes: 0,
          estimatedBytes: 0,
        ),
      ).title,
      'Downloading 1 item',
    );
    final many = plan(
      const DownloadBatch(
        itemCount: 12,
        completedCount: 3,
        receivedBytes: 0,
        estimatedBytes: 0,
      ),
    );
    expect(many.title, 'Downloading 12 items');
    expect(many.finishedText, 'Downloads finished');
    expect(many.progress, 0.25);
  });

  test('the channel is the low-importance Downloads channel', () {
    final result = plan(
      const DownloadBatch(
        itemCount: 1,
        completedCount: 0,
        receivedBytes: 0,
        estimatedBytes: 0,
      ),
    );

    expect(result.channelName, 'Downloads');
    expect(result.channelImportance, DownloadChannelImportance.low);
  });

  test('the plan is valid with notifications denied: the same foreground '
      'decision and content', () {
    const batch = DownloadBatch(
      itemCount: 3,
      completedCount: 1,
      receivedBytes: 0,
      estimatedBytes: 80 * _mb,
    );

    final granted = plan(batch);
    final denied = plan(batch, notificationsGranted: false);

    expect(denied.runInForeground, isTrue);
    expect(denied.title, granted.title);
    expect(denied.progress, granted.progress);
    expect(denied.notificationsGranted, isFalse);
    expect(granted.notificationsGranted, isTrue);
  });

  test('an empty batch has no progress and runs in the background', () {
    final result = plan(DownloadBatch.fromItems(const []));

    expect(result.progress, 0);
    expect(result.runInForeground, isFalse);
  });
}
