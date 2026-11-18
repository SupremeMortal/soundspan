// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:path/path.dart' as p;
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/storage/artwork_fetcher.dart';
import 'package:soundspan/platform/artwork_store/artwork_store.dart';
import 'package:soundspan_api/soundspan_api.dart';

export 'package:soundspan/core/storage/artwork_fetcher.dart'
    show ArtworkBytesFetcher;

/// Gives the OS media surface an artwork URI it can load without
/// credentials (doc 06, OS Media Controls).
///
/// On native targets the 512-pixel cover is fetched through the image cache
/// and written to `profiles/<id>/art/now-playing.img`, whose `file://` URI
/// is returned. On web, which has no files, the cover URL carrying the
/// access token is returned instead. A missing cover value or a failure
/// gives null.
final class ArtworkPinner {
  /// Creates the pinner of a profile whose covers come from [_urls] with
  /// the [_credentials] of the moment, fetched by [_fetch] and written by
  /// [_store] under [_artDirectory] (null on web). [_isWeb] picks the web
  /// path.
  new({
    required this._urls,
    required this._credentials,
    required this._fetch,
    required this._store,
    required this._artDirectory,
    required this._isWeb,
  });

  /// The pixel size of the pinned cover.
  static const int pixelSize = localArtworkPixelSize;

  /// The file name of the pinned cover under the profile's `art/`.
  static const String fileName = 'now-playing.img';

  static final AppLogger _log = AppLogger.scope('MediaControls');

  final ImageUrls _urls;
  final Credentials? Function() _credentials;
  final ArtworkBytesFetcher _fetch;
  final ArtworkStore _store;
  final String? _artDirectory;
  final bool _isWeb;

  /// The artwork URI of the cover [artworkRef], or null.
  Future<Uri?> pin(String? artworkRef) async {
    if (artworkRef == null) return null;
    try {
      if (_isWeb) {
        return localArtworkFetch(
          artworkRef,
          urls: _urls,
          credentials: _credentials(),
          isWeb: true,
        ).url;
      }
      final directory = _artDirectory;
      if (directory == null) return null;
      return await fetchAndStoreArtwork(
        artworkRef,
        path: p.join(directory, fileName),
        urls: _urls,
        credentials: _credentials(),
        fetch: _fetch,
        store: _store,
      );
    } on Object catch (error, stackTrace) {
      _log.warning('Artwork was not pinned', const {}, error, stackTrace);
      return null;
    }
  }
}
