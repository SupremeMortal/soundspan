// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Artwork loading: the profile's image store and the image provider every
/// [ImageProvider] of a cover comes from (doc 05, Image Cache).
library;

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/platform/image_cache/image_cache.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// One cover at one layout size: what the artwork widget asks for.
@immutable
final class ArtworkRequest {
  /// Asks for the cover named by [ref] drawn [logicalPx] wide on a screen of
  /// [devicePixelRatio].
  const new(
    this.ref, {
    required this.logicalPx,
    required this.devicePixelRatio,
  });

  /// The server's cover value.
  final String ref;

  /// The layout width, in logical pixels.
  final double logicalPx;

  /// The device pixel ratio of the screen it is drawn on.
  final double devicePixelRatio;

  /// The server size, in pixels, snapped for `logicalPx × devicePixelRatio`.
  /// The image is requested and decoded at this width.
  int get pixelSize => snapCoverSize(logicalPx * devicePixelRatio);

  @override
  bool operator ==(Object other) =>
      other is ArtworkRequest &&
      other.ref == ref &&
      other.logicalPx == logicalPx &&
      other.devicePixelRatio == devicePixelRatio;

  @override
  int get hashCode => Object.hash(ref, logicalPx, devicePixelRatio);

  @override
  String toString() =>
      'ArtworkRequest($ref, $logicalPx × $devicePixelRatio = $pixelSize)';
}

/// How one cover is fetched: its URL, its headers and its key in the image
/// store.
@immutable
final class ArtworkFetch {
  /// Creates a fetch of [url] with [headers], stored under [cacheKey].
  const new({required this.url, required this.headers, required this.cacheKey});

  /// The cover URL; on web it carries the access token.
  final Uri url;

  /// The authentication headers; empty on web.
  final Map<String, String> headers;

  /// `sha1(ref) + ":" + pixelSize`: independent of the URL, so a rotated
  /// token does not miss the store.
  final String cacheKey;
}

/// The key of the cover [ref] at [pixelSize] in the image store.
String artworkCacheKey(String ref, int pixelSize) =>
    '${sha1.convert(utf8.encode(ref))}:$pixelSize';

/// How [request] is fetched from the server of [urls] with [credentials].
///
/// Native targets send [authHeaders]; web ([isWeb]) cannot set headers on
/// an image, so the URL carries the JWT as `?token=` and API-key credentials
/// throw an [UnsupportedError]. Without credentials the request is
/// anonymous.
ArtworkFetch artworkFetch(
  ArtworkRequest request, {
  required ImageUrls urls,
  required Credentials? credentials,
  required bool isWeb,
}) {
  final cover = urls.cover(
    request.ref,
    logicalPx: request.logicalPx,
    devicePixelRatio: request.devicePixelRatio,
  );
  final cacheKey = artworkCacheKey(request.ref, request.pixelSize);
  if (credentials == null) {
    return ArtworkFetch(url: cover, headers: const {}, cacheKey: cacheKey);
  }
  if (!isWeb) {
    return ArtworkFetch(
      url: cover,
      headers: authHeaders(credentials),
      cacheKey: cacheKey,
    );
  }
  return switch (credentials) {
    JwtCredentials() => ArtworkFetch(
      url: withQueryToken(cover, credentials),
      headers: const {},
      cacheKey: cacheKey,
    ),
    ApiKeyCredentials() => throw UnsupportedError(
      'API-key credentials cannot load images on web',
    ),
  };
}

/// The image store of the profile scope, closed when the profile scope ends.
final Provider<BaseCacheManager> imageCacheManagerProvider =
    Provider<BaseCacheManager>((ref) {
      final context = ref.watch(profileContextProvider);
      final manager = createImageCacheManager(
        profileId: context.profile.id,
        directory: context.paths?.images,
      );
      ref.watch(profileDisposerProvider).register(manager.dispose);
      return manager;
    }, dependencies: [profileContextProvider, profileDisposerProvider]);

/// Builds the [ImageProvider] of one [ArtworkRequest].
typedef ArtworkImageProviderFactory = ImageProvider Function(ArtworkRequest);

/// The [ImageProvider] factory of the profile scope: a
/// [CachedNetworkImageProvider] over [imageCacheManagerProvider], fetched as
/// [artworkFetch] says with the session's current credentials.
///
/// Only `Artwork` reads it. Tests override it with a placeholder.
final Provider<ArtworkImageProviderFactory> artworkImageProvider =
    Provider<ArtworkImageProviderFactory>(
      (ref) {
        final urls = ImageUrls(ref.watch(apiConfigProvider).baseUrl);
        final manager = ref.watch(imageCacheManagerProvider);
        final session = ref.watch(sessionControllerProvider);
        return (request) {
          final fetch = artworkFetch(
            request,
            urls: urls,
            credentials: session.current,
            isWeb: kIsWeb,
          );
          return CachedNetworkImageProvider(
            fetch.url.toString(),
            headers: fetch.headers,
            cacheKey: fetch.cacheKey,
            cacheManager: manager,
          );
        };
      },
      dependencies: [
        apiConfigProvider,
        imageCacheManagerProvider,
        sessionControllerProvider,
      ],
    );

/// Caps the decoded-image memory cache: 100 MB and 300 images on desktop,
/// 60 MB and 200 images on mobile and web.
void configureImageMemoryCache({required bool isDesktop}) {
  PaintingBinding.instance.imageCache
    ..maximumSizeBytes = (isDesktop ? 100 : 60) << 20
    ..maximumSize = isDesktop ? 300 : 200;
}
