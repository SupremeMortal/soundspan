// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/just_audio_mapping.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';

void main() {
  group('engineErrorFor', () {
    EngineErrorKind kindOf(
      PlayerFamily family,
      int code, {
      int? httpStatus,
      bool unreachable = false,
    }) => engineErrorFor(
      family: family,
      code: code,
      httpStatus: httpStatus,
      unreachable: unreachable,
    ).kind;

    test('HTTP 404 is notFound on every platform', () {
      for (final family in PlayerFamily.values) {
        final error = engineErrorFor(family: family, code: 0, httpStatus: 404);
        expect(error.kind, EngineErrorKind.notFound, reason: family.name);
        expect(error.httpStatus, 404);
      }
    });

    test('HTTP 401 is unauthorized on every platform', () {
      for (final family in PlayerFamily.values) {
        final error = engineErrorFor(family: family, code: 0, httpStatus: 401);
        expect(error.kind, EngineErrorKind.unauthorized, reason: family.name);
        expect(error.httpStatus, 401);
      }
    });

    test('another HTTP error status is http with that status', () {
      for (final status in [400, 403, 416, 500, 503]) {
        final error = engineErrorFor(
          family: PlayerFamily.android,
          code: 0,
          httpStatus: status,
        );
        expect(error.kind, EngineErrorKind.http, reason: '$status');
        expect(error.httpStatus, status);
      }
    });

    test('a success status says nothing; the player code decides', () {
      expect(
        kindOf(PlayerFamily.android, 1, httpStatus: 206),
        EngineErrorKind.decode,
      );
      final error = engineErrorFor(
        family: PlayerFamily.android,
        code: 0,
        httpStatus: 200,
      );
      expect(error.kind, EngineErrorKind.unknown);
      expect(error.httpStatus, isNull);
    });

    test('no response from the server is a network failure', () {
      for (final family in PlayerFamily.values) {
        expect(
          kindOf(family, 0, unreachable: true),
          EngineErrorKind.network,
          reason: family.name,
        );
      }
    });

    test('connection failures reported by the player are network', () {
      for (final code in [-1001, -1003, -1004, -1005, -1009]) {
        expect(
          kindOf(PlayerFamily.darwin, code),
          EngineErrorKind.network,
          reason: '$code',
        );
      }
      expect(kindOf(PlayerFamily.web, 2), EngineErrorKind.network);
    });

    test('format errors are decode', () {
      expect(kindOf(PlayerFamily.android, 1), EngineErrorKind.decode);
      for (final code in [-11828, -11829, -11821, -11853]) {
        expect(
          kindOf(PlayerFamily.darwin, code),
          EngineErrorKind.decode,
          reason: '$code',
        );
      }
      expect(kindOf(PlayerFamily.web, 3), EngineErrorKind.decode);
      expect(kindOf(PlayerFamily.web, 4), EngineErrorKind.decode);
    });

    test('the darwin authentication and missing-file codes', () {
      expect(kindOf(PlayerFamily.darwin, -1013), EngineErrorKind.unauthorized);
      expect(kindOf(PlayerFamily.darwin, -1100), EngineErrorKind.notFound);
    });

    test('anything else is unknown', () {
      expect(kindOf(PlayerFamily.android, 0), EngineErrorKind.unknown);
      expect(kindOf(PlayerFamily.android, 2), EngineErrorKind.unknown);
      expect(kindOf(PlayerFamily.darwin, -42), EngineErrorKind.unknown);
      expect(kindOf(PlayerFamily.web, 1), EngineErrorKind.unknown);
    });

    test('the detail names the code and message for logs', () {
      final error = engineErrorFor(
        family: PlayerFamily.android,
        code: 0,
        message: 'Source error',
      );
      expect(error.detail, contains('0'));
      expect(error.detail, contains('Source error'));
    });
  });

  group('slotEvent', () {
    test('index change 0 to 1 while ready is AdvancedToNext', () {
      expect(
        slotEvent(
          sequence: const ['a', 'b'],
          index: 1,
          status: EngineStatus.ready,
          currentId: 'a',
          nextId: 'b',
          completedReported: false,
        ),
        const AdvancedToNext('b'),
      );
    });

    test('index change while buffering the next item is AdvancedToNext', () {
      expect(
        slotEvent(
          sequence: const ['a', 'b'],
          index: 1,
          status: EngineStatus.buffering,
          currentId: 'a',
          nextId: 'b',
          completedReported: false,
        ),
        const AdvancedToNext('b'),
      );
    });

    test('completed with no next is Completed', () {
      expect(
        slotEvent(
          sequence: const ['a'],
          index: 0,
          status: EngineStatus.ended,
          currentId: 'a',
          nextId: null,
          completedReported: false,
        ),
        const Completed('a'),
      );
    });

    test('Completed is reported once', () {
      expect(
        slotEvent(
          sequence: const ['a'],
          index: 0,
          status: EngineStatus.ended,
          currentId: 'a',
          nextId: null,
          completedReported: true,
        ),
        isNull,
      );
    });

    test('the current item playing on is no event', () {
      expect(
        slotEvent(
          sequence: const ['a', 'b'],
          index: 0,
          status: EngineStatus.ready,
          currentId: 'a',
          nextId: 'b',
          completedReported: false,
        ),
        isNull,
      );
    });

    test('the played item removed after a transition is no event', () {
      // After AdvancedToNext('b') the engine's current is b and the player
      // drops a, so b moves from index 1 to index 0.
      for (final (sequence, index) in [
        (const ['a', 'b'], 1),
        (const ['b'], 0),
      ]) {
        expect(
          slotEvent(
            sequence: sequence,
            index: index,
            status: EngineStatus.ready,
            currentId: 'b',
            nextId: null,
            completedReported: false,
          ),
          isNull,
        );
      }
    });

    test('a replaced next item never becomes current', () {
      expect(
        slotEvent(
          sequence: const ['a', 'b'],
          index: 1,
          status: EngineStatus.ready,
          currentId: 'a',
          nextId: 'c',
          completedReported: false,
        ),
        isNull,
      );
    });

    test('no index is no event', () {
      expect(
        slotEvent(
          sequence: const [],
          index: null,
          status: EngineStatus.idle,
          currentId: null,
          nextId: null,
          completedReported: false,
        ),
        isNull,
      );
    });
  });

  group('reportedPosition', () {
    const duration = Duration(seconds: 3);

    test('is clamped to the duration', () {
      expect(
        reportedPosition(
          raw: const Duration(seconds: 4),
          duration: duration,
          ended: false,
        ),
        duration,
      );
      expect(
        reportedPosition(
          raw: const Duration(milliseconds: -5),
          duration: duration,
          ended: false,
        ),
        Duration.zero,
      );
    });

    test('is the duration once ended', () {
      expect(
        reportedPosition(
          raw: const Duration(milliseconds: 2990),
          duration: duration,
          ended: true,
        ),
        duration,
      );
    });

    test('is unknown while the player still reports the previous item end '
        'just after a transition', () {
      expect(
        reportedPosition(
          raw: const Duration(milliseconds: 2980),
          duration: duration,
          ended: false,
          sinceAdvance: const Duration(milliseconds: 10),
        ),
        isNull,
      );
    });

    test('keeps a plausible position just after a transition', () {
      expect(
        reportedPosition(
          raw: const Duration(milliseconds: 40),
          duration: duration,
          ended: false,
          sinceAdvance: const Duration(milliseconds: 30),
        ),
        const Duration(milliseconds: 40),
      );
    });

    test('trusts the player again a second after a transition', () {
      expect(
        reportedPosition(
          raw: const Duration(milliseconds: 2500),
          duration: duration,
          ended: false,
          sinceAdvance: const Duration(milliseconds: 1200),
        ),
        const Duration(milliseconds: 2500),
      );
    });
  });
}
