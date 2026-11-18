// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/playback_controller.dart';

import '../../logging/recording_sink.dart';
import '../queue/queue_test_items.dart';
import 'controller_harness.dart';

void main() {
  tearDown(AppLogging.reset);

  test('a playback step still running after its time limit is logged with '
      'its command', () {
    fakeAsync((async) {
      final sink = RecordingSink();
      AppLogging.configure(sinks: [sink], releaseMode: true);
      final h = ControllerHarness();
      final gate = Completer<void>();
      h.resolver.gates['a'] = gate;
      unawaited(h.controller.playItems(trackItems(['a', 'b'])));

      List<LogEntry> slow() => sink.entries
          .where((e) => e.message == 'A playback step is still running')
          .toList();

      async.elapse(
        PlaybackController.slowStepWarning - const Duration(seconds: 1),
      );
      expect(slow(), isEmpty);

      async.elapse(const Duration(seconds: 2));
      expect(slow().single.fields['step'], 'PlayItemsCommand');
      expect(slow().single.level, 'warning');

      gate.complete();
      async
        ..flushMicrotasks()
        ..elapse(PlaybackController.slowStepWarning * 2);
      expect(slow(), hasLength(1));
    });
  });
}
