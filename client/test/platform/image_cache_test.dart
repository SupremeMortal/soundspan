// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/platform/image_cache/image_cache.dart';

void main() {
  test("files are created under the profile's images directory", () async {
    final root = await Directory.systemTemp.createTemp('image_cache_test');
    addTearDown(() => root.delete(recursive: true));
    final images = p.join(root.path, 'profiles', 'p1', 'images');

    final manager = createImageCacheManager(profileId: 'p1', directory: images);
    addTearDown(manager.dispose);
    final file = await manager.putFile(
      'https://music.example/api/library/cover-art/a?size=320',
      Uint8List.fromList([1, 2, 3]),
      key: 'a:320',
    );

    expect(p.isWithin(images, file.path), isTrue);
    expect(await file.readAsBytes(), [1, 2, 3]);
    expect((await manager.getFileFromCache('a:320'))?.file.path, file.path);
  });

  test('the store keeps images 30 days and at most 10,000 of them', () {
    expect(imageCacheStalePeriod, const Duration(days: 30));
    expect(imageCacheMaxObjects, 10000);
  });
}
