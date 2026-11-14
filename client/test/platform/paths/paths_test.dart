// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/platform/paths/paths_io.dart';

void main() {
  final support = p.join(p.separator, 'support');
  final cache = p.join(p.separator, 'cache');

  group('ProfilePaths', () {
    final paths = IoAppPaths(appSupport: support, appCache: cache);

    test('roots and logs follow the doc 05 tree', () {
      expect(paths.appSupport, support);
      expect(paths.appCache, cache);
      expect(paths.logs, p.join(support, 'logs'));
    });

    test('every profile member follows the doc 05 tree', () {
      final profile = paths.profile('abc');
      expect(profile.profileId, 'abc');
      expect(profile.supportRoot, p.join(support, 'profiles', 'abc'));
      expect(profile.stateDb, p.join(support, 'profiles', 'abc', 'state.db'));
      expect(profile.media, p.join(support, 'profiles', 'abc', 'media'));
      expect(profile.art, p.join(support, 'profiles', 'abc', 'art'));
      expect(profile.cacheRoot, p.join(cache, 'profiles', 'abc'));
      expect(profile.cacheDb, p.join(cache, 'profiles', 'abc', 'cache.db'));
      expect(profile.images, p.join(cache, 'profiles', 'abc', 'images'));
    });

    test('is a value', () {
      expect(paths.profile('abc'), paths.profile('abc'));
      expect(paths.profile('abc').hashCode, paths.profile('abc').hashCode);
      expect(paths.profile('abc'), isNot(paths.profile('abd')));
    });

    test('two profile ids never share a directory', () {
      final a = paths.profile('a');
      final b = paths.profile('b');
      final aDirs = [a.supportRoot, a.cacheRoot];
      final bDirs = [b.supportRoot, b.cacheRoot];
      for (final x in aDirs) {
        for (final y in bDirs) {
          expect(p.isWithin(x, y) || p.isWithin(y, x) || x == y, isFalse);
        }
      }
    });

    test('an id that is not a single path segment is rejected', () {
      for (final id in ['', '.', '..', 'a/b', r'a\b']) {
        expect(() => paths.profile(id), throwsArgumentError, reason: id);
      }
    });
  });

  group('deleteProfileTree', () {
    late Directory root;
    late IoAppPaths paths;

    setUp(() {
      root = Directory.systemTemp.createTempSync('paths_test');
      paths = IoAppPaths(
        appSupport: p.join(root.path, 'support'),
        appCache: p.join(root.path, 'cache'),
      );
    });
    tearDown(() => root.deleteSync(recursive: true));

    test('removes both trees of the profile and nothing else', () async {
      final doomed = paths.profile('doomed');
      final kept = paths.profile('kept');
      for (final dir in [doomed.media, doomed.images, kept.media]) {
        Directory(dir).createSync(recursive: true);
      }
      File(doomed.stateDb).writeAsStringSync('x');
      File(doomed.cacheDb).writeAsStringSync('x');

      await paths.deleteProfileTree('doomed');

      expect(Directory(doomed.supportRoot).existsSync(), isFalse);
      expect(Directory(doomed.cacheRoot).existsSync(), isFalse);
      expect(Directory(kept.media).existsSync(), isTrue);
    });

    test('tolerates missing trees', () async {
      await paths.deleteProfileTree('never-created');
      Directory(paths.profile('half').cacheRoot).createSync(recursive: true);
      await paths.deleteProfileTree('half');
      expect(Directory(paths.profile('half').cacheRoot).existsSync(), isFalse);
    });
  });
}
