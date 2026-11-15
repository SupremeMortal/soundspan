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

/// Builds the URLs that players and the downloader fetch audio from (doc
/// 03, URL Builders). Audio is never requested through a generated method.
final class StreamUrls {
  /// Creates a builder for [baseUrl], the normalized server base URL; a
  /// path prefix is kept.
  new(this.baseUrl);

  /// The server base URL, without a trailing slash.
  final Uri baseUrl;

  /// The stream of the track [playbackId], which is one opaque path segment
  /// and never inspected.
  ///
  /// [quality] null means the server default and adds no parameter. Unless
  /// [reportPlay] is true the URL carries `report=0`, so the server records
  /// no play for the request (P7).
  Uri track(String playbackId, {String? quality, bool reportPlay = false}) {
    final query = Uri(
      queryParameters: {'quality': ?quality, if (!reportPlay) 'report': '0'},
    ).query;
    final path =
        '$baseUrl/api/playback/stream/'
        '${Uri.encodeComponent(playbackId)}';
    return Uri.parse(query.isEmpty ? path : '$path?$query');
  }

  /// The stream of episode [episodeId] of podcast [podcastId].
  Uri episode(String podcastId, String episodeId) => Uri.parse(
    '$baseUrl/api/podcasts/${Uri.encodeComponent(podcastId)}/episodes/'
    '${Uri.encodeComponent(episodeId)}/stream',
  );

  /// Resolves a server-provided relative URL such as an offline
  /// `downloadUrl` against the base, path prefix included.
  ///
  /// Throws [ArgumentError] when [serverRelative] does not start with
  /// `/api/`.
  Uri resolve(String serverRelative) {
    if (!serverRelative.startsWith('/api/')) {
      throw ArgumentError.value(
        serverRelative,
        'serverRelative',
        'must start with /api/',
      );
    }
    return Uri.parse('$baseUrl$serverRelative');
  }

  /// The headers that authenticate a stream request; see the top-level
  /// [authHeaders]. The headers are always returned; leaving them out on
  /// web is up to the caller.
  Map<String, String> authHeaders(Credentials credentials) =>
      _authHeaders(credentials);

  /// [uri] with the access token of [credentials] as the `token` query
  /// parameter; see the top-level [withQueryToken].
  Uri withQueryToken(Uri uri, JwtCredentials credentials) =>
      _withQueryToken(uri, credentials);
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
    _authHeaders(credentials);

Map<String, String> _authHeaders(Credentials credentials) =>
    switch (credentials) {
      ApiKeyCredentials(:final apiKey) => {'X-API-Key': apiKey},
      JwtCredentials(:final accessToken) => {
        'Authorization': 'Bearer $accessToken',
      },
    };

/// [uri] with the access token of [credentials] added as the `token` query
/// parameter, for web playback and images where headers cannot be set;
/// existing parameters are kept.
Uri withQueryToken(Uri uri, JwtCredentials credentials) =>
    _withQueryToken(uri, credentials);

Uri _withQueryToken(Uri uri, JwtCredentials credentials) => uri.replace(
  queryParameters: {...uri.queryParameters, 'token': credentials.accessToken},
);
