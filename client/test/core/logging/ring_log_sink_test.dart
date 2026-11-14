// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/logging/ring_log_sink.dart';

import 'recording_sink.dart';

void main() {
  test('keeps 500 entries', () {
    final ring = RingLogSink();
    for (var i = 0; i < 500; i++) {
      ring.write(entryWith(message: '$i'));
    }
    expect(ring.entries, hasLength(500));
    expect(ring.entries.first.message, '0');
    expect(ring.entries.last.message, '499');
  });

  test('the 501st entry evicts the oldest', () {
    final ring = RingLogSink();
    for (var i = 0; i < 501; i++) {
      ring.write(entryWith(message: '$i'));
    }
    expect(ring.entries, hasLength(500));
    expect(ring.entries.first.message, '1');
    expect(ring.entries.last.message, '500');
  });

  test('close keeps the entries readable', () async {
    final ring = RingLogSink()..write(entryWith());
    await ring.close();
    expect(ring.entries, hasLength(1));
  });
}
