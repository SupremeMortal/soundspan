// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:path/path.dart' as p;
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/downloader/downloader.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// The lifetime a JWT must have left when a download is enqueued: its
/// headers are fixed for the life of the task (doc 07, Credentials in
/// queued tasks).
const downloadCredentialMinRemaining = Duration(hours: 12);

/// Returns a credential with at least `minRemaining` of lifetime left;
/// `SessionController.ensureFresh` in the app.
typedef EnsureFreshDownloadCredentials = Future<Credentials> Function({
  required Duration minRemaining,
});

/// Turns a queued `download_items` row into the [DownloadRequest] the
/// [Downloader] runs (doc 07, Transfers).
class DownloadRequestBuilder {
  /// Creates the builder of one profile.
  ///
  /// `currentCredentials` returns the profile's credential without
  /// renewing it; `ensureFresh` is `SessionController.ensureFresh`.
  new({
    required this._paths,
    required this._urls,
    required this._currentCredentials,
    required this._ensureFresh,
  });

  final DownloadPaths _paths;
  final StreamUrls _urls;
  final Credentials? Function() _currentCredentials;
  final EnsureFreshDownloadCredentials _ensureFresh;

  /// The request that downloads [item] to its `.part` file.
  ///
  /// A JWT session is renewed first when it has less than
  /// [downloadCredentialMinRemaining] left; an API key is used as is. The
  /// server-built `downloadUrl` is resolved against the base URL and its
  /// query string is kept unchanged.
  ///
  /// Throws [StateError] when [item] has no `downloadUrl`, and what
  /// `ensureFresh` throws when no usable credential can be had.
  Future<DownloadRequest> build(
    DownloadItem item, {
    required bool wifiOnly,
    required bool userInitiated,
  }) async {
    final downloadUrl = item.downloadUrl;
    if (downloadUrl == null) {
      throw StateError('download item ${item.itemKey} has no downloadUrl');
    }
    final credentials = switch (_currentCredentials()) {
      final ApiKeyCredentials key => key,
      _ => await _ensureFresh(minRemaining: downloadCredentialMinRemaining),
    };
    final hash = itemKeyHash(DownloadItemKey.decode(item.itemKey));
    final part = _paths.relativePartFile(hash);
    return DownloadRequest(
      taskId: hash,
      url: _urls.resolve(downloadUrl),
      headers: _urls.authHeaders(credentials),
      profileId: _paths.profile.profileId,
      relativeDirectory: p.dirname(part),
      filename: p.basename(part),
      requiresWifi: wifiOnly,
      highPriority: userInitiated,
      metaData: item.itemKey,
    );
  }
}
