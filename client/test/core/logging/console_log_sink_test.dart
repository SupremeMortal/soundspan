// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/logging/console_log_sink.dart';

import 'recording_sink.dart';

void main() {
  test('writes entries with and without errors without throwing', () async {
    final sink = ConsoleLogSink();
    expect(() => sink.write(entryWith(fields: {'bytes': 3})), returnsNormally);
    expect(
      () => sink.write(entryWith(error: 'e', stackTrace: '#0 main')),
      returnsNormally,
    );
    await sink.close();
  });
}
