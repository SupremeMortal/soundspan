// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/downloader/downloader.dart';

/// The [Downloader] of the web app, where downloads are hidden.
Downloader createDownloader() => const UnsupportedDownloader();

/// The web [Downloader]: there are no downloads on web, so every method
/// throws [UnsupportedError].
final class UnsupportedDownloader implements Downloader {
  /// Creates the unsupported downloader.
  const new();

  static Never _unsupported() =>
      throw UnsupportedError('downloads are not available on web');

  @override
  Future<void> start() => _unsupported();

  @override
  Future<void> enqueue(DownloadRequest request) => _unsupported();

  @override
  Future<bool> pause(String taskId) => _unsupported();

  @override
  Future<bool> resume(String taskId) => _unsupported();

  @override
  Future<void> cancel(String taskId, {bool deletePartial = false}) =>
      _unsupported();

  @override
  Future<Set<String>> liveTaskIds({required String group}) => _unsupported();

  @override
  Stream<DownloaderEvent> get events => _unsupported();
}
