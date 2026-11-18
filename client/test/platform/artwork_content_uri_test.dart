// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/downloads/download_artwork.dart'
    show downloadArtworkFileName;
import 'package:soundspan/platform/artwork_content_uri/artwork_content_uri.dart';
import 'package:soundspan/platform/artwork_content_uri/artwork_content_uri_io.dart';

const String _authority = 'io.soundspan.app.artwork';
const String _ref = 'album:42?size=large/front';

void main() {
  group('artworkContentUri', () {
    test('names the authority, the profile and the pinned file', () {
      final uri = artworkContentUri(
        authority: _authority,
        profileId: 'p1',
        ref: _ref,
      );

      expect(uri.scheme, 'content');
      expect(uri.host, _authority);
      expect(uri.pathSegments, [
        'art',
        'p1',
        'art',
        downloadArtworkFileName(_ref),
      ]);
    });

    test('artFileFor maps it back to the file under profiles/', () {
      final uri = artworkContentUri(
        authority: _authority,
        profileId: 'p1',
        ref: _ref,
      );

      expect(
        artFileFor(uri),
        'profiles/p1/art/${downloadArtworkFileName(_ref)}',
      );
    });

    test('artFileFor rejects a path that leaves art/', () {
      final name = downloadArtworkFileName(_ref);
      for (final path in [
        'art/p1/art/../state.db',
        'art/p1/media/$name',
        'art/p1/art/sub/$name',
        'art/../p1/art/$name',
        'art/p1/art/now-playing.img',
        'art/p1/art/$name.tmp',
        'other/p1/art/$name',
        'art/p1/$name',
      ]) {
        expect(
          artFileFor(Uri.parse('content://$_authority/$path')),
          isNull,
          reason: path,
        );
      }
      expect(
        artFileFor(Uri.parse('file:///art/p1/art/$name')),
        isNull,
        reason: 'not a content URI',
      );
    });
  });

  group('FileArtworkContentUri', () {
    late Directory root;
    late String art;
    late List<Uri> granted;
    late FileArtworkContentUri uris;

    setUp(() {
      root = Directory.systemTemp.createTempSync('artwork_content_uri');
      art = p.join(root.path, 'profiles', 'p1', 'art');
      Directory(art).createSync(recursive: true);
      granted = [];
      uris = FileArtworkContentUri(
        authority: _authority,
        profileId: 'p1',
        artDirectory: art,
        grant: granted.add,
      );
    });
    tearDown(() => root.deleteSync(recursive: true));

    test('a ref with a pinned file yields its content URI, granted', () {
      File(p.join(art, downloadArtworkFileName(_ref))).writeAsBytesSync([1]);

      final uri = uris.forArtRef(_ref);

      expect(
        uri,
        artworkContentUri(authority: _authority, profileId: 'p1', ref: _ref),
      );
      expect(granted, [uri]);
    });

    test('a ref with no pinned file yields null', () {
      expect(uris.forArtRef(_ref), isNull);
      expect(granted, isEmpty);
    });
  });

  test('NoArtworkContentUri yields null', () {
    expect(const NoArtworkContentUri().forArtRef(_ref), isNull);
  });
}
