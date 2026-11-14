// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Spike S8: does swagger_parser generate correct freezed models and retrofit
// clients from the committed client-surface spec? One test per question 2 to 8
// of the spike (question 1 is the pipeline itself).

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:spike_s8/src/closed/closed_rest_client.dart' as closed;
import 'package:spike_s8/src/generated/soundspan_rest_client.dart';
import 'package:test/test.dart';

const _specPath = '../../packages/soundspan_api/openapi/soundspan-client.json';

Map<String, Object?> _sample(String name) =>
    jsonDecode(File('test/samples/$name.json').readAsStringSync())
        as Map<String, Object?>;

Map<String, Object?> _spec() =>
    jsonDecode(File(_specPath).readAsStringSync()) as Map<String, Object?>;

/// Every operation in the spec: operationId -> (method, path, tag).
Map<String, ({String method, String path, String tag})> _operations() {
  final paths = _spec()['paths']! as Map<String, Object?>;
  return {
    for (final path in paths.entries)
      for (final op in (path.value! as Map<String, Object?>).entries)
        (op.value! as Map<String, Object?>)['operationId']! as String: (
          method: op.key.toUpperCase(),
          path: path.key,
          tag:
              ((op.value! as Map<String, Object?>)['tags']! as List<Object?>)
                      .single!
                  as String,
        ),
  };
}

/// Hand-maintained: spec tag -> the root client's getter for it.
final Map<String, Object Function(SoundspanRestClient)> _clientPerTag = {
  'discovery': (c) => c.discovery,
  'library': (c) => c.library2,
  'playlists': (c) => c.playlists,
  'podcasts': (c) => c.podcasts,
  'search': (c) => c.search,
  'session': (c) => c.session,
};

/// Hand-maintained: operationId -> a call of the method of that name, with
/// `x` for every path parameter. Each entry only compiles when the generated
/// client has a method named after the operationId.
final Map<String, Future<Object?> Function(SoundspanRestClient)> _calls = {
  'getAuthConfig': (c) => c.session.getAuthConfig(),
  'login': (c) => c.session.login(
    body: const LoginRequest(username: 'ada', password: 'pw'),
  ),
  'logout': (c) => c.session.logout(),
  'getCurrentUser': (c) => c.session.getCurrentUser(),
  'refreshSession': (c) => c.session.refreshSession(
    body: const RefreshSessionRequest(refreshToken: 'r'),
  ),
  'getApiDocument': (c) => c.session.getApiDocument(),
  'getHealth': (c) => c.session.getHealth(),
  'getOnboardingStatus': (c) => c.session.getOnboardingStatus(),
  'getSystemFeatures': (c) => c.session.getSystemFeatures(),
  'listAlbums': (c) => c.library2.listAlbums(),
  'getAlbum': (c) => c.library2.getAlbum(id: 'x'),
  'listArtists': (c) => c.library2.listArtists(),
  'getArtist': (c) => c.library2.getArtist(id: 'x'),
  'listLikedTracks': (c) => c.library2.listLikedTracks(),
  'listRecentlyAdded': (c) => c.library2.listRecentlyAdded(),
  'listRecentlyListened': (c) => c.library2.listRecentlyListened(),
  'listTracks': (c) => c.library2.listTracks(),
  'listMixes': (c) => c.discovery.listMixes(),
  'listPlaylists': (c) => c.playlists.listPlaylists(),
  'getPlaylist': (c) => c.playlists.getPlaylist(id: 'x'),
  'listTopPodcasts': (c) => c.podcasts.listTopPodcasts(),
  'search': (c) => c.search.search(),
  'searchDiscover': (c) => c.search.searchDiscover(),
};

