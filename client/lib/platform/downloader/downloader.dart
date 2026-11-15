// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The downloader seam: hands audio file transfers to the operating system
/// (doc 02, Platform Seams; doc 07, Transfers).
///
/// Native targets use `background_downloader`; on web there are no
/// downloads (`PlatformCapabilities.canDownload` is false) and every method
/// of the web implementation throws [UnsupportedError].
///
/// Resume Rule (doc 07): a paused or interrupted transfer is cancelled and
/// restarts from byte zero, so [Downloader.pause] and [Downloader.resume]
/// of the native implementation always return false.
library;

import 'package:flutter/foundation.dart' show immutable, mapEquals;

export 'downloader_web.dart'
    if (dart.library.io) 'downloader_io.dart'
    show createDownloader;

/// The transfer group of profile [profileId]: `p:<profileId>`.
String downloaderGroup(String profileId) => 'p:$profileId';

/// Transfers files in the background, outside the app's HTTP client.
abstract interface class Downloader {
  /// Re-attaches to OS tasks and delivers events that arrived while the app
  /// was dead.
  Future<void> start();

  /// Hands [request] to the operating system. Enqueueing a task id that is
  /// already live is idempotent.
  Future<void> enqueue(DownloadRequest request);

  /// Pauses when the transfer may be resumed under the resume rule;
  /// otherwise cancels and keeps the `.part` file. Returns true when paused.
  Future<bool> pause(String taskId);

  /// Resumes a paused task. Returns false when it must be restarted from
  /// byte zero.
  Future<bool> resume(String taskId);

  /// Cancels [taskId]; with [deletePartial] its `.part` file is deleted.
  Future<void> cancel(String taskId, {bool deletePartial = false});

  /// The ids of the tasks of [group] the operating system still holds:
  /// queued, running or waiting to retry.
  Future<Set<String>> liveTaskIds({required String group});

  /// Every task's progress, first response and outcome.
  Stream<DownloaderEvent> get events;
}

/// One transfer to hand to the [Downloader] (doc 07, Transfers).
@immutable
final class DownloadRequest {
  /// Creates a request; every field is required.
  const new({
    required this.taskId,
    required this.url,
    required this.headers,
    required this.profileId,
    required this.relativeDirectory,
    required this.filename,
    required this.requiresWifi,
    required this.highPriority,
    required this.metaData,
  });

  /// The task id: the item's `itemKeyHash`, so re-enqueueing is idempotent.
  final String taskId;

  /// The absolute URL to fetch.
  final Uri url;

  /// The headers that authenticate the request.
  final Map<String, String> headers;

  /// The profile the file belongs to.
  final String profileId;

  /// The file's directory, relative to the profile directory, such as
  /// `media/ab`.
  final String relativeDirectory;

  /// The file name, such as `<hash>.part`.
  final String filename;

  /// Whether the transfer may only run on Wi-Fi.
  final bool requiresWifi;

  /// Whether the user started this download, so the platform runs it
  /// first where it can.
  final bool highPriority;

  /// The encoded item key, carried back by the platform's task record.
  final String metaData;

  /// The transfer group of [profileId].
  String get group => downloaderGroup(profileId);

  @override
  bool operator ==(Object other) =>
      other is DownloadRequest &&
      other.taskId == taskId &&
      other.url == url &&
      mapEquals(other.headers, headers) &&
      other.profileId == profileId &&
      other.relativeDirectory == relativeDirectory &&
      other.filename == filename &&
      other.requiresWifi == requiresWifi &&
      other.highPriority == highPriority &&
      other.metaData == metaData;

  @override
  int get hashCode => Object.hash(
    taskId,
    url,
    Object.hashAllUnordered(
      headers.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    profileId,
    relativeDirectory,
    filename,
    requiresWifi,
    highPriority,
    metaData,
  );

  @override
  String toString() =>
      'DownloadRequest($taskId, $profileId/$relativeDirectory/$filename)';
}

/// Why a transfer failed.
enum DownloaderFailureKind {
  /// The connection failed or was lost.
  network,

  /// The server answered with an error status; see
  /// [DownloaderFailed.httpStatus].
  http,

  /// The file could not be written.
  fileSystem,

  /// The device has no room for the file.
  noSpace,

  /// The task was cancelled.
  cancelled,

