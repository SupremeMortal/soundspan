// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/platform/release_feed/release_feed.dart';

void main() {
  test('reads tag, page and draft of each release', () {
    expect(
      parseReleases([
        {
          'tag_name': 'client-v0.2.0',
          'html_url': 'https://github.com/o/r/releases/tag/client-v0.2.0',
          'draft': false,
          'prerelease': true,
        },
        {
          'tag_name': 'client-v0.3.0',
          'html_url': 'https://github.com/o/r/releases/tag/client-v0.3.0',
          'draft': true,
        },
      ]),
      [
        ReleaseInfo(
          tag: 'client-v0.2.0',
          htmlUrl: Uri.parse(
            'https://github.com/o/r/releases/tag/client-v0.2.0',
          ),
          draft: false,
        ),
        ReleaseInfo(
          tag: 'client-v0.3.0',
          htmlUrl: Uri.parse(
            'https://github.com/o/r/releases/tag/client-v0.3.0',
          ),
          draft: true,
        ),
      ],
    );
  });

  test('skips entries without a tag or page', () {
    expect(
      parseReleases([
        {'tag_name': 'client-v0.2.0'},
        {'html_url': 'https://github.com/o/r/releases/tag/x', 'draft': false},
        'garbage',
      ]),
      isEmpty,
    );
  });

  test('a body that is not a list is malformed', () {
    expect(
      () => parseReleases({'message': 'API rate limit exceeded'}),
      throwsFormatException,
    );
  });
}
