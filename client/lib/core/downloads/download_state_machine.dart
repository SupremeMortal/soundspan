// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The item state machine of doc 07 (Item State Machine) as a pure
/// function.
///
/// [reduce] decides; it reads no clock, touches no file and talks to no
/// database. The [DownloadEffect]s it returns are data that the downloader,
/// scheduler and controller execute.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:soundspan/core/storage/state/enums.dart';

/// Why a queued or paused item is not running: the `waitingFor` column of
/// `download_items`.
enum DownloadWaitReason {
  /// The user paused it.
  user,

  /// Downloads are Wi-Fi-only and the device is not on Wi-Fi.
  wifi,

  /// The disk or the device limit has no room for it.
  space,
}

/// How a transfer failed.
enum TransferFailureKind {
  /// No HTTP response: the connection failed or was lost.
  network,

  /// The server answered with an error status.
  http,
}

/// The `failureCode` values the state machine writes. An HTTP failure is
/// `HTTP_<status>`.
abstract final class DownloadFailureCodes {
  /// A transfer failed without an HTTP response.
  static const String network = 'NETWORK';

  /// The downloaded file did not pass verification.
  static const String verificationFailed = 'VERIFICATION_FAILED';

  /// The last of [kMaxRetryableFailures] retryable failures.
  static const String retriesExhausted = 'RETRIES_EXHAUSTED';

  /// The code of an HTTP failure with [status].
  static String http(int? status) => 'HTTP_${status ?? 0}';
}

/// The number of retryable failures after which an item fails permanently.
const int kMaxRetryableFailures = 5;

/// The backoff after a retryable failure with [attempts] earlier attempts:
/// 5 s × 3^[attempts], capped at one hour.
Duration retryDelay(int attempts) {
  const cap = Duration(hours: 1);
  // 5 × 3^7 s already exceeds the cap; stop before the power overflows.
  if (attempts >= 7) return cap;
  final delay = Duration(seconds: 5 * math.pow(3, attempts).toInt());
  return delay > cap ? cap : delay;
}

/// The fields of a `download_items` row that the transition rules read or
/// write.
@immutable
final class DownloadItemState {
  /// Creates the state.
  const new({
    required this.status,
    this.attempts = 0,
    this.taskId,
    this.serverConfirmed = false,
    this.failureCode,
    this.nextAttemptAt,
    this.waitingFor,
    this.sizeBytes,
    this.relativePath,
    this.completedAt,
  });

  /// Where the item is in the machine.
  final DownloadStatus status;

  /// Retryable failures since the last reset.
  final int attempts;

  /// The transfer task's id.
  final String? taskId;

  /// Whether the server acknowledged the completed download.
  final bool serverConfirmed;

  /// Why the item failed or is unavailable; null otherwise.
  final String? failureCode;

  /// When a retryable failure may run again; stored so the scheduler can
  /// re-arm the retry after a restart.
  final DateTime? nextAttemptAt;

  /// Why a queued or paused item is not running.
  final DownloadWaitReason? waitingFor;

  /// The verified size on disk.
  final int? sizeBytes;

  /// The verified file, relative to the profile directory.
  final String? relativePath;

  /// When the file was verified.
  final DateTime? completedAt;

