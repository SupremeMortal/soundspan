// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/shared/providers/images.dart';
import 'package:soundspan_api/soundspan_api.dart';

void main() {
  final urls = ImageUrls(Uri.parse('https://music.example/sub'));
  const request = ArtworkRequest(
    'cover-1',
    logicalPx: 160,
    devicePixelRatio: 2,
  );
  const jwtA = JwtCredentials(accessToken: 'token-a', refreshToken: 'r');
  const jwtB = JwtCredentials(accessToken: 'token-b', refreshToken: 'r');
  const apiKey = ApiKeyCredentials(apiKey: 'key-1');

  test('the request asks for the snapped pixel size', () {
    expect(request.pixelSize, 320);
    expect(
      const ArtworkRequest('x', logicalPx: 232, devicePixelRatio: 3).pixelSize,
      768,
    );
  });

  test('cache key ignores the token', () {
    final a = artworkFetch(request, urls: urls, credentials: jwtA, isWeb: true);
    final b = artworkFetch(request, urls: urls, credentials: jwtB, isWeb: true);

    expect(a.url, isNot(b.url));
    expect(a.cacheKey, b.cacheKey);
    expect(a.cacheKey, '${sha1.convert(utf8.encode('cover-1'))}:320');
  });

  test('the cache key differs by snapped size', () {
    final small = artworkFetch(
      const ArtworkRequest('cover-1', logicalPx: 40, devicePixelRatio: 1),
      urls: urls,
      credentials: jwtA,
      isWeb: false,
    );
    final large = artworkFetch(
      request,
      urls: urls,
      credentials: jwtA,
      isWeb: false,
    );

    expect(small.cacheKey, isNot(large.cacheKey));
  });

  test('native requests carry auth headers and no token', () {
    final jwt = artworkFetch(
      request,
      urls: urls,
      credentials: jwtA,
      isWeb: false,
    );
    final key = artworkFetch(
      request,
      urls: urls,
      credentials: apiKey,
      isWeb: false,
    );

    expect(
      jwt.url,
      Uri.parse(
        'https://music.example/sub/api/library/cover-art/cover-1?size=320',
      ),
    );
    expect(jwt.headers, {'Authorization': 'Bearer token-a'});
    expect(key.headers, {'X-API-Key': 'key-1'});
    expect(key.url.queryParameters, isNot(contains('token')));
  });

  test('web requests carry the token and no auth header', () {
    final fetch = artworkFetch(
      request,
      urls: urls,
      credentials: jwtA,
      isWeb: true,
    );

    expect(fetch.url.queryParameters, {'size': '320', 'token': 'token-a'});
    expect(fetch.headers, isEmpty);
  });

  test('API-key credentials on web throw', () {
    expect(
      () => artworkFetch(request, urls: urls, credentials: apiKey, isWeb: true),
      throwsUnsupportedError,
    );
  });

  test('the memory cache is capped by device class', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final cache = PaintingBinding.instance.imageCache;
    final (bytes, count) = (cache.maximumSizeBytes, cache.maximumSize);
    addTearDown(
      () => cache
        ..maximumSizeBytes = bytes
        ..maximumSize = count,
    );

    configureImageMemoryCache(isDesktop: true);
    expect((cache.maximumSizeBytes, cache.maximumSize), (100 << 20, 300));
    configureImageMemoryCache(isDesktop: false);
    expect((cache.maximumSizeBytes, cache.maximumSize), (60 << 20, 200));
  });

  test('without credentials the request is anonymous', () {
    final fetch = artworkFetch(
      request,
      urls: urls,
      credentials: null,
      isWeb: true,
    );

    expect(fetch.headers, isEmpty);
    expect(fetch.url.queryParameters, {'size': '320'});
  });
}
