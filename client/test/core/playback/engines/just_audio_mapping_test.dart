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

    test('is unknown at the end of an item with a next item loaded', () {
      for (final raw in [duration, const Duration(milliseconds: 3040)]) {
        expect(
          reportedPosition(
            raw: raw,
            duration: duration,
            ended: false,
            hasNext: true,
          ),
          isNull,
          reason: '$raw',
        );
      }
      expect(
        reportedPosition(
          raw: const Duration(milliseconds: 2990),
          duration: duration,
          ended: false,
          hasNext: true,
        ),
        const Duration(milliseconds: 2990),
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

  group('PlayingReport', () {
    const ready = EngineStatus.ready;
    const buffering = EngineStatus.buffering;

    Duration ms(num value) => Duration(microseconds: (value * 1000).round());

    test('reproduces the iOS load and play failure without going backwards '
        'or reporting ready before the player confirms', () {
      final report = PlayingReport(confirmStart: true);
      // The player finished loading item a, paused at zero.
      final loaded = Object();
      expect(
        report.next(
          event: loaded,
          status: ready,
          playing: false,
          position: Duration.zero,
          eventPosition: Duration.zero,
        ),
        (status: ready, position: Duration.zero),
      );

      // play(): just_audio marks itself playing with an event of its own and
      // extrapolates from it, before AVPlayer has started.
      final requested = Object();
      report.playRequested(requested);
      expect(
        report.next(
          event: requested,
          status: ready,
          playing: true,
          position: ms(6.322),
          eventPosition: Duration.zero,
        ),
        (status: buffering, position: Duration.zero),
      );

      // AVPlayer waits to play: buffering at its own position.
      final waiting = Object();
      expect(
        report.next(
          event: waiting,
          status: buffering,
          playing: true,
          position: Duration.zero,
          eventPosition: Duration.zero,
        ),
        (status: buffering, position: Duration.zero),
      );

      // AVPlayer plays: the first ready report is the player's own position.
      final playing = Object();
      final confirmed = report.next(
        event: playing,
        status: ready,
        playing: true,
        position: ms(1.142),
        eventPosition: ms(1.142),
      );
      expect(confirmed, (status: ready, position: ms(1.142)));

      // From there the position only moves on.
      expect(
        report
            .next(
              event: playing,
              status: ready,
              playing: true,
              position: ms(101.5),
              eventPosition: ms(1.142),
            )
            .position,
        ms(101.5),
      );
    });

    test('never reports a lower position while one item plays', () {
      final report = PlayingReport(confirmStart: false);
      final event = Object();
      Duration at(Duration position, {EngineStatus status = ready}) => report
          .next(
            event: event,
            status: status,
            playing: true,
            position: position,
            eventPosition: position,
          )
          .position;

      expect(at(ms(6.322)), ms(6.322));
      expect(at(ms(1.142)), ms(6.322));
      expect(at(ms(300)), ms(300));
      // A stall the player detects late reports its true, lower position.
      expect(at(ms(120), status: buffering), ms(300));
      expect(at(ms(350)), ms(350));
    });

    test('restart lets a seek or a new item report a lower position', () {
      final report = PlayingReport(confirmStart: false);
      final event = Object();
      Duration at(Duration position) => report
          .next(
            event: event,
            status: ready,
            playing: true,
            position: position,
            eventPosition: position,
          )
          .position;

      expect(at(const Duration(seconds: 2)), const Duration(seconds: 2));
      report.restart();
      expect(at(ms(500)), ms(500));
    });

    test('without confirmStart, ready is reported as soon as the player '
        'says so', () {
      final report = PlayingReport(confirmStart: false);
      final requested = Object();
      report.playRequested(requested);
      expect(
        report.next(
          event: requested,
          status: ready,
          playing: true,
          position: ms(6),
          eventPosition: Duration.zero,
        ),
        (status: ready, position: ms(6)),
      );
    });

    test('a pause before the player confirms ends the wait', () {
      final report = PlayingReport(confirmStart: true);
      final requested = Object();
      report.playRequested(requested);
      expect(
        report
            .next(
              event: requested,
              status: ready,
              playing: false,
              position: Duration.zero,
              eventPosition: Duration.zero,
            )
            .status,
        ready,
      );
      // A later report of the same event while playing is not held back.
      expect(
        report
            .next(
              event: requested,
              status: ready,
              playing: true,
              position: ms(10),
              eventPosition: Duration.zero,
            )
            .status,
        ready,
      );
    });

    test('reset forgets a pending request', () {
      final report = PlayingReport(confirmStart: true);
      final requested = Object();
      report
        ..playRequested(requested)
        ..reset();
      expect(
        report
            .next(
              event: requested,
              status: ready,
              playing: true,
              position: ms(10),
              eventPosition: Duration.zero,
            )
            .status,
        ready,
      );
    });
  });
}
