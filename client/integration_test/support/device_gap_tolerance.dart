// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The gap tolerance of the native device engine harness (doc 06).
library;

/// The tolerance every device holds unless a target is allowed more.
const Duration baseDeviceGapTolerance = Duration(milliseconds: 20);

/// The largest tolerance doc 06 allows on any target.
const Duration maxDeviceGapTolerance = Duration(milliseconds: 100);

/// The tolerance, in milliseconds, a CI job passes with
/// `--dart-define=CONFORMANCE_GAP_TOLERANCE_MS=<ms>`, or 0 when none is set.
///
/// The `engine-conformance-ios` job sets 100 for the iOS simulator: the app
/// launched on a simulator by `flutter test -d <udid>` cannot tell from its
/// environment that it is not on hardware.
const int definedDeviceGapToleranceMs = int.fromEnvironment(
  'CONFORMANCE_GAP_TOLERANCE_MS',
);

/// The gap tolerance on a native device: [maxDeviceGapTolerance] on macOS,
/// whose transition between two loaded items is not reliably gapless (Spike
/// S1 finding); otherwise the tolerance a CI job defined in [definedMs],
/// kept between [baseDeviceGapTolerance] and [maxDeviceGapTolerance]; and
/// [baseDeviceGapTolerance] when none is defined.
Duration deviceGapTolerance({required bool isMacOS, required int definedMs}) {
  if (isMacOS) return maxDeviceGapTolerance;
  if (definedMs <= 0) return baseDeviceGapTolerance;
  return Duration(
    milliseconds: definedMs.clamp(
      baseDeviceGapTolerance.inMilliseconds,
      maxDeviceGapTolerance.inMilliseconds,
    ),
  );
}
