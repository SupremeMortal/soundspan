// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/downloads/download_artwork.dart'
    show downloadArtworkFileName;
import 'package:soundspan/core/playback/media_controls/artwork_pinner.dart';
import 'package:soundspan/platform/artwork_store/artwork_store.dart';
import 'package:soundspan/platform/artwork_store/artwork_store_io.dart'
    show IoArtworkStore;
import 'package:soundspan/platform/artwork_store/artwork_store_web.dart'
    show WebArtworkStore;
import 'package:soundspan/shared/providers/images.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// An [ArtworkStore] that keeps files in memory.
class _MemoryStore implements ArtworkStore {
  final Map<String, Uint8List> files = {};

  @override
  Future<Uri?> write(String path, Uint8List bytes) async {
    files[path] = bytes;
    return Uri.file(path);
  }

  @override
  Future<bool> exists(String path) async => files.containsKey(path);

  @override
  Future<List<String>> list(String directory) async => [
    for (final path in files.keys)
      if (p.dirname(path) == directory) p.basename(path),
  ];

  @override
  Future<void> delete(String path) async => files.remove(path);
}

/// Answers each fetch with the bytes of [bytes], recording it.
class _Fetcher {
  final List<ArtworkFetch> fetches = [];
  Uint8List bytes = Uint8List.fromList([1, 2, 3]);
  bool fail = false;

  Future<Uint8List> fetch(ArtworkFetch fetch) async {
    fetches.add(fetch);
    if (fail) throw const SocketException('offline');
    return bytes;
  }
}

const _jwt = JwtCredentials(accessToken: 'access', refreshToken: 'refresh');
const _art = '/support/profiles/p1/art';

void main() {
  late _Fetcher fetcher;
  late _MemoryStore store;
  ArtworkPinner pinner({bool isWeb = false, Credentials? credentials = _jwt}) =>
      ArtworkPinner(
        urls: ImageUrls(Uri.parse('https://music.example')),
        credentials: () => credentials,
        fetch: fetcher.fetch,
        store: store,
        artDirectory: isWeb ? null : _art,
        isWeb: isWeb,
      );

  setUp(() {
    fetcher = _Fetcher();
    store = _MemoryStore();
  });

  test('requests the 512-pixel cover with the session headers', () async {
    await pinner().pin('al-1');

    final fetch = fetcher.fetches.single;
    expect(fetch.url.queryParameters['size'], '512');
    expect(fetch.cacheKey, artworkCacheKey('al-1', 512));
    expect(fetch.headers, {'Authorization': 'Bearer access'});
  });

  test('writes the bytes and returns a file URI under the art '
      'directory', () async {
    final uri = await pinner().pin('al-1');

    expect(uri, Uri.file('$_art/now-playing.img'));
    expect(store.files['$_art/now-playing.img'], [1, 2, 3]);
  });

  test('a second pin replaces the file content', () async {
    await pinner().pin('al-1');
    fetcher.bytes = Uint8List.fromList([9, 9]);

    final uri = await pinner().pin('al-2');

    expect(uri, Uri.file('$_art/now-playing.img'));
    expect(store.files, hasLength(1));
    expect(store.files['$_art/now-playing.img'], [9, 9]);
  });

  test('a null cover gives null without a fetch', () async {
    expect(await pinner().pin(null), isNull);
    expect(fetcher.fetches, isEmpty);
  });

  test('a fetch failure gives null', () async {
    fetcher.fail = true;
    expect(await pinner().pin('al-1'), isNull);
    expect(store.files, isEmpty);
  });

  test('on web the cover URL carrying the token is returned', () async {
    final uri = await pinner(isWeb: true).pin('al-1');

    expect(uri!.queryParameters['token'], 'access');
    expect(uri.queryParameters['size'], '512');
    expect(fetcher.fetches, isEmpty);
    expect(store.files, isEmpty);
  });

  test('on web an API key, which cannot load images, gives null', () async {
    final uri = await pinner(
      isWeb: true,
      credentials: const ApiKeyCredentials(apiKey: 'key'),
    ).pin('al-1');
    expect(uri, isNull);
  });

  test('without an art directory nothing is written', () async {
    final pinner = ArtworkPinner(
      urls: ImageUrls(Uri.parse('https://music.example')),
      credentials: () => _jwt,
      fetch: fetcher.fetch,
      store: store,
      artDirectory: null,
      isWeb: false,
    );
    expect(await pinner.pin('al-1'), isNull);
    expect(store.files, isEmpty);
  });

  group('artwork stores', () {
    test('the native store creates the directory and replaces the '
        'file', () async {
      final root = await Directory.systemTemp.createTemp('artwork_store');
      addTearDown(() => root.delete(recursive: true));
      final path = '${root.path}/profiles/p1/art/now-playing.img';
      const store = IoArtworkStore();

      final uri = await store.write(path, Uint8List.fromList([1, 2]));
      expect(uri, File(path).uri);
      expect(File(path).readAsBytesSync(), [1, 2]);

      await store.write(path, Uint8List.fromList([3]));
      expect(File(path).readAsBytesSync(), [3]);
      expect(File('$path.tmp').existsSync(), isFalse);
    });

    test('the native store lists, checks and deletes files', () async {
      final root = await Directory.systemTemp.createTemp('artwork_store');
      addTearDown(() => root.delete(recursive: true));
      final art = '${root.path}/art';
      const store = IoArtworkStore();
      expect(await store.list(art), isEmpty);

      await store.write('$art/a.img', Uint8List.fromList([1]));
      await store.write('$art/b.img', Uint8List.fromList([2]));
      expect(await store.list(art), unorderedEquals(['a.img', 'b.img']));
      expect(await store.exists('$art/a.img'), isTrue);

      await store.delete('$art/a.img');
      await store.delete('$art/a.img');
      expect(await store.exists('$art/a.img'), isFalse);
      expect(await store.list(art), ['b.img']);
    });

    test('the web store stores nothing', () async {
      const store = WebArtworkStore();
      expect(await store.write('/x', Uint8List(1)), isNull);
      expect(await store.exists('/x'), isFalse);
      expect(await store.list('/'), isEmpty);
      await store.delete('/x');
    });

    test('now-playing.img and a download artwork file coexist', () async {
      final root = await Directory.systemTemp.createTemp('artwork_store');
      addTearDown(() => root.delete(recursive: true));
      final art = '${root.path}/profiles/p1/art';
      const store = IoArtworkStore();
      final pinner = ArtworkPinner(
        urls: ImageUrls(Uri.parse('https://music.example')),
        credentials: () => _jwt,
        fetch: fetcher.fetch,
        store: store,
        artDirectory: art,
        isWeb: false,
      );
      final download = '$art/${downloadArtworkFileName('al-2')}';
      await store.write(download, Uint8List.fromList([5]));

      await pinner.pin('al-1');

      expect(File('$art/now-playing.img').readAsBytesSync(), [1, 2, 3]);
      expect(File(download).readAsBytesSync(), [5]);
      expect(
        await store.list(art),
        unorderedEquals(['now-playing.img', downloadArtworkFileName('al-2')]),
      );
    });

    test('the platform store of the test host is the native one', () {
      expect(createArtworkStore(), isA<IoArtworkStore>());
    });
  });
}
