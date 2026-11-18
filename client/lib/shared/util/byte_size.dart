// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// A short size for people to read, in decimal units.
library;

const List<String> _units = ['B', 'KB', 'MB', 'GB', 'TB'];

/// Formats [bytes] in decimal units: `512 B`, `1.5 MB`, `12 GB`. Sizes
/// below 10 of a unit keep one decimal; negative sizes read `0 B`.
String formatByteSize(int bytes) {
  var value = bytes < 0 ? 0.0 : bytes.toDouble();
  var unit = 0;
  while (value >= 1000 && unit < _units.length - 1) {
    value /= 1000;
    unit++;
  }
  final text = unit == 0 || value >= 10
      ? value.round().toString()
      : value.toStringAsFixed(1);
  return '$text ${_units[unit]}';
}
