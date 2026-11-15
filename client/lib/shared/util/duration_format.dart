// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The fixed track-time format of doc 09, Localization: `m:ss` under an hour
/// and `h:mm:ss` from an hour, in every locale.
library;

/// Formats [value] as `m:ss`, or `h:mm:ss` from one hour.
///
/// Fractions of a second are dropped and negative values read `0:00`.
String formatTrackDuration(Duration value) {
  final total = value.isNegative ? 0 : value.inSeconds;
  final hours = total ~/ 3600;
  final minutes = total % 3600 ~/ 60;
  final seconds = (total % 60).toString().padLeft(2, '0');
  if (hours == 0) return '$minutes:$seconds';
  return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
}