  /// A copy with the given fields replaced. The nullable fields are
  /// replaced by functions so that they can be cleared.
  DownloadItemState copyWith({
    DownloadStatus? status,
    int? attempts,
    String? Function()? taskId,
    bool? serverConfirmed,
    String? Function()? failureCode,
    DateTime? Function()? nextAttemptAt,
    DownloadWaitReason? Function()? waitingFor,
    int? Function()? sizeBytes,
    String? Function()? relativePath,
    DateTime? Function()? completedAt,
  }) => DownloadItemState(
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    taskId: taskId != null ? taskId() : this.taskId,
    serverConfirmed: serverConfirmed ?? this.serverConfirmed,
    failureCode: failureCode != null ? failureCode() : this.failureCode,
    nextAttemptAt: nextAttemptAt != null ? nextAttemptAt() : this.nextAttemptAt,
    waitingFor: waitingFor != null ? waitingFor() : this.waitingFor,
    sizeBytes: sizeBytes != null ? sizeBytes() : this.sizeBytes,
    relativePath: relativePath != null ? relativePath() : this.relativePath,
    completedAt: completedAt != null ? completedAt() : this.completedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is DownloadItemState &&
      other.status == status &&
      other.attempts == attempts &&
      other.taskId == taskId &&
      other.serverConfirmed == serverConfirmed &&
      other.failureCode == failureCode &&
      other.nextAttemptAt == nextAttemptAt &&
      other.waitingFor == waitingFor &&
      other.sizeBytes == sizeBytes &&
      other.relativePath == relativePath &&
      other.completedAt == completedAt;

  @override
  int get hashCode => Object.hash(
    status,
    attempts,
    taskId,
    serverConfirmed,
    failureCode,
    nextAttemptAt,
    waitingFor,
    sizeBytes,
    relativePath,
    completedAt,
  );

  @override
  String toString() =>
      'DownloadItemState(${status.name}, attempts: $attempts, '
      'failureCode: $failureCode, waitingFor: ${waitingFor?.name})';
}

/// Something that happened to an item.
@immutable
sealed class DownloadEvent {
  const new();
}

/// The scheduler gave the item a transfer slot; [taskId] is its task.
final class SlotGranted extends DownloadEvent {
  /// Creates the event.
  const new(this.taskId);

  /// The transfer task's id.
  final String taskId;

  @override
  String toString() => 'SlotGranted($taskId)';
}

/// The transfer reports that it finished.
final class TransferCompleted extends DownloadEvent {
  /// Creates the event.
  const new();
}

/// The downloaded file passed verification.
final class VerificationPassed extends DownloadEvent {
  /// Creates the event for a file of [sizeBytes] that is renamed to
  /// [relativePath].
  const new(this.sizeBytes, this.relativePath);

  /// The verified size.
  final int sizeBytes;

  /// The final file, relative to the profile directory.
  final String relativePath;

  @override
  String toString() => 'VerificationPassed($sizeBytes, $relativePath)';
}

/// The downloaded file failed verification.
final class VerificationFailed extends DownloadEvent {
  /// Creates the event.
  const new();
}

/// `POST /api/offline/items/complete` succeeded for the item.
final class ServerConfirmed extends DownloadEvent {
  /// Creates the event.
  const new();
}

/// The transfer must stop for [reason].
final class PauseRequested extends DownloadEvent {
  /// Creates the event.
  const new(this.reason);

  /// Why the transfer stops.
  final DownloadWaitReason reason;

  @override
  String toString() => 'PauseRequested(${reason.name})';
}

/// A paused item may run again.
final class ResumeRequested extends DownloadEvent {
  /// Creates the event.
  const new();
}

/// The transfer failed.
final class TransferFailed extends DownloadEvent {
  /// Creates the event; [httpStatus] is set for [TransferFailureKind.http].
  const new(this.kind, {this.httpStatus});

  /// How it failed.
  final TransferFailureKind kind;

  /// The response status of an HTTP failure.
  final int? httpStatus;

  @override
  String toString() => 'TransferFailed(${kind.name}, $httpStatus)';
}

/// The backoff of a retryable failure is over.
final class BackoffElapsed extends DownloadEvent {
  /// Creates the event.
  const new();
}

/// The user pressed Retry on a failed item.
final class RetryPressed extends DownloadEvent {
  /// Creates the event.
  const new();
}

/// A completed item's file is not on disk.
final class FileMissing extends DownloadEvent {
  /// Creates the event.
  const new();
}

/// A running item has no live transfer task.
final class TaskLost extends DownloadEvent {
  /// Creates the event.
  const new();
}

/// Reconciliation reports the item as revoked by the server.
final class Revoked extends DownloadEvent {
  /// Creates the event.
  const new();
}

/// Work a transition asks for, executed outside the state machine.
@immutable
sealed class DownloadEffect {
  const new();
}

/// Enqueue the transfer task [taskId].
final class EnqueueTask extends DownloadEffect {
  /// Creates the effect.
  const new(this.taskId);

  /// The task's id.
  final String taskId;

  @override
  bool operator ==(Object other) =>
      other is EnqueueTask && other.taskId == taskId;

