// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

void main() {
  _streamUrlsTests();

  final urls = ImageUrls(Uri.parse('https://music.example.org'));

  String sizeOf(double logicalPx, double devicePixelRatio) => urls
      .cover('abc', logicalPx: logicalPx, devicePixelRatio: devicePixelRatio)
      .queryParameters['size']!;

  group('ImageUrls.cover size', () {
    test('snaps up to the server sizes', () {
      expect(sizeOf(1, 1), '64');
      expect(sizeOf(64, 1), '64');
      expect(sizeOf(65, 1), '128');
      expect(sizeOf(160, 2), '320');
      expect(sizeOf(232, 3), '768');
      expect(sizeOf(2000, 1), '768');
    });

    test('covers every step', () {
      expect(sizeOf(129, 1), '192');
      expect(sizeOf(193, 1), '320');
      expect(sizeOf(321, 1), '512');
      expect(sizeOf(513, 1), '768');
    });
  });

  group('ImageUrls.cover cases', () {
    test('an id or hash is a path segment with a size', () {
      final uri = urls.cover('a1b2c3', logicalPx: 48, devicePixelRatio: 2);
      expect(
        uri.toString(),
        'https://music.example.org/api/library/cover-art/a1b2c3?size=128',
      );
    });

    test('an http(s) URL is passed as the url parameter with a size', () {
      final https = urls.cover(
        'https://img.example.com/a.jpg?w=1&h=2',
        logicalPx: 64,
        devicePixelRatio: 1,
      );
      expect(https.path, '/api/library/cover-art');
      expect(https.queryParameters, {
        'url': 'https://img.example.com/a.jpg?w=1&h=2',
        'size': '64',
      });

      final http = urls.cover(
        'http://img.example.com/b.png',
        logicalPx: 64,
        devicePixelRatio: 1,
      );
      expect(http.path, '/api/library/cover-art');
      expect(http.queryParameters['url'], 'http://img.example.com/b.png');
    });

    test('a podcast or audiobook path is served under /api without a size', () {
      final podcast = urls.cover(
        '/podcasts/p1/cover',
        logicalPx: 64,
        devicePixelRatio: 1,
      );
      expect(
        podcast.toString(),
        'https://music.example.org/api/podcasts/p1/cover',
      );

      final audiobook = urls.cover(
        '/audiobooks/b1/cover',
        logicalPx: 64,
        devicePixelRatio: 1,
      );
      expect(
        audiobook.toString(),
        'https://music.example.org/api/audiobooks/b1/cover',
      );
    });

    test('a ref that needs percent-encoding is one encoded segment', () {
      final uri = urls.cover(
        'native:albums/a b#1?.jpg',
        logicalPx: 64,
        devicePixelRatio: 1,
      );
      expect(uri.pathSegments, [
        'api',
        'library',
        'cover-art',
        'native:albums/a b#1?.jpg',
      ]);
      expect(
        uri.toString(),
        'https://music.example.org/api/library/cover-art/'
        'native%3Aalbums%2Fa%20b%231%3F.jpg?size=64',
      );
    });

    test('a base with a path prefix keeps the prefix', () {
      final prefixed = ImageUrls(Uri.parse('http://10.0.0.2:3030/soundspan'));
      expect(
        prefixed.cover('abc', logicalPx: 64, devicePixelRatio: 1).toString(),
        'http://10.0.0.2:3030/soundspan/api/library/cover-art/abc?size=64',
      );
      expect(
        prefixed
            .cover('https://x.test/a.jpg', logicalPx: 64, devicePixelRatio: 1)
            .path,
        '/soundspan/api/library/cover-art',
      );
      expect(
        prefixed
            .cover('/podcasts/p1/cover', logicalPx: 64, devicePixelRatio: 1)
            .toString(),
        'http://10.0.0.2:3030/soundspan/api/podcasts/p1/cover',
      );
    });
  });

  group('authHeaders', () {
    test('an API key is sent as X-API-Key', () {
      expect(authHeaders(const ApiKeyCredentials(apiKey: 'k1')), {
        'X-API-Key': 'k1',
      });
    });

    test('a JWT session is sent as a bearer token', () {
      expect(
        authHeaders(
          const JwtCredentials(accessToken: 'a1', refreshToken: 'r1'),
        ),
        {'Authorization': 'Bearer a1'},
      );
    });
  });

  group('withQueryToken', () {
    const jwt = JwtCredentials(accessToken: 'a.b.c', refreshToken: 'r1');

    test('adds the access token as token', () {
      final uri = withQueryToken(
        Uri.parse('https://h/api/library/cover-art/abc'),
        jwt,
      );
      expect(uri.queryParameters, {'token': 'a.b.c'});
      expect(uri.path, '/api/library/cover-art/abc');
    });

    test('keeps existing parameters', () {
      final uri = withQueryToken(
        Uri.parse(
          'https://h/api/library/cover-art?url=https%3A%2F%2Fx&size=64',
        ),
        jwt,
      );
      expect(uri.queryParameters, {
        'url': 'https://x',
        'size': '64',
        'token': 'a.b.c',
      });
    });
  });
}

