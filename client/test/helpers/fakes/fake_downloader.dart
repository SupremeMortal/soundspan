// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:soundspan/platform/downloader/downloader.dart';

/// A [Downloader] driven by the test (doc 11, Test Doubles).
///
/// It records every request and emits progress, completion and failures
/// on demand. Completions write a real file of the scripted size at the
/// requested path under [appSupport], laid out like the native downloader:
/// `<appSupport>/profiles/<profileId>/<relativeDirectory>/<filename>`.
final class FakeDownloader implements Downloader {
  /// Creates a fake rooted in [appSupport], usually a temporary directory.
  new({required this.appSupport});

  /// The directory standing in for the application support directory.
  final String appSupport;

  /// Whether [pause] pauses (true) or, as the Resume Rule says, cancels
  /// and asks for a restart from byte zero (false, the default).
  bool pauseResumable = false;

  /// Every request passed to [enqueue], oldest first.
  final List<DownloadRequest> requests = [];

  /// Every task id passed to [cancel], oldest first.
  final List<String> cancelled = [];

  /// How many times [start] ran.
  int startCount = 0;

  /// When set, [start] throws it, as the native downloader does when it
  /// cannot initialise.
  Exception? startError;

  final _live = <String, DownloadRequest>{};
  final _known = <String, DownloadRequest>{};
  final _events = StreamController<DownloaderEvent>.broadcast(sync: true);

  @override
  Future<void> start() async {
    startCount++;
    final error = startError;
    if (error != null) throw error;
  }

  @override
  Future<void> enqueue(DownloadRequest request) async {
    requests.add(request);
    _live[request.taskId] = request;
    _known[request.taskId] = request;
  }

  @override
  Future<bool> pause(String taskId) async {
    final request = _request(taskId);
    if (pauseResumable) {
      _events.add(DownloaderPaused(taskId: taskId, group: request.group));
      return true;
    }
    _live.remove(taskId);
    _events.add(
      DownloaderFailed(
        taskId: taskId,
        group: request.group,
        kind: DownloaderFailureKind.cancelled,
      ),
    );
    return false;
  }

  @override
  Future<bool> resume(String taskId) async => pauseResumable;

  @override
  Future<void> cancel(String taskId, {bool deletePartial = false}) async {
    cancelled.add(taskId);
    _live.remove(taskId);
    if (deletePartial && _known.containsKey(taskId)) {
      final file = File(pathOf(taskId));
      if (file.existsSync()) file.deleteSync();
    }
  }

  @override
  Future<Set<String>> liveTaskIds({required String group}) async => {
    for (final request in _live.values)
      if (request.group == group) request.taskId,
  };

  @override
  Stream<DownloaderEvent> get events => _events.stream;

  /// The absolute path a completion of [taskId] writes to.
  String pathOf(String taskId) {
    final request = _request(taskId);
    return p.join(
      appSupport,
      'profiles',
      request.profileId,
      request.relativeDirectory,
      request.filename,
    );
  }

  /// Emits a [DownloaderProgress] for [taskId].
  void emitProgress(
    String taskId, {
    required int receivedBytes,
    int? expectedBytes,
  }) => _events.add(
    DownloaderProgress(
      taskId: taskId,
      group: _request(taskId).group,
      receivedBytes: receivedBytes,
      expectedBytes: expectedBytes,
    ),
  );

  /// Writes [bytes] bytes to the task's file, emits the response info and
  /// [DownloaderCompleted], and returns the file's path.
  Future<String> complete(
    String taskId, {
    required int bytes,
    String? etag,
    String? contentType,
    int? contentLength,
  }) async {
    final request = _request(taskId);
    final path = pathOf(taskId);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(List<int>.filled(bytes, 0x5a));
    _live.remove(taskId);
    _events
      ..add(
        DownloaderResponseInfo(
          taskId: taskId,
          group: request.group,
          etag: etag,
          isStrongEtag: isStrongEtag(etag),
          contentType: contentType,
          contentLength: contentLength,
        ),
      )
      ..add(
        DownloaderCompleted(
          taskId: taskId,
          group: request.group,
          filePath: path,
        ),
      );
    return path;
  }

  /// Completes [taskId] with a file of [bytes] bytes while the response
  /// announced [contentLength], which is larger.
  Future<String> completeTruncated(
    String taskId, {
    required int bytes,
    required int contentLength,
    String? etag,
    String? contentType,
  }) {
    if (bytes >= contentLength) {
      throw ArgumentError.value(bytes, 'bytes', 'must be below $contentLength');
    }
    return complete(
      taskId,
      bytes: bytes,
      etag: etag,
      contentType: contentType,
      contentLength: contentLength,
    );
  }

  /// Ends [taskId] with a [DownloaderFailed] of [kind] and [httpStatus].
  void fail(
    String taskId, {
    required DownloaderFailureKind kind,
    int? httpStatus,
  }) {
    final request = _request(taskId);
    _live.remove(taskId);
    _events.add(
      DownloaderFailed(
        taskId: taskId,
        group: request.group,
        kind: kind,
        httpStatus: httpStatus,
      ),
    );
  }

  /// Forgets [taskId] without an event, as when the operating system lost
  /// it while the app was dead: [liveTaskIds] no longer lists it.
  void dropTask(String taskId) => _live.remove(taskId);

  /// Closes the event stream.
  Future<void> dispose() => _events.close();

  DownloadRequest _request(String taskId) =>
      _known[taskId] ?? (throw StateError('no request for task $taskId'));
}
