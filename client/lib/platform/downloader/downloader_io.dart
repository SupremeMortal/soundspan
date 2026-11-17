// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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

  /// Whether an unhandled error of the plugin has been logged.
  static bool _unhandledLogged = false;

  /// The plugin's start-up, shared by every caller: the root-scope router
  /// and each profile's scheduler start the downloader, and the plugin
  /// re-attaches and delivers background events once.
  static Future<void>? _started;

  /// The channel of `excludeFromBackup(path)`, registered by the iOS and
  /// macOS runners.
  static const MethodChannel backupChannel = MethodChannel(
    'io.soundspan.app/backup',
  );

  /// The profiles whose media directory was excluded from backup in this
  /// process.
  static final Set<String> _excludedProfiles = {};

  /// The plugin's updates. The plugin is first touched here, in a guarded
  /// zone: on Linux it listens to connectivity through NetworkManager and
  /// does not handle that listener's error where the service is absent
  /// (doc 07, Spike S5 finding), so the error is logged once here instead
  /// of reaching the caller's zone. An error thrown while creating the
  /// plugin still reaches the caller.
  static Stream<TaskUpdate> get _updates {
    final existing = _sharedUpdates;
    if (existing != null) return existing;
    Object? failure;
    StackTrace failureTrace = StackTrace.empty;
    final updates = runZonedGuarded(() {
      try {
        return FileDownloader().updates.asBroadcastStream();
      } on Object catch (error, stackTrace) {
        failure = error;
        failureTrace = stackTrace;
        return null;
      }
    }, _logUnhandled);
    if (updates == null) {
      Error.throwWithStackTrace(
        failure ?? StateError('no updates'),
        failureTrace,
      );
    }
    return _sharedUpdates = updates;
  }

  static void _logUnhandled(Object error, StackTrace stackTrace) {
    if (_unhandledLogged) return;
    _unhandledLogged = true;
    _log.warning(
      'background_downloader reported an unhandled error',
      const {},
      error,
      stackTrace,
    );
  }

  @override
  Future<void> start() =>
      _started ??= _start().catchError((Object error, StackTrace stackTrace) {
        // A failed start may be tried again.
        _started = null;
        Error.throwWithStackTrace(error, stackTrace);
      });

  Future<void> _start() async {
    final ready = Completer<void>();
    // Errors the plugin leaves unhandled while it starts, such as its
    // NetworkManager listener's on Linux (doc 07, Spike S5 finding), are
    // logged once here, like those of its creation in [_updates].
    unawaited(
      runZonedGuarded(() async {
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
      }, _logUnhandled),
    );
    await ready.future;
  }

  /// Creates the media directory of profile [profileId] under [appSupport]
  /// and excludes it from iCloud and Time Machine backups (doc 05, Files on
  /// Disk), once per profile and process. A failure is logged and tried
  /// again at the next call; the download goes ahead either way.
  @visibleForTesting
  static Future<void> excludeMediaFromBackup(
    String profileId, {
    required String appSupport,
    MethodChannel channel = backupChannel,
  }) async {
    if (!_excludedProfiles.add(profileId)) return;
    try {
      await channel.invokeMethod<void>(
        'excludeFromBackup',
        p.join(appSupport, 'profiles', profileId, 'media'),
      );
    } on Object catch (error, stackTrace) {
      _excludedProfiles.remove(profileId);
      _log.warning(
        'The media directory was not excluded from backup',
        const {},
        error,
        stackTrace,
      );
    }
  }

  @override
  Future<void> enqueue(DownloadRequest request) async {
    _reported.remove(request.taskId);
    // Android keeps profiles/ out of backups through its backup rules.
    if (Platform.isIOS || Platform.isMacOS) {
      await excludeMediaFromBackup(
        request.profileId,
        appSupport: (await getApplicationSupportDirectory()).path,
      );
    }
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