  /// Anything else.
  unknown,
}

/// Something that happened to one transfer.
@immutable
sealed class DownloaderEvent {
  const new({required this.taskId, required this.group});

  /// The task it happened to.
  final String taskId;

  /// The task's transfer group.
  final String group;
}

/// Bytes arrived.
final class DownloaderProgress extends DownloaderEvent {
  /// Creates a progress event.
  const new({
    required super.taskId,
    required super.group,
    required this.receivedBytes,
    this.expectedBytes,
  });

  /// Bytes received so far.
  final int receivedBytes;

  /// The total size, when known.
  final int? expectedBytes;

  @override
  bool operator ==(Object other) =>
      other is DownloaderProgress &&
      other.taskId == taskId &&
      other.group == group &&
      other.receivedBytes == receivedBytes &&
      other.expectedBytes == expectedBytes;

  @override
  int get hashCode => Object.hash(taskId, group, receivedBytes, expectedBytes);

  @override
  String toString() =>
      'DownloaderProgress($taskId, $receivedBytes/$expectedBytes)';
}

/// What the first response of a task said about the file; emitted once
/// per transfer.
final class DownloaderResponseInfo extends DownloaderEvent {
  /// Creates a response-info event.
  const new({
    required super.taskId,
    required super.group,
    required this.isStrongEtag,
    this.etag,
    this.contentType,
    this.contentLength,
  });

  /// The response's `ETag`, as sent.
  final String? etag;

  /// Whether [etag] is present and not weak (`W/`).
  final bool isStrongEtag;

  /// The response's `Content-Type`.
  final String? contentType;

  /// The response's `Content-Length`.
  final int? contentLength;

  @override
  bool operator ==(Object other) =>
      other is DownloaderResponseInfo &&
      other.taskId == taskId &&
      other.group == group &&
      other.etag == etag &&
      other.isStrongEtag == isStrongEtag &&
      other.contentType == contentType &&
      other.contentLength == contentLength;

  @override
  int get hashCode => Object.hash(
    taskId,
    group,
    etag,
    isStrongEtag,
    contentType,
    contentLength,
  );

  @override
  String toString() =>
      'DownloaderResponseInfo($taskId, etag: $etag, '
      'type: $contentType, length: $contentLength)';
}

/// The whole file is on disk at [filePath].
final class DownloaderCompleted extends DownloaderEvent {
  /// Creates a completion event.
  const new({
    required super.taskId,
    required super.group,
    required this.filePath,
  });

  /// The absolute path of the downloaded file.
  final String filePath;

  @override
  bool operator ==(Object other) =>
      other is DownloaderCompleted &&
      other.taskId == taskId &&
      other.group == group &&
      other.filePath == filePath;

  @override
  int get hashCode => Object.hash(taskId, group, filePath);

  @override
  String toString() => 'DownloaderCompleted($taskId, $filePath)';
}

/// The transfer is paused and may be resumed.
final class DownloaderPaused extends DownloaderEvent {
  /// Creates a paused event.
  const new({required super.taskId, required super.group});

  @override
  bool operator ==(Object other) =>
      other is DownloaderPaused &&
      other.taskId == taskId &&
      other.group == group;

  @override
  int get hashCode => Object.hash(taskId, group);

  @override
  String toString() => 'DownloaderPaused($taskId)';
}

/// The transfer ended without the file.
final class DownloaderFailed extends DownloaderEvent {
  /// Creates a failure event.
  const new({
    required super.taskId,
    required super.group,
    required this.kind,
    this.httpStatus,
  });

  /// Why it failed.
  final DownloaderFailureKind kind;

  /// The server's status for [DownloaderFailureKind.http].
  final int? httpStatus;

  @override
  bool operator ==(Object other) =>
      other is DownloaderFailed &&
      other.taskId == taskId &&
      other.group == group &&
      other.kind == kind &&
      other.httpStatus == httpStatus;

  @override
  int get hashCode => Object.hash(taskId, group, kind, httpStatus);

  @override
  String toString() => 'DownloaderFailed($taskId, ${kind.name}, $httpStatus)';
}

/// Whether [etag] is a strong entity tag: present and without the `W/`
/// prefix.
bool isStrongEtag(String? etag) =>
    etag != null && etag.isNotEmpty && !etag.startsWith('W/');
