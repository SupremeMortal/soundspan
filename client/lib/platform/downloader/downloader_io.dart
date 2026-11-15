// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/platform/downloader/downloader.dart';

/// The [Downloader] of the native app.
Downloader createDownloader() => BackgroundDownloader();

/// The `background_downloader` [Downloader] of the native targets (doc 07,
/// Transfers).
///
/// The plugin is a process-wide singleton with one update stream, so every
/// instance shares one broadcast of it: a new instance after `start()` sees
/// the tasks an earlier one enqueued.
final class BackgroundDownloader implements Downloader {
  /// Creates a downloader over the plugin's singleton.
  new();

  static final AppLogger _log = AppLogger.scope('Downloader');

  /// The plugin's single-subscription update stream, shared by every
  /// instance.
  static Stream<TaskUpdate>? _sharedUpdates;

  /// Tasks whose first response has been reported, so
  /// [DownloaderResponseInfo] is emitted once per transfer.
  static final Set<String> _reported = {};

  static Stream<TaskUpdate> get _updates =>
      _sharedUpdates ??= FileDownloader().updates.asBroadcastStream();

  @override
  Future<void> start() async {
    final ready = Completer<void>();
    // On Linux the plugin listens to connectivity through NetworkManager;
    // where that service is absent the listener fails asynchronously and
    // the plugin does not handle the error (doc 07, Spike S5 finding). The
    // plugin is first touched in this zone so that error is logged here.
    unawaited(
      runZonedGuarded(
        () async {
          try {
            _updates;
            // Retries and restarts of killed tasks belong to the state
            // machine and the scheduler, not the plugin.
            await FileDownloader().start(doRescheduleKilledTasks: false);
            await FileDownloader().resumeFromBackground();
            ready.complete();
          } on Object catch (error, stackTrace) {
            if (!ready.isCompleted) ready.completeError(error, stackTrace);
          }
        },
        (error, stackTrace) => _log.warning(
          'background_downloader reported an unhandled error',
          const {},
          error,
          stackTrace,
        ),
      ),
    );
    await ready.future;
  }

  @override
  Future<void> enqueue(DownloadRequest request) async {
    _reported.remove(request.taskId);
    final task = DownloadTask(
      taskId: request.taskId,
      url: request.url.toString(),
      headers: request.headers,
      baseDirectory: BaseDirectory.applicationSupport,
      directory: p.join(
        'profiles',
        request.profileId,
        request.relativeDirectory,
      ),
      filename: request.filename,
      group: request.group,
      updates: Updates.statusAndProgress,
      requiresWiFi: request.requiresWifi,
      // The state machine owns retries.
      // ignore: avoid_redundant_argument_values, stated as doc 07 does.
      retries: 0,
      // Resume Rule: transfers restart from byte zero.
      // ignore: avoid_redundant_argument_values, stated as doc 07 does.
      allowPause: false,
      priority: request.highPriority ? 0 : 5,
      metaData: request.metaData,
    );
    if (!await FileDownloader().enqueue(task)) {
      throw StateError('background_downloader refused task ${request.taskId}');
    }
  }

  /// Under the Resume Rule a transfer is never paused: it is cancelled, and
  /// the item restarts from byte zero when it runs again. Always false.
  @override
  Future<bool> pause(String taskId) async {
    await FileDownloader().cancelTaskWithId(taskId);
    return false;
  }

  /// Always false: a cancelled transfer restarts from byte zero.
  @override
  Future<bool> resume(String taskId) async => false;

  @override
  Future<void> cancel(String taskId, {bool deletePartial = false}) async {
    final task = await FileDownloader().taskForId(taskId);
    await FileDownloader().cancelTaskWithId(taskId);
    if (deletePartial && task != null) {
      final file = File(await task.filePath());
      if (file.existsSync()) await file.delete();
    }
  }

  @override
  Future<Set<String>> liveTaskIds({required String group}) async {
    final tasks = await FileDownloader().allTasks(group: group);
    return {for (final task in tasks) task.taskId};
  }

  @override
  Stream<DownloaderEvent> get events => _updates.asyncExpand(eventsOf);

  /// The events one plugin [update] stands for; the first update that
  /// carries response headers also yields a [DownloaderResponseInfo].
  @visibleForTesting
  static Stream<DownloaderEvent> eventsOf(TaskUpdate update) async* {
    final task = update.task;
    final id = task.taskId;
    final group = task.group;
    switch (update) {
      case TaskProgressUpdate(:final progress, :final expectedFileSize):
        // Negative progress values signal a final status, reported by the
        // status update.
        if (progress < 0) return;
        final expected = expectedFileSize > 0 ? expectedFileSize : null;
        yield DownloaderProgress(
          taskId: id,
          group: group,
          receivedBytes: expected == null ? 0 : (progress * expected).round(),
          expectedBytes: expected,
        );
      case TaskStatusUpdate(:final status, :final responseHeaders):
        if (responseHeaders != null && _reported.add(id)) {
          final headers = {
            for (final MapEntry(:key, :value) in responseHeaders.entries)
              key.toLowerCase(): value,
          };
          final etag = headers['etag'];
          yield DownloaderResponseInfo(
            taskId: id,
            group: group,
            etag: etag,
            isStrongEtag: isStrongEtag(etag),
            contentType: headers['content-type'],
            contentLength: int.tryParse(headers['content-length'] ?? ''),
          );
        }
        switch (status) {
          case TaskStatus.complete:
            yield DownloaderCompleted(
              taskId: id,
              group: group,
              filePath: await task.filePath(),
            );
          case TaskStatus.paused:
            yield DownloaderPaused(taskId: id, group: group);
          case TaskStatus.notFound:
            yield DownloaderFailed(
              taskId: id,
              group: group,
              kind: DownloaderFailureKind.http,
              httpStatus: 404,
            );
          case TaskStatus.canceled:
            yield DownloaderFailed(
              taskId: id,
              group: group,
              kind: DownloaderFailureKind.cancelled,
            );
          case TaskStatus.failed:
            yield _failure(id, group, update);
          case TaskStatus.enqueued ||
              TaskStatus.running ||
              TaskStatus.waitingToRetry:
            break;
        }
    }
  }

  static DownloaderFailed _failure(
    String id,
    String group,
    TaskStatusUpdate update,
  ) {
    final exception = update.exception;
    final (kind, status) = switch (exception) {
      TaskHttpException(:final httpResponseCode) => (
        DownloaderFailureKind.http,
        httpResponseCode,
      ),
      TaskConnectionException() => (DownloaderFailureKind.network, null),
      TaskFileSystemException(:final description)
          when description.toLowerCase().contains('space') =>
        (DownloaderFailureKind.noSpace, null),
      TaskFileSystemException() => (DownloaderFailureKind.fileSystem, null),
      _ when (update.responseStatusCode ?? 0) >= 400 => (
        DownloaderFailureKind.http,
        update.responseStatusCode,
      ),
      _ => (DownloaderFailureKind.unknown, null),
    };
    return DownloaderFailed(
      taskId: id,
      group: group,
      kind: kind,
      httpStatus: status,
    );
  }
}
