// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math' as math;

import 'package:soundspan/core/profile/settings/user_settings.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan/shared/domain/track.dart';

/// The largest positive gain applied, in dB (doc 06, Loudness).
const double maxPositiveGainDb = 3;

/// Gain in dB for an item with [loudness] under [mode] (doc 06, Loudness).
///
/// [contextKind] is where the item was queued from; `auto` uses the album
/// values inside an album. Zero when nothing is measured, in modes `off`
/// and `unknown`, and for an episode, whose caller passes no [loudness].
/// A positive gain is limited to 3 dB and to the headroom below 0 dBTP of
/// the chosen true peak, and is 0 dB when that peak is unknown.
double loudnessGainDb({
  required LoudnessMode mode,
  required Loudness? loudness,
  required QueueContextKind? contextKind,
  required double targetLufs,
}) {
  if (loudness == null) return 0;
  final useAlbum = switch (mode) {
    LoudnessMode.off || LoudnessMode.unknown => null,
    LoudnessMode.track => false,
    LoudnessMode.album => true,
    LoudnessMode.auto => contextKind == QueueContextKind.album,
  };
  if (useAlbum == null) return 0;
  final albumMeasured = useAlbum && loudness.albumLoudnessLufs != null;
  final measured = albumMeasured
      ? loudness.albumLoudnessLufs
      : loudness.loudnessLufs;
  final peak = albumMeasured ? loudness.albumTruePeakDb : loudness.truePeakDb;
  if (measured == null) return 0;
  final gainDb = targetLufs - measured;
  if (gainDb <= 0) return gainDb;
  final headroomDb = peak == null || peak >= 0 ? 0.0 : -peak;
  return math.min(gainDb, math.min(maxPositiveGainDb, headroomDb));
}

/// The linear volume factor of [gainDb]: `10 ^ (gainDb / 20)`.
double gainToLinear(double gainDb) => math.pow(10, gainDb / 20).toDouble();
