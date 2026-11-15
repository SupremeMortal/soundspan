// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan_api/src/config.dart';

/// The cover-art sizes the server snaps to, in pixels (doc 03, Server
/// Behaviour This Relies On).
const List<int> coverArtSizes = [64, 128, 192, 320, 512, 768];

/// Builds cover-art URLs the way the web client does (doc 03, URL Builders).
final class ImageUrls {
  /// Creates a builder for [baseUrl], the normalized server base URL; a
  /// path prefix is kept.
  new(this.baseUrl);

  /// The server base URL, without a trailing slash.
  final Uri baseUrl;

  /// The URL of the cover named by [ref], the server's cover value: an id
  /// or hash, an absolute `http(s)://` URL, or a `/podcasts/` or
  /// `/audiobooks/` path.
  ///
  /// `logicalPx * devicePixelRatio` is rounded up to the next server size,
  /// 768 at most. Podcast and audiobook paths carry no size.
  Uri cover(
    String ref, {
    required double logicalPx,
    required double devicePixelRatio,
  }) {
    final base = baseUrl.toString();
    if (ref.startsWith('/podcasts/') || ref.startsWith('/audiobooks/')) {
      return Uri.parse('$base/api$ref');
    }
    final size = snapCoverSize(logicalPx * devicePixelRatio);
    if (ref.startsWith('http://') || ref.startsWith('https://')) {
      final query = Uri(queryParameters: {'url': ref, 'size': '$size'}).query;
      return Uri.parse('$base/api/library/cover-art?$query');
    }
    return Uri.parse(
      '$base/api/library/cover-art/${Uri.encodeComponent(ref)}?size=$size',
    );
  }
}

/// [physicalPx] rounded up to the next size in [coverArtSizes]; the largest
/// size above that.
int snapCoverSize(double physicalPx) {
  for (final size in coverArtSizes) {
    if (physicalPx <= size) return size;
  }
  return coverArtSizes.last;
}

/// The headers that authenticate a request made outside the transport, such
/// as by an image cache or a native player: `X-API-Key` for an API key,
/// `Authorization: Bearer` for a JWT session.
Map<String, String> authHeaders(Credentials credentials) =>
    switch (credentials) {
      ApiKeyCredentials(:final apiKey) => {'X-API-Key': apiKey},
      JwtCredentials(:final accessToken) => {
        'Authorization': 'Bearer $accessToken',
      },
    };

/// [uri] with the access token of [credentials] added as the `token` query
/// parameter, for web playback and images where headers cannot be set;
/// existing parameters are kept.
Uri withQueryToken(Uri uri, JwtCredentials credentials) => uri.replace(
  queryParameters: {...uri.queryParameters, 'token': credentials.accessToken},
);
