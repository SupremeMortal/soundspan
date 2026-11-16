// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/deep_link_router.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/auth/device_link_code.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/features/connect/connect.dart';

import '../../core/logging/recording_sink.dart';
import '../../helpers/fake_clock.dart';
import '../../helpers/fake_deep_links.dart';

/// The exact link of the web UI's device page (`getQRValue`).
const _devicePageLink =
    'soundspan://link?code=ABCD23&server=https%3A%2F%2Fmusic.example.com';

class _Profiles implements DeepLinkProfiles {
  new({this.byBaseUrl = const {}});

  @override
  bool hasActive = true;

  final Map<Uri, String> byBaseUrl;
  final List<String> switched = [];

  @override
  Future<String?> idForBaseUrl(List<Uri> candidates) async {
    for (final candidate in candidates) {
      final id = byBaseUrl[candidate];
      if (id != null) return id;
    }
    return null;
  }

  @override
  Future<void> switchTo(String profileId) async => switched.add(profileId);
}

GoRouter _testRouter() => GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/home', builder: (_, _) => const Text('home')),
    GoRoute(path: '/connect/probe', builder: (_, _) => const Text('probe')),
    for (final kind in DetailKind.values)
      GoRoute(
        path: '/${kind.name}/:id',
        builder: (_, state) =>
            Text('${kind.name} ${state.pathParameters['id']}'),
      ),
  ],
);

void main() {
  group('parse', () {
    final cases = <String, DeepLinkTarget?>{
      _devicePageLink: LinkDevice(
        'https://music.example.com',
        DeviceLinkCode.tryParse('ABCD23'),
      ),
      'SOUNDSPAN://link?code=ABCD23&server=https%3A%2F%2Fmusic.example.com':
          LinkDevice(
            'https://music.example.com',
            DeviceLinkCode.tryParse('ABCD23'),
          ),
      'soundspan://link?server=192.168.1.10%3A3030': const LinkDevice(
        '192.168.1.10:3030',
        null,
      ),
      'soundspan://link?code=ABCD23': null,
      'soundspan://link?server=ftp%3A%2F%2Fx': null,
      'soundspan://link?server=ftp://x': null,
      'soundspan://link?code=ABC10I&server=music.example.com': null,
      'soundspan://link/extra?server=music.example.com': null,
      'soundspan://album/abc': const OpenAlbum('abc'),
      'soundspan://artist/a-b_c.9': const OpenArtist('a-b_c.9'),
      'soundspan://playlist/liked': const OpenPlaylist('liked'),
      'soundspan://album/a/b': null,
      'soundspan://album/': null,
      'soundspan://album': null,
      'soundspan://album/a%2Fb': null,
      'soundspan://album/abc?x=1': null,
      'soundspan://album/${'a' * 129}': null,
      'soundspan://settings/abc': null,
      'https://music.example.com/album/abc': null,
    };
    for (final MapEntry(key: link, value: expected) in cases.entries) {
      test('$link -> $expected', () {
        expect(DeepLinkRouter.parse(Uri.parse(link)), expected);
      });
    }
  });

  group('handle', () {
    late GoRouter router;
    late FakeClock clock;
    late _Profiles profiles;
    late DeepLinkRouter deepLinks;
    late RecordingSink sink;

    Future<void> pumpRouter(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
    }

    String location() =>
        router.routerDelegate.currentConfiguration.uri.toString();

    setUp(() {
      sink = RecordingSink();
      AppLogging.configure(sinks: [sink], releaseMode: false);
      router = _testRouter();
      clock = FakeClock();
      profiles = _Profiles(
        byBaseUrl: {Uri.parse('https://known.example.com'): 'p-known'},
      );
      deepLinks = DeepLinkRouter(
        router: router,
        profiles: profiles,
        clock: clock,
      );
    });

    tearDown(() async {
      await deepLinks.dispose();
      router.dispose();
      AppLogging.reset();
    });

    testWidgets('a link with a code lands on the probe with server and code', (
      tester,
    ) async {
      await pumpRouter(tester);
      await deepLinks.handle(Uri.parse(_devicePageLink));
      await tester.pumpAndSettle();

      expect(location(), RoutePaths.probe);
      final extra =
          router.routerDelegate.currentConfiguration.extra! as ProbeRequest;
      expect(extra.input, 'https://music.example.com');
      expect(extra.address.candidates, [
        Uri.parse('https://music.example.com'),
      ]);
      expect(extra.address.linkCode, 'ABCD23');
    });

    testWidgets('a link without a code to a known server switches profile', (
      tester,
    ) async {
      await pumpRouter(tester);
      await deepLinks.handle(
        Uri.parse('soundspan://link?server=https%3A%2F%2Fknown.example.com%2F'),
      );
      await tester.pumpAndSettle();

      expect(profiles.switched, ['p-known']);
      expect(location(), '/home');
    });

    testWidgets('a link without a code to a new server opens the probe', (
      tester,
    ) async {
      await pumpRouter(tester);
      await deepLinks.handle(
        Uri.parse('soundspan://link?server=new.example.com'),
      );
      await tester.pumpAndSettle();

      expect(profiles.switched, isEmpty);
      expect(location(), RoutePaths.probe);
      final extra =
          router.routerDelegate.currentConfiguration.extra! as ProbeRequest;
      expect(extra.address.linkCode, isNull);
    });

    testWidgets('an entity link opens the detail in the active profile', (
      tester,
    ) async {
      await pumpRouter(tester);
      await deepLinks.handle(Uri.parse('soundspan://album/abc'));
      await tester.pumpAndSettle();

      expect(location(), '/album/abc');
      expect(find.text('album abc'), findsOneWidget);
    });

    testWidgets('an entity link without an active profile is dropped', (
      tester,
    ) async {
      profiles.hasActive = false;
      await pumpRouter(tester);
      await deepLinks.handle(Uri.parse('soundspan://artist/abc'));
      await tester.pumpAndSettle();

      expect(location(), '/home');
    });

    testWidgets('the same link within 2 seconds is handled once', (
      tester,
    ) async {
      await pumpRouter(tester);
      final links = FakeDeepLinks(initial: Uri.parse('soundspan://album/x1'));
      addTearDown(links.close);
      await deepLinks.listen(links);
      await tester.pumpAndSettle();
      expect(location(), '/album/x1');

      router.go('/home');
      await tester.pumpAndSettle();
      clock.advance(const Duration(milliseconds: 1500));
      links.send(Uri.parse('soundspan://album/x1'));
      await tester.pumpAndSettle();
      expect(location(), '/home');

      clock.advance(const Duration(seconds: 3));
      links.send(Uri.parse('soundspan://album/x1'));
      await tester.pumpAndSettle();
      expect(location(), '/album/x1');
    });

    testWidgets('an invalid link leaves the location and logs no query', (
      tester,
    ) async {
      await pumpRouter(tester);
      await deepLinks.handle(
        Uri.parse('soundspan://settings?secret=hunter2&server=x'),
      );
      await tester.pumpAndSettle();

      expect(location(), '/home');
      final entry = sink.entries.singleWhere(
        (e) => e.message == DeepLinkRouter.ignoredMessage,
      );
      expect(entry.level, 'warning');
      expect(entry.fields, {'scheme': 'soundspan', 'host': 'settings'});
      expect(entry.toString(), isNot(contains('hunter2')));
    });
  });
}