void main() {
  test('nullable_vs_optional', () {
    // Nullable key present with null; optional key absent.
    final body = _sample('library_track')
      ..['trackNo'] = null
      ..remove('playbackId');
    final track = LibraryTrack.fromJson(body);
    expect(track.trackNo, isNull);
    expect(track.playbackId, isNull);
    expect(track.title, 'First Track');

    // A required key absent fails.
    final missing = _sample('library_track')..remove('title');
    expect(() => LibraryTrack.fromJson(missing), throwsA(anything));
    // A required nullable key absent fails too: present-with-null is not
    // the same as absent.
    final missingNullable = _sample('library_track')..remove('trackNo');
    expect(() => LibraryTrack.fromJson(missingNullable), throwsA(anything));
  });

  group('login oneOf', () {
    late Dio dio;
    late DioAdapter adapter;
    late SoundspanRestClient client;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      adapter = DioAdapter(dio: dio);
      client = SoundspanRestClient(dio);
    });

    test('login_one_of_success', () async {
      adapter.onPost(
        '/api/auth/login',
        (server) => server.reply(200, _sample('login_success')),
        data: Matchers.any,
      );
      final result = await client.session.login(
        body: const LoginRequest(username: 'ada', password: 'pw'),
      );
      switch (result) {
        case LoginTokenResponse(:final token, :final refreshToken, :final user):
          expect(token, 'access-token');
          expect(refreshToken, 'refresh-token');
          expect(user.username, 'ada');
          expect(user.displayName, isNull);
        case LoginTwoFactorChallenge():
          fail('decoded the token body as a 2FA challenge');
      }
    });

    test('login_one_of_2fa', () async {
      adapter.onPost(
        '/api/auth/login',
        (server) => server.reply(200, _sample('login_2fa')),
        data: Matchers.any,
      );
      final result = await client.session.login(
        body: const LoginRequest(username: 'ada', password: 'pw'),
      );
      switch (result) {
        case LoginTwoFactorChallenge(:final message):
          expect(message, 'Two-factor authentication required');
        case LoginTokenResponse():
          fail('decoded the 2FA challenge as a token body');
      }
    });
  });

  test('unknown_enum_value', () {
    final track = LibraryTrack.fromJson(
      _sample('library_track')..['source'] = 'soundcloud',
    );
    expect(track.source, isA<TrackSourceUnknown>());
    expect((track.source as TrackSourceUnknown).rawValue, 'soundcloud');
    expect(track.toJson()['source'], 'soundcloud');

    final known = LibraryTrack.fromJson(_sample('library_track'));
    expect(known.source, TrackSource.local);
  });

  test('one_client_per_tag', () {
    final tags = {for (final op in _operations().values) op.tag};
    expect(_clientPerTag.keys.toSet(), tags);

    final root = SoundspanRestClient(Dio());
    final clients = {
      for (final getter in _clientPerTag.values) getter(root).runtimeType,
    };
    // One distinct client class per tag.
    expect(clients, hasLength(tags.length));
  });

  group('method_per_operation_id', () {
    test(
      'every operationId has a method that sends its method and path',
      () async {
        final operations = _operations();
        expect(_calls.keys.toSet(), operations.keys.toSet());

        for (final MapEntry(key: id, value: call) in _calls.entries) {
          RequestOptions? sent;
          final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
            ..interceptors.add(
              InterceptorsWrapper(
                onRequest: (options, handler) {
                  sent = options;
                  handler.reject(DioException(requestOptions: options));
                },
              ),
            );
          await expectLater(
            call(SoundspanRestClient(dio)),
            throwsA(isA<DioException>()),
          );
          final op = operations[id]!;
          expect(sent!.method, op.method, reason: id);
          expect(
            sent!.path,
            op.path.replaceAll(RegExp(r'\{[^}]+\}'), 'x'),
            reason: id,
          );
        }
      },
    );

    late Dio dio;
    late DioAdapter adapter;
    late SoundspanRestClient client;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      adapter = DioAdapter(dio: dio);
      client = SoundspanRestClient(dio);
    });

    test('GET with query parameters: listAlbums', () async {
      adapter.onGet(
        '/api/library/albums',
        (server) => server.reply(200, _sample('album_list')),
        queryParameters: {'limit': 25, 'offset': 50, 'sortBy': 'name-desc'},
      );
      final page = await client.library2.listAlbums(
        limit: 25,
        offset: 50,
        sortBy: ListAlbumsSortBy.nameDesc,
      );
      expect(page.offset, 50);
    });

    test('path parameter: getPlaylist', () async {
      adapter.onGet(
        '/api/playlists/pl-9',
        (server) => server.reply(200, _sample('playlist_detail')),
      );
      final detail = await client.playlists.getPlaylist(id: 'pl-9');
      expect(detail.id, 'pl-9');
    });

    test('POST with a body: login', () async {
      adapter.onPost(
        '/api/auth/login',
        (server) => server.reply(200, _sample('login_2fa')),
        data: jsonEncode({'password': 'pw', 'username': 'ada'}),
      );
      final result = await client.session.login(
        body: const LoginRequest(username: 'ada', password: 'pw'),
      );
      expect(result, isA<LoginTwoFactorChallenge>());
    });
  });

  group('unknown keys', () {
    test('unknown_keys_ignored', () {
      final body = _sample('library_track')..['addedByNewerServer'] = 1;
      final track = LibraryTrack.fromJson(body);
      expect(track.id, 'tr-1');
    });

    test('a closed object (additionalProperties: false) rejects them', () {
      final body = _sample('library_track')..['addedByNewerServer'] = 1;
      expect(() => closed.LibraryTrack.fromJson(body), throwsA(anything));
    });
  });

  test('date_time_utc', () {
    final playlist = PlaylistSummary.fromJson(_sample('playlist_summary'));
    expect(playlist.createdAt.isUtc, isTrue);
    expect(playlist.createdAt, DateTime.utc(2026, 3, 4, 5, 6, 7, 890));
    expect(playlist.updatedAt.isUtc, isTrue);
    expect(playlist.updatedAt, DateTime.utc(2026, 3, 5));
  });
}
