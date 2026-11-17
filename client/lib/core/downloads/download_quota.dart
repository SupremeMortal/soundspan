// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The device limit on downloads (doc 07, Storage Accounting and Quota) as
/// pure functions.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable;
import 'package:soundspan/core/downloads/download_scheduler.dart'
    show kDiskReserveBytes;
import 'package:soundspan/core/downloads/download_store.dart'
    show kUnknownItemBytes;

/// The `device_settings` key of the device limit, in bytes (doc 05).
const String downloadsQuotaKey = 'downloads.quotaBytes';

/// The largest default device limit: 20 GB.
const int kMaxDefaultDeviceLimitBytes = 20 * 1024 * 1024 * 1024;

/// The device limit written the first time it is needed: the smaller of
/// 20 GB and a quarter of [freeDiskBytes], or 20 GB when free space is
/// unknown.
int defaultDeviceLimitBytes(int? freeDiskBytes) {
  if (freeDiskBytes == null) return kMaxDefaultDeviceLimitBytes;
  return math.min(kMaxDefaultDeviceLimitBytes, freeDiskBytes ~/ 4);
}

/// How many newly queued items fit on the device, and the numbers the
/// "not enough space" sheet shows.
@immutable
final class QuotaDecision {
  /// Creates the decision.
  const new({
    required this.fitCount,
    required this.neededBytes,
    required this.availableBytes,
    required this.itemCount,
  });

  /// The number of new items, from the first in schedule order, that fit.
  final int fitCount;

  /// The bytes all the new items take, unknown sizes counted as
  /// [kUnknownItemBytes].
  final int neededBytes;

  /// The bytes still free for downloads before the new items, never
  /// negative.
  final int availableBytes;

  /// The number of new items evaluated.
  final int itemCount;

  /// Whether every new item fits.
  bool get fitsAll => fitCount == itemCount;

  @override
  bool operator ==(Object other) =>
      other is QuotaDecision &&
      other.fitCount == fitCount &&
      other.neededBytes == neededBytes &&
      other.availableBytes == availableBytes &&
      other.itemCount == itemCount;

  @override
  int get hashCode =>
      Object.hash(fitCount, neededBytes, availableBytes, itemCount);

  @override
  String toString() =>
      'QuotaDecision($fitCount/$itemCount fit, '
      'needed: $neededBytes, available: $availableBytes)';
}

/// What items waiting for space need and what is free for them, for the
/// "not enough space" sheet.
@immutable
final class QuotaShortfall {
  /// Creates the shortfall.
  const new({required this.neededBytes, required this.availableBytes});

  /// The bytes the waiting items still need.
  final int neededBytes;

  /// The bytes free for them, never negative.
  final int availableBytes;

  @override
  bool operator ==(Object other) =>
      other is QuotaShortfall &&
      other.neededBytes == neededBytes &&
      other.availableBytes == availableBytes;

  @override
  int get hashCode => Object.hash(neededBytes, availableBytes);

  @override
  String toString() =>
      'QuotaShortfall(needed: $neededBytes, available: $availableBytes)';
}

/// Decides how many of [newItemBytes], in schedule order, fit beside the
/// [committedBytes] downloads already hold or are about to hold.
///
/// Available is `deviceLimitBytes − committedBytes`, and no more than
/// `freeDiskBytes − 500 MB` when free space is known. An unknown item size
/// counts as [kUnknownItemBytes]. The cut is a prefix: once an item does
/// not fit, the items after it do not either, so the schedule order holds.
QuotaDecision evaluateQuota({
  required int committedBytes,
  required List<int?> newItemBytes,
  required int deviceLimitBytes,
  required int? freeDiskBytes,
}) {
  var available = deviceLimitBytes - committedBytes;
  if (freeDiskBytes != null) {
    available = math.min(available, freeDiskBytes - kDiskReserveBytes);
  }
  if (available < 0) available = 0;
  var needed = 0;
  var fitCount = 0;
  var cut = false;
  for (final bytes in newItemBytes) {
    needed += bytes ?? kUnknownItemBytes;
    if (!cut && needed <= available) {
      fitCount++;
    } else {
      cut = true;
    }
  }
  return QuotaDecision(
    fitCount: fitCount,
    neededBytes: needed,
    availableBytes: available,
    itemCount: newItemBytes.length,
  );
}