  @override
  int get hashCode => taskId.hashCode;

  @override
  String toString() => 'EnqueueTask($taskId)';
}

/// Pause the transfer if it is resumable, else cancel it and keep the
/// `.part` file.
final class PauseOrCancelKeepingPart extends DownloadEffect {
  /// Creates the effect.
  const new();
}

/// Delete the item's file, final or partial.
final class DeleteFile extends DownloadEffect {
  /// Creates the effect.
  const new();
}

/// Delete the item's row.
final class DeleteRow extends DownloadEffect {
  /// Creates the effect.
  const new();
}

/// Check the finished `.part` file and answer [VerificationPassed] or
/// [VerificationFailed].
final class VerifyFile extends DownloadEffect {
  /// Creates the effect; [contentType] is the response's `Content-Type`,
  /// which the scheduler adds when it knows it.
  const new({this.contentType});

  /// The response's `Content-Type`, which picks the final file's extension.
  final String? contentType;

  @override
  bool operator ==(Object other) =>
      other is VerifyFile && other.contentType == contentType;

  @override
  int get hashCode => contentType.hashCode;

  @override
  String toString() => 'VerifyFile($contentType)';
}

/// Rename the `.part` file to [relativePath] atomically.
final class RenamePartToFinal extends DownloadEffect {
  /// Creates the effect.
  const new(this.relativePath);

  /// The final file, relative to the profile directory.
  final String relativePath;

  @override
  bool operator ==(Object other) =>
      other is RenamePartToFinal && other.relativePath == relativePath;

  @override
  int get hashCode => relativePath.hashCode;

  @override
  String toString() => 'RenamePartToFinal($relativePath)';
}

/// Send `POST /api/offline/items/complete`, directly or through the outbox.
final class SendComplete extends DownloadEffect {
  /// Creates the effect.
  const new();
}

/// Refresh the profile's credentials before the next attempt.
final class RefreshCredentials extends DownloadEffect {
  /// Creates the effect.
  const new();
}

/// Re-resolve the item's collections once with the server.
final class ReResolveCollection extends DownloadEffect {
  /// Creates the effect.
  const new();
}

/// Deliver [BackoffElapsed] at [at].
final class ScheduleRetry extends DownloadEffect {
  /// Creates the effect.
  const new(this.at);

  /// When the retry is due, in UTC.
  final DateTime at;

  @override
  bool operator ==(Object other) => other is ScheduleRetry && other.at == at;

  @override
  int get hashCode => at.hashCode;

  @override
  String toString() => 'ScheduleRetry($at)';
}

/// The result of [reduce]: the next state and the effects to run.
@immutable
final class DownloadTransition {
  /// Creates the transition.
  const new(this.next, this.effects);

  /// The state to persist.
  final DownloadItemState next;

  /// The work to run after persisting [next], in order.
  final List<DownloadEffect> effects;

  @override
  bool operator ==(Object other) =>
      other is DownloadTransition &&
      other.next == next &&
      listEquals(other.effects, effects);

  @override
  int get hashCode => Object.hash(next, Object.hashAll(effects));