void _streamUrlsTests() {
  final urls = StreamUrls(Uri.parse('https://music.example.org'));
  final prefixed = StreamUrls(Uri.parse('https://example.com/soundspan'));

  group('StreamUrls.track', () {
    test('without quality carries only report=0', () {
      expect(
        urls.track('abc').toString(),
        'https://music.example.org/api/playback/stream/abc?report=0',
      );
    });

    test('with quality adds it beside report=0', () {
      final uri = urls.track('abc', quality: 'high');

      expect(uri.path, '/api/playback/stream/abc');
      expect(uri.queryParameters, {'quality': 'high', 'report': '0'});
    });

    test('reportPlay: true leaves report out', () {
      expect(
        urls.track('abc', reportPlay: true).toString(),
        'https://music.example.org/api/playback/stream/abc',
      );
      expect(
        urls.track('abc', quality: 'low', reportPlay: true).queryParameters,
        {'quality': 'low'},
      );
    });

    test('an id with /, :, ? and spaces is one encoded segment', () {
      final uri = urls.track('a/b:c?d e');

      expect(uri.pathSegments, ['api', 'playback', 'stream', 'a/b:c?d e']);
      expect(
        uri.toString(),
        'https://music.example.org/api/playback/stream/'
        'a%2Fb%3Ac%3Fd%20e?report=0',
      );
    });

    test('a base with a path prefix keeps the prefix', () {
      expect(
        prefixed.track('abc').toString(),
        'https://example.com/soundspan/api/playback/stream/abc?report=0',
      );
    });
  });

  test('StreamUrls.episode', () {
    expect(
      prefixed.episode('pod 1', 'ep/2').toString(),
      'https://example.com/soundspan/api/podcasts/pod%201/episodes/ep%2F2/'
      'stream',
    );
  });

  group('StreamUrls.resolve', () {
    test('resolves against the base', () {
      expect(
        urls.resolve('/api/playback/stream/abc?quality=high&report=0'),
        Uri.parse(
          'https://music.example.org/api/playback/stream/abc?quality=high&'
          'report=0',
        ),
      );
    });

    test('keeps the path prefix of the base', () {
      expect(
        prefixed.resolve('/api/playback/stream/abc?report=0').toString(),
        'https://example.com/soundspan/api/playback/stream/abc?report=0',
      );
    });

    test('rejects a value that does not start with /api/', () {
      expect(
        () => urls.resolve('https://other.example/x'),
        throwsArgumentError,
      );
      expect(() => urls.resolve('/other'), throwsArgumentError);
      expect(
        () => prefixed.resolve('//other.example/api/x'),
        throwsArgumentError,
      );
    });
  });

  group('StreamUrls.authHeaders', () {
    test('an API key is sent as X-API-Key', () {
      expect(urls.authHeaders(const ApiKeyCredentials(apiKey: 'k')), {
        'X-API-Key': 'k',
      });
    });

    test('a JWT session is sent as a bearer token', () {
      expect(
        urls.authHeaders(
          const JwtCredentials(accessToken: 'a', refreshToken: 'r'),
        ),
        {'Authorization': 'Bearer a'},
      );
    });
  });

  test('StreamUrls.withQueryToken keeps existing parameters', () {
    final uri = urls.withQueryToken(
      urls.track('abc', quality: 'high'),
      const JwtCredentials(accessToken: 'a', refreshToken: 'r'),
    );

    expect(uri.queryParameters, {
      'quality': 'high',
      'report': '0',
      'token': 'a',
    });
  });
}
