// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/media_kit_mapping.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';

void main() {
  group('classifyMpvError', () {
    const failedToOpen = 'Failed to open http://127.0.0.1:8080/stream.';

    final table = <(String, String, int?, EngineErrorKind)>[
      ('404', failedToOpen, 404, EngineErrorKind.notFound),
      ('401', failedToOpen, 401, EngineErrorKind.unauthorized),
      ('500', failedToOpen, 500, EngineErrorKind.http),
      (
        'connection refused',
        'tcp: Connection to tcp://127.0.0.1:1?timeout=30000000 failed: '
            'Connection refused',
        null,
        EngineErrorKind.network,
      ),
      (
        'timeout',
        'tcp: Connection to tcp://10.255.255.1:80?timeout=30000000 failed: '
            'Connection timed out',
        null,
        EngineErrorKind.network,
      ),
      (
        'unresolvable host',
        'tcp: Failed to resolve hostname nowhere.invalid: '
            'Name or service not known',
        null,
        EngineErrorKind.network,
      ),
      (
        'unrecognised format',
        'Failed to recognize file format.',
        null,
        EngineErrorKind.decode,
      ),
      ('decode failure', 'Error decoding audio.', null, EngineErrorKind.decode),
      ('unknown text', failedToOpen, null, EngineErrorKind.unknown),
      ('empty text', '', null, EngineErrorKind.unknown),
    ];

    for (final (name, message, status, kind) in table) {
      test('$name is ${kind.name}', () {
        final error = classifyMpvError(message, httpStatus: status);
        expect(error.kind, kind);
        expect(error.httpStatus, status);
        expect(error.detail, contains(message));
      });
    }

    test('an HTTP status decides over the text', () {
      final error = classifyMpvError(
        'Failed to recognize file format.',
        httpStatus: 404,
      );
      expect(error.kind, EngineErrorKind.notFound);
    });

    test('a status below 400 is not an HTTP error', () {
      final error = classifyMpvError(failedToOpen, httpStatus: 200);
      expect(error.kind, EngineErrorKind.unknown);
      expect(error.httpStatus, isNull);
    });

    test('a missing local file is notFound', () {
      final error = classifyMpvError(
        "Cannot open file '/tmp/gone.flac': No such file or directory",
      );
      expect(error.kind, EngineErrorKind.notFound);
    });
  });

  group('httpStatusInMpvLog', () {
    test("reads the status of ffmpeg's HTTP error line", () {
      expect(httpStatusInMpvLog('http: HTTP error 404 Not Found'), 404);
      expect(
        httpStatusInMpvLog('http: HTTP error 500 Internal Server Error'),
        500,
      );
      expect(httpStatusInMpvLog('HTTP error 416 Requested Range'), 416);
    });

    test('is null for any other line', () {
      expect(httpStatusInMpvLog('Failed to open http://host/404.'), isNull);
      expect(httpStatusInMpvLog('Reading plaintext playlist.'), isNull);
      expect(httpStatusInMpvLog(''), isNull);
    });
  });

  group('mediaKitSlotEvent', () {
    test('playlist index 0 to 1 with a next source is AdvancedToNext', () {
      expect(
        mediaKitSlotEvent(
          index: 1,
          completed: false,
          currentId: 'a',
          nextId: 'b',
          completedReported: false,
        ),
        const AdvancedToNext('b'),
      );
    });

    test('index 0 is no event', () {
      expect(
        mediaKitSlotEvent(
          index: 0,
          completed: false,
          currentId: 'a',
          nextId: 'b',
          completedReported: false,
        ),
        isNull,
      );
    });

    test('index 1 without a next source is no event', () {
      expect(
        mediaKitSlotEvent(
          index: 1,
          completed: false,
          currentId: 'a',
          nextId: null,
          completedReported: false,
        ),
        isNull,
      );
    });

    test('completed with no next is Completed, once', () {
      expect(
        mediaKitSlotEvent(
          index: 0,
          completed: true,
          currentId: 'a',
          nextId: null,
          completedReported: false,
        ),
        const Completed('a'),
      );
      expect(
        mediaKitSlotEvent(
          index: 0,
          completed: true,
          currentId: 'a',
          nextId: null,
          completedReported: true,
        ),
        isNull,
      );
    });

    test('completed at the end of an item with a next is no event', () {
      // media_kit reports completed for a moment at the end of every item.
      expect(
        mediaKitSlotEvent(
          index: 0,
          completed: true,
          currentId: 'a',
          nextId: 'b',
          completedReported: false,
        ),
        isNull,
      );
    });

    test('nothing loaded is no event', () {
      expect(
        mediaKitSlotEvent(
          index: 0,
          completed: true,
          currentId: null,
          nextId: null,
          completedReported: false,
        ),
        isNull,
      );
    });
  });

  group('mpvVolume', () {
    test('maps linear 0.0, 0.5 and 1.0 to mpv volume 0, 50 and 100', () {
      expect(mpvVolume(0), 0);
      expect(mpvVolume(0.5), 50);
      expect(mpvVolume(1), 100);
    });

    test('clamps out-of-range values', () {
      expect(mpvVolume(-0.5), 0);
      expect(mpvVolume(1.5), 100);
      expect(mpvVolume(double.nan), 0);
    });
  });

  group('clockMoved', () {
    const from = Duration(seconds: 1);
    const duration = Duration(seconds: 3);

    test('is false for jitter around the start position', () {
      for (final ms in const [1000, 1000.066, 1010, 990, 1049]) {
        expect(
          clockMoved(
            from: from,
            position: Duration(microseconds: (ms * 1000).round()),
            duration: duration,
          ),
          isFalse,
          reason: '$ms ms',
        );
      }
    });

    test('is true once the position moved 50 ms on', () {
      expect(
        clockMoved(
          from: from,
          position: const Duration(milliseconds: 1050),
          duration: duration,
        ),
        isTrue,
      );
    });

    test('is true at the end of an item that started within 50 ms of it', () {
      expect(
        clockMoved(
          from: const Duration(milliseconds: 2980),
          position: duration,
          duration: duration,
        ),
        isTrue,
      );
    });
  });

  group('mpvSeconds', () {
    test('reads a property value in seconds', () {
      expect(mpvSeconds('0.516630'), const Duration(microseconds: 516630));
      expect(mpvSeconds('12'), const Duration(seconds: 12));
      expect(mpvSeconds('-0.25'), const Duration(milliseconds: -250));
    });

    test('is null for an unavailable property', () {
      expect(mpvSeconds(''), isNull);
      expect(mpvSeconds('no'), isNull);
      expect(mpvSeconds('nan'), isNull);
    });
  });

  group('mediaKitPosition', () {
    const second = Duration(seconds: 1);
    const duration = Duration(seconds: 3);

    test('passes a position within the item through', () {
      expect(
        mediaKitPosition(raw: second, duration: duration, ended: false),
        second,
      );
    });

    test('clamps to [0, duration] and is the duration once ended', () {
      expect(
        mediaKitPosition(
          raw: const Duration(milliseconds: -40),
          duration: duration,
          ended: false,
        ),
        Duration.zero,
      );
      expect(
        mediaKitPosition(
          raw: const Duration(seconds: 4),
          duration: duration,
          ended: false,
        ),
        duration,
      );
      expect(
        mediaKitPosition(raw: second, duration: duration, ended: true),
        duration,
      );
    });

    test('after a transition, holds the reset and negative positions', () {
      // media_kit sets the position to zero when a file starts, then mpv
      // reports the new item's position minus the previous item's audio
      // that is still buffered.
      for (final raw in const [
        Duration.zero,
        Duration(milliseconds: -460),
        Duration(milliseconds: -10),
      ]) {
        expect(
          mediaKitPosition(
            raw: raw,
            duration: duration,
            ended: false,
            sinceAdvance: const Duration(milliseconds: 100),
          ),
          isNull,
          reason: '$raw',
        );
      }
    });

    test("after a transition, holds the previous item's late position", () {
      expect(
        mediaKitPosition(
          raw: const Duration(milliseconds: 950),
          duration: duration,
          ended: false,
          sinceAdvance: const Duration(milliseconds: 20),
        ),
        isNull,
      );
    });

    test("after a transition, passes the new item's own position", () {
      expect(
        mediaKitPosition(
          raw: const Duration(milliseconds: 13),
          duration: duration,
          ended: false,
          sinceAdvance: const Duration(milliseconds: 340),
        ),
        const Duration(milliseconds: 13),
      );
    });
  });
}
