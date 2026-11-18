// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/platform/deep_links/deep_links.dart';
import 'package:soundspan/platform/deep_links/deep_links_io.dart';
import 'package:soundspan/platform/deep_links/deep_links_web.dart';

void main() {
  test('deepLinksIn keeps only soundspan: arguments, in order', () {
    expect(
      deepLinksIn(['--verbose', 'SOUNDSPAN://album/a', 'x', 'soundspan://b/c']),
      [Uri.parse('SOUNDSPAN://album/a'), Uri.parse('soundspan://b/c')],
    );
  });

  group('LaunchArgumentDeepLinks', () {
    test('the initial link is the first soundspan: launch argument', () async {
      final links = LaunchArgumentDeepLinks(
        launchArguments: ['--flag', 'soundspan://album/a', 'soundspan://b/c'],
        launches: const Stream.empty(),
      );
      expect(await links.initialLink(), Uri.parse('soundspan://album/a'));
    });

    test('no link without a soundspan: argument', () async {
      final links = LaunchArgumentDeepLinks(
        launchArguments: const ['--flag'],
        launches: const Stream.empty(),
      );
      expect(await links.initialLink(), isNull);
    });

    test('later launches deliver their soundspan: arguments', () async {
      final launches = StreamController<List<String>>();
      final links = LaunchArgumentDeepLinks(
        launchArguments: const [],
        launches: launches.stream,
      );
      final received = links.links.toList();
      launches
        ..add(const [])
        ..add(const ['soundspan://album/x']);
      await launches.close();
      expect(await received, [Uri.parse('soundspan://album/x')]);
    });
  });

  group('web query', () {
    test('?link=&server= becomes a soundspan://link, once', () async {
      final links = QueryDeepLinks(
        Uri.parse(
          'https://app.example.com/?link=ABCD23&server=https%3A%2F%2Fm.example.com',
        ),
      );
      final link = await links.initialLink();
      expect(link!.scheme, 'soundspan');
      expect(link.host, 'link');
      expect(link.queryParameters, {
        'code': 'ABCD23',
        'server': 'https://m.example.com',
      });
      expect(await links.initialLink(), isNull);
    });

    test('a page without server has no link', () {
      expect(linkFromQuery(Uri.parse('https://a.example.com/?link=X')), isNull);
    });
  });
}