  @override
  String toString() => 'DownloadTransition($next, $effects)';
}

/// Applies [event] to [state] at [now].
///
/// An event that does not apply to the current status returns [state]
/// unchanged with no effects.
DownloadTransition reduce(
  DownloadItemState state,
  DownloadEvent event, {
  required DateTime now,
}) {
  final status = state.status;
  return switch (event) {
    Revoked() => DownloadTransition(
      state.copyWith(
        status: DownloadStatus.revoked,
        waitingFor: () => null,
        nextAttemptAt: () => null,
      ),
      const [DeleteFile(), DeleteRow()],
    ),
    SlotGranted(:final taskId) when status == DownloadStatus.queued =>
      DownloadTransition(
        state.copyWith(
          status: DownloadStatus.running,
          taskId: () => taskId,
          waitingFor: () => null,
        ),
        [EnqueueTask(taskId)],
      ),
    TransferCompleted() when status == DownloadStatus.running =>
      DownloadTransition(
        state.copyWith(status: DownloadStatus.verifying),
        const [VerifyFile()],
      ),
    VerificationPassed(:final sizeBytes, :final relativePath)
        when status == DownloadStatus.verifying =>
      DownloadTransition(
        state.copyWith(
          status: DownloadStatus.completed,
          failureCode: () => null,
          sizeBytes: () => sizeBytes,
          relativePath: () => relativePath,
          completedAt: () => now,
        ),
        [RenamePartToFinal(relativePath), const SendComplete()],
      ),
    VerificationFailed() when status == DownloadStatus.verifying =>
      _retryableFailure(
        state,
        DownloadFailureCodes.verificationFailed,
        now,
        before: const [DeleteFile()],
      ),
    ServerConfirmed() when status == DownloadStatus.completed =>
      DownloadTransition(state.copyWith(serverConfirmed: true), const []),
    PauseRequested(:final reason) when status == DownloadStatus.running =>
      DownloadTransition(
        state.copyWith(status: DownloadStatus.paused, waitingFor: () => reason),
        const [PauseOrCancelKeepingPart()],
      ),
    ResumeRequested() when status == DownloadStatus.paused =>
      DownloadTransition(_queued(state), const []),
    TransferFailed() when status == DownloadStatus.running => _transferFailed(
      state,
      event,
      now,
    ),
    BackoffElapsed() when status == DownloadStatus.failedRetryable =>
      DownloadTransition(_queued(state), const []),
    RetryPressed()
        when status == DownloadStatus.failedRetryable ||
            status == DownloadStatus.failedPermanent =>
      DownloadTransition(_queued(state).copyWith(attempts: 0), const []),
    FileMissing()
        when status == DownloadStatus.completed ||
            status == DownloadStatus.missing =>
      DownloadTransition(
        _queued(state).copyWith(
          sizeBytes: () => null,
          relativePath: () => null,
          completedAt: () => null,
        ),
        const [],
      ),
    TaskLost() when status == DownloadStatus.running => DownloadTransition(
      _queued(state).copyWith(taskId: () => null),
      const [],
    ),
    _ => DownloadTransition(state, const []),
  };
}

DownloadItemState _queued(DownloadItemState state) => state.copyWith(
  status: DownloadStatus.queued,
  failureCode: () => null,
  nextAttemptAt: () => null,
  waitingFor: () => null,
);

/// Network errors, 5xx, 429 and 401 are retried; any other 4xx is
/// permanent, and 404 and 409 also re-resolve the collection.
DownloadTransition _transferFailed(
  DownloadItemState state,
  TransferFailed event,
  DateTime now,
) {
  if (event.kind == TransferFailureKind.network) {
    return _retryableFailure(state, DownloadFailureCodes.network, now);
  }
  final httpStatus = event.httpStatus;
  final code = DownloadFailureCodes.http(httpStatus);
  final permanent =
      httpStatus != null &&
      httpStatus >= 400 &&
      httpStatus < 500 &&
      httpStatus != 401 &&
      httpStatus != 429;
  if (!permanent) {
    return _retryableFailure(
      state,
      code,
      now,
      before: httpStatus == 401 ? const [RefreshCredentials()] : const [],
    );
  }
  return DownloadTransition(
    state.copyWith(
      status: DownloadStatus.failedPermanent,
      failureCode: () => code,
      nextAttemptAt: () => null,
    ),
    httpStatus == 404 || httpStatus == 409
        ? const [ReResolveCollection()]
        : const [],
  );
}

DownloadTransition _retryableFailure(
  DownloadItemState state,
  String code,
  DateTime now, {
  List<DownloadEffect> before = const [],
}) {
  final attempts = state.attempts + 1;
  if (attempts >= kMaxRetryableFailures) {
    return DownloadTransition(
      state.copyWith(
        status: DownloadStatus.failedPermanent,
        attempts: attempts,
        failureCode: () => DownloadFailureCodes.retriesExhausted,
        nextAttemptAt: () => null,
      ),
      [...before.whereType<DeleteFile>()],
    );
  }
  final at = now.add(retryDelay(state.attempts));
  return DownloadTransition(
    state.copyWith(
      status: DownloadStatus.failedRetryable,
      attempts: attempts,
      failureCode: () => code,
      nextAttemptAt: () => at,
    ),
    [...before, ScheduleRetry(at)],
  );
}
