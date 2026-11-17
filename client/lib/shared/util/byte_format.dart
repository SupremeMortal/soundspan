// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The one byte-size format of the app (`Settings → Storage`, doc 09).
library;

import 'package:intl/intl.dart';

const List<String> _units = ['KB', 'MB', 'GB', 'TB'];

/// Formats [bytes] in binary units (1 KB = 1,024 bytes) with one decimal,
/// such as `1.5 MB`, and with the number formatted for [locale]. Sizes
/// under 1 KB are whole bytes and a negative size reads as zero.
String formatBytes(int bytes, String locale) {
  if (bytes < 1024) {
    return '${NumberFormat.decimalPattern(locale).format(bytes < 0 ? 0 : bytes)} B';
  }
  var value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < _units.length - 1) {
    value /= 1024;
    unit++;
  }
  final number = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = 1
    ..maximumFractionDigits = 1;
  return '${number.format(value)} ${_units[unit]}';
}
