// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Where a Listen Together group is expected to be, and what to do about a
/// difference (doc 08, Applying State and Drift Correction).
///
/// This file imports nothing, so the contract suite can use it by path.
library;

/// The position a group's playback is expected at when the server clock
/// reads [serverNow]: [positionMs] plus the server time elapsed since
/// [serverTime] while [isPlaying], else [positionMs]; clamped to zero and,
/// when known, to [durationMs].
int expectedPositionMs({
  required bool isPlaying,
  required int positionMs,
  required int serverTime,
  required int serverNow,
  int? durationMs,
}) {
  final raw = isPlaying ? positionMs + (serverNow - serverTime) : positionMs;
  final atLeastZero = raw < 0 ? 0 : raw;
  if (durationMs != null && durationMs > 0 && atLeastZero > durationMs) {
    return durationMs;
  }
  return atLeastZero;
}

/// What a measured drift asks for.
enum DriftCorrection {
  /// Below [driftToleranceMs]: nothing.
  none,

  /// Below [driftImmediateMs]: seek to the expected position, at most once
  /// per [midBandCorrectionInterval].
  throttledSeek,

  /// [driftImmediateMs] or more: seek to the expected position at once.
  immediateSeek,
}

/// A drift below this many milliseconds is left alone.
const int driftToleranceMs = 250;

/// A drift of this many milliseconds or more is corrected at once.
const int driftImmediateMs = 1500;

/// The shortest time between two corrections of the middle band.
const Duration midBandCorrectionInterval = Duration(seconds: 10);

/// The correction for [driftMs], the engine position minus the expected
/// position.
DriftCorrection driftCorrectionFor(int driftMs) {
  final size = driftMs.abs();
  if (size < driftToleranceMs) return DriftCorrection.none;
  if (size < driftImmediateMs) return DriftCorrection.throttledSeek;
  return DriftCorrection.immediateSeek;
}
