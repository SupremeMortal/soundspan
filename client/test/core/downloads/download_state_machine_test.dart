// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/downloads/download_state_machine.dart';
import 'package:soundspan/core/storage/state/enums.dart';

final DateTime _now = DateTime.utc(2026, 5, 1, 12);

DownloadTransition _reduce(DownloadItemState state, DownloadEvent event) =>
    reduce(state, event, now: _now);

const _queued = DownloadItemState(status: DownloadStatus.queued);
const _running = DownloadItemState(
  status: DownloadStatus.running,
  taskId: 'task',
);

DownloadTransition _fail(
  DownloadItemState state, {
  TransferFailureKind kind = TransferFailureKind.http,
  int? httpStatus,
}) => _reduce(state, TransferFailed(kind, httpStatus: httpStatus));

void main() {
  test('queued → running stores the task id and asks for an enqueue', () {
    const state = DownloadItemState(
      status: DownloadStatus.queued,
      waitingFor: DownloadWaitReason.space,
    );
    final t = _reduce(state, const SlotGranted('abc'));
    expect(t.next.status, DownloadStatus.running);
    expect(t.next.taskId, 'abc');
    expect(t.next.waitingFor, isNull);
    expect(t.effects, [const EnqueueTask('abc')]);
  });

  test('running → verifying on transfer complete, asking for verification', () {
    final t = _reduce(_running, const TransferCompleted());
    expect(t.next.status, DownloadStatus.verifying);
    expect(t.next.taskId, 'task');
    expect(t.effects, [const VerifyFile()]);
  });

  test(
    'verifying → completed renames the part file and records size and time',
    () {
      const state = DownloadItemState(
        status: DownloadStatus.verifying,
        attempts: 2,
        taskId: 'task',
      );
      final t = _reduce(
        state,
        const VerificationPassed(1234, 'media/ab/x.mp3'),
      );
      expect(t.next.status, DownloadStatus.completed);
      expect(t.next.sizeBytes, 1234);
      expect(t.next.relativePath, 'media/ab/x.mp3');
      expect(t.next.completedAt, _now);
      expect(t.next.failureCode, isNull);
      expect(t.effects, [
        const RenamePartToFinal('media/ab/x.mp3'),
        const SendComplete(),
      ]);
    },
  );

  test(
    'completed → confirmed sets serverConfirmed without changing status',
    () {
      const state = DownloadItemState(status: DownloadStatus.completed);
      final t = _reduce(state, const ServerConfirmed());
      expect(t.next.status, DownloadStatus.completed);
      expect(t.next.serverConfirmed, isTrue);
      expect(t.effects, isEmpty);
    },
  );

  test(
    'running → paused for user, Wi-Fi and space, each recording waitingFor',
    () {
      for (final reason in DownloadWaitReason.values) {
        final t = _reduce(_running, PauseRequested(reason));
        expect(t.next.status, DownloadStatus.paused, reason: reason.name);
        expect(t.next.waitingFor, reason);
        expect(t.effects, [const PauseOrCancelKeepingPart()]);
      }
    },
  );

  group('running → failed(retryable)', () {
    test('for a network error', () {
      final t = _fail(_running, kind: TransferFailureKind.network);
      expect(t.next.status, DownloadStatus.failedRetryable);
      expect(t.next.attempts, 1);
      expect(t.next.failureCode, DownloadFailureCodes.network);
      expect(t.next.nextAttemptAt, _now.add(const Duration(seconds: 5)));
      expect(t.effects, [ScheduleRetry(_now.add(const Duration(seconds: 5)))]);
    });

    test('for 500 and 429', () {
      for (final status in [500, 429]) {
        final t = _fail(_running, httpStatus: status);
        expect(t.next.status, DownloadStatus.failedRetryable);
        expect(t.next.failureCode, 'HTTP_$status');
        expect(t.effects, [
          ScheduleRetry(_now.add(const Duration(seconds: 5))),
        ]);
      }
    });

    test('for 401, asking for a credential refresh first', () {
      final t = _fail(_running, httpStatus: 401);
      expect(t.next.status, DownloadStatus.failedRetryable);
      expect(t.effects, [
        const RefreshCredentials(),
        ScheduleRetry(_now.add(const Duration(seconds: 5))),
      ]);
    });

    test('with the backoff sequence 5 s, 15 s, 45 s, 135 s', () {
      var state = _running;
      final delays = <Duration>[];
      for (var i = 0; i < 4; i++) {
        final t = _fail(state, kind: TransferFailureKind.network);
        delays.add(t.next.nextAttemptAt!.difference(_now));
        state = t.next.copyWith(status: DownloadStatus.running);
      }
      expect(delays, const [
        Duration(seconds: 5),
        Duration(seconds: 15),
        Duration(seconds: 45),
        Duration(seconds: 135),
      ]);
    });

    test('with the delay 405 s after four attempts and the 1 h cap', () {
      expect(retryDelay(0), const Duration(seconds: 5));
      expect(retryDelay(4), const Duration(seconds: 405));
      expect(retryDelay(5), const Duration(seconds: 1215));
      expect(retryDelay(6), const Duration(seconds: 3600));
      expect(retryDelay(40), const Duration(hours: 1));
    });
  });

  group('running → failed(permanent)', () {
    test('for 400, without a re-resolve', () {
      final t = _fail(_running, httpStatus: 400);
      expect(t.next.status, DownloadStatus.failedPermanent);
      expect(t.next.failureCode, 'HTTP_400');
      expect(t.next.nextAttemptAt, isNull);
      expect(t.effects, isEmpty);
    });

    test('for 404 and 409, asking for a re-resolve', () {
      for (final status in [404, 409]) {
        final t = _fail(_running, httpStatus: status);
        expect(t.next.status, DownloadStatus.failedPermanent);
        expect(t.next.failureCode, 'HTTP_$status');
        expect(t.effects, [const ReResolveCollection()]);
      }
    });
  });

  test('completed → missing re-queues', () {
    final completed = DownloadItemState(
      status: DownloadStatus.completed,
      serverConfirmed: true,
      sizeBytes: 10,
      relativePath: 'media/ab/x.mp3',
      completedAt: _now,
    );
    final t = _reduce(completed, const FileMissing());
    expect(t.next.status, DownloadStatus.queued);
    expect(t.next.serverConfirmed, isTrue);
    expect(t.next.sizeBytes, isNull);
    expect(t.next.relativePath, isNull);
    expect(t.next.completedAt, isNull);
    expect(t.effects, isEmpty);

    const missing = DownloadItemState(status: DownloadStatus.missing);
    expect(
      _reduce(missing, const FileMissing()).next.status,
      DownloadStatus.queued,
    );
  });

  test('any → revoked from every status deletes the file and the row', () {
    for (final status in DownloadStatus.values) {
      final t = _reduce(DownloadItemState(status: status), const Revoked());
      expect(t.next.status, DownloadStatus.revoked, reason: status.name);
      expect(t.effects, [const DeleteFile(), const DeleteRow()]);
    }
  });

  test('the fifth retryable failure becomes permanent', () {
    const state = DownloadItemState(
      status: DownloadStatus.running,
      attempts: 4,
    );
    final t = _fail(state, httpStatus: 401);
    expect(t.next.status, DownloadStatus.failedPermanent);
    expect(t.next.attempts, 5);
    expect(t.next.failureCode, DownloadFailureCodes.retriesExhausted);
    expect(t.next.nextAttemptAt, isNull);
    expect(t.effects, isEmpty);
  });

  test('failed(retryable) → queued when the backoff elapses', () {
    final failed = DownloadItemState(
      status: DownloadStatus.failedRetryable,
      attempts: 2,
      failureCode: 'HTTP_500',
      nextAttemptAt: _now,
    );
    final t = _reduce(failed, const BackoffElapsed());
    expect(t.next.status, DownloadStatus.queued);
    expect(t.next.attempts, 2);
    expect(t.next.nextAttemptAt, isNull);
    expect(t.next.failureCode, isNull);
  });

  test('Retry re-queues a failed item and resets attempts', () {
    for (final status in [
      DownloadStatus.failedRetryable,
      DownloadStatus.failedPermanent,
    ]) {
      final failed = DownloadItemState(
        status: status,
        attempts: 5,
        failureCode: 'X',
        nextAttemptAt: _now,
      );
      final t = _reduce(failed, const RetryPressed());
      expect(t.next.status, DownloadStatus.queued, reason: status.name);
      expect(t.next.attempts, 0);
      expect(t.next.failureCode, isNull);
      expect(t.next.nextAttemptAt, isNull);
    }
  });

  test('paused → queued on resume, clearing waitingFor', () {
    const paused = DownloadItemState(
      status: DownloadStatus.paused,
      waitingFor: DownloadWaitReason.wifi,
    );
    final t = _reduce(paused, const ResumeRequested());
    expect(t.next.status, DownloadStatus.queued);
    expect(t.next.waitingFor, isNull);
    expect(t.effects, isEmpty);
  });

  test('a failed verification deletes the file and is a retryable failure', () {
    const verifying = DownloadItemState(status: DownloadStatus.verifying);
    final t = _reduce(verifying, const VerificationFailed());
    expect(t.next.status, DownloadStatus.failedRetryable);
    expect(t.next.attempts, 1);
    expect(t.next.failureCode, DownloadFailureCodes.verificationFailed);
    expect(t.effects, [
      const DeleteFile(),
      ScheduleRetry(_now.add(const Duration(seconds: 5))),
    ]);
  });

  test('TaskLost returns a running item to queued with attempts unchanged', () {
    const state = DownloadItemState(
      status: DownloadStatus.running,
      attempts: 3,
      taskId: 'task',
    );
    final t = _reduce(state, const TaskLost());
    expect(t.next.status, DownloadStatus.queued);
    expect(t.next.attempts, 3);
    expect(t.next.taskId, isNull);
    expect(t.effects, isEmpty);
  });

  test('an inapplicable event is a no-op', () {
    final cases = <(DownloadItemState, DownloadEvent)>[
      (_queued, const TransferCompleted()),
      (_queued, const ServerConfirmed()),
      (_running, const SlotGranted('x')),
      (_running, const RetryPressed()),
      (
        const DownloadItemState(status: DownloadStatus.verifying),
        const PauseRequested(DownloadWaitReason.user),
      ),
      (
        const DownloadItemState(status: DownloadStatus.completed),
        const TaskLost(),
      ),
      (
        const DownloadItemState(status: DownloadStatus.unavailable),
        const ResumeRequested(),
      ),
      (_queued, const BackoffElapsed()),
      (_queued, const VerificationPassed(1, 'x')),
      (_queued, const VerificationFailed()),
      (_queued, const FileMissing()),
      (_queued, const TransferFailed(TransferFailureKind.network)),
    ];
    for (final (state, event) in cases) {
      final t = _reduce(state, event);
      expect(t.next, state, reason: '$event on ${state.status.name}');
      expect(t.effects, isEmpty);
    }
  });
}
