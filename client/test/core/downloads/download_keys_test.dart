// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/platform/paths/paths.dart';

void main() {
  group('DownloadItemKey', () {
    test('a track key round-trips and carries the playback id verbatim', () {
      const key = TrackItemKey('yt:abc:def/ghi');
      expect(key.encode(), 't:yt:abc:def/ghi');
      expect(DownloadItemKey.decode('t:yt:abc:def/ghi'), key);
    });

    test('an episode key round-trips', () {
      const key = EpisodeItemKey(podcastId: 'p1', episodeId: 'e:9');
      expect(key.encode(), 'e:p1:e:9');
      expect(DownloadItemKey.decode('e:p1:e:9'), key);
    });

    test('decode rejects an unknown or malformed key', () {
      expect(() => DownloadItemKey.decode('x:1'), throwsFormatException);
      expect(() => DownloadItemKey.decode('t:'), throwsFormatException);
      expect(() => DownloadItemKey.decode('e:p1'), throwsFormatException);
      expect(() => DownloadItemKey.decode('e::e1'), throwsFormatException);
    });
  });

  group('itemKeyHash', () {
    test('is the lower-case hex SHA-1 of the encoded key', () {
      // printf 't:abc' | sha1sum
      expect(
        itemKeyHash(const TrackItemKey('abc')),
        '1edb4f5c5a344e596b7a03bbeb6836b87d77fa51',
      );
    });

    test('is stable and distinguishes keys', () {
      expect(
        itemKeyHash(const EpisodeItemKey(podcastId: 'p', episodeId: 'e')),
        itemKeyHash(DownloadItemKey.decode('e:p:e')),
      );
      expect(
        itemKeyHash(const TrackItemKey('a')),
        isNot(itemKeyHash(const TrackItemKey('b'))),
      );
    });
  });

  group('DownloadPaths', () {
    final profile = ProfilePaths.derive(
      appSupport: '/support',
      appCache: '/cache',
      profileId: 'p1',
    );
    final paths = DownloadPaths(profile);
    const hash = 'ab0123456789abcdef0123456789abcdef012345';

    test('the part file fans out by the first two hash characters', () {
      expect(paths.relativePartFile(hash), p.join('media', 'ab', '$hash.part'));
      expect(
        paths.partFile(hash),
        p.join('/support', 'profiles', 'p1', 'media', 'ab', '$hash.part'),
      );
    });

    test('the final file takes its extension from the content type', () {
      expect(
        paths.relativeFinalFile(hash, 'audio/flac'),
        p.join('media', 'ab', '$hash.flac'),
      );
      expect(
        paths.finalFile(hash, 'audio/mpeg'),
        p.join('/support', 'profiles', 'p1', 'media', 'ab', '$hash.mp3'),
      );
    });

    test('resolve joins a relative path onto the profile directory', () {
      expect(
        paths.resolve(p.join('media', 'ab', '$hash.mp3')),
        p.join('/support', 'profiles', 'p1', 'media', 'ab', '$hash.mp3'),
      );
    });
  });

  group('extensionForContentType', () {
    test('follows the table of doc 05', () {
      expect(extensionForContentType('audio/mpeg'), 'mp3');
      expect(extensionForContentType('audio/flac'), 'flac');
      expect(extensionForContentType('audio/mp4'), 'm4a');
      expect(extensionForContentType('audio/ogg'), 'ogg');
      expect(extensionForContentType('audio/webm'), 'webm');
      expect(extensionForContentType('audio/x-unknown'), 'bin');
      expect(extensionForContentType(null), 'bin');
    });

    test('ignores parameters and case', () {
      expect(extensionForContentType('Audio/MPEG; charset=binary'), 'mp3');
    });
  });
}
