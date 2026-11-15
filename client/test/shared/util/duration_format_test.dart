// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/shared/util/duration_format.dart';

void main() {
  test('formats minutes and seconds as m:ss and hours as h:mm:ss', () {
    expect(formatTrackDuration(Duration.zero), '0:00');
    expect(formatTrackDuration(const Duration(seconds: 9)), '0:09');
    expect(
      formatTrackDuration(const Duration(minutes: 3, seconds: 41)),
      '3:41',
    );
    expect(
      formatTrackDuration(const Duration(minutes: 59, seconds: 59)),
      '59:59',
    );
    expect(formatTrackDuration(const Duration(hours: 1)), '1:00:00');
    expect(
      formatTrackDuration(const Duration(hours: 10, minutes: 5, seconds: 9)),
      '10:05:09',
    );
  });

  test('drops fractions of a second and clamps negatives to zero', () {
    expect(
      formatTrackDuration(const Duration(seconds: 61, milliseconds: 999)),
      '1:01',
    );
    expect(formatTrackDuration(const Duration(seconds: -5)), '0:00');
  });
}
