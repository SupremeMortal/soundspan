// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:soundspan/app/l10n/app_locales.dart';
import 'package:soundspan/core/storage/app/app_database.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/core/update/update_checker.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/release_feed/release_feed.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/providers/package_info.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_release_feed.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late FakeReleaseFeed feed;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clock = FakeClock();
    feed = FakeReleaseFeed();
  });
  tearDown(() => db.close());

  ProviderContainer container({
    String running = '0.1.0',
    String repository = 'owner/soundspan',
    String channel = 'stable',
    PlatformCapabilities capabilities = PlatformCapabilities.windowsAndLinux,
  }) {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
        releaseFeedProvider.overrideWithValue(feed),
        releaseRepositoryProvider.overrideWithValue(repository),
        buildChannelProvider.overrideWithValue(channel),
        platformCapabilitiesProvider.overrideWithValue(capabilities),
        packageInfoProvider.overrideWith(
          (ref) async => PackageInfo(
            appName: 'soundspan',
            packageName: 'com.soundspan.client',
            version: running,
            buildNumber: '7',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<UpdateState> check(ProviderContainer c, {bool force = false}) => c
      .read(updateCheckerProvider.notifier)
      .check(force: force)
      .then((_) => c.read(updateCheckerProvider));

  AppSettingsStore settings() => AppSettingsStore(db);

  test('a higher client release is available', () async {
    feed.releases = [release('client-v0.2.0')];

    final state = await check(container());

    expect(
      state,
      UpdateAvailable(
        '0.2.0',
        Uri.parse(
          'https://github.com/owner/soundspan/releases/tag/client-v0.2.0',
        ),
      ),
    );
    expect(feed.requests, ['owner/soundspan']);
  });

  test('the running release is up to date', () async {
    feed.releases = [release('client-v0.1.0')];

    expect(await check(container()), const UpToDate());
  });

  test('the build number of the running version is ignored', () async {
    feed.releases = [release('client-v0.1.0')];

    expect(await check(container(running: '0.1.0+9')), const UpToDate());
  });

  test('server tags are ignored', () async {
    feed.releases = [
      release('1.9.0'),
      release('v2.0.0'),
      release('client-v0.1.0'),
    ];

    expect(await check(container()), const UpToDate());
  });

  test('drafts are ignored', () async {
    feed.releases = [release('client-v0.3.0', draft: true)];

    expect(await check(container()), const UpToDate());
  });

  test('pre-releases count', () async {
    feed.releases = [release('client-v0.2.0-rc.1')];

    expect(
      await check(container()),
      isA<UpdateAvailable>().having((s) => s.version, 'version', '0.2.0-rc.1'),
    );
  });

  test('a pre-release is lower than its release', () async {
    feed.releases = [release('client-v0.2.0-rc.1')];

    expect(await check(container(running: '0.2.0')), const UpToDate());
  });

  test('the highest release is chosen whatever the feed order', () async {
    feed.releases = [
      release('client-v0.2.0'),
      release('client-v0.10.0'),
      release('client-v0.10.0-rc.2'),
      release('client-v0.3.1'),
    ];

    expect(
      await check(container()),
      isA<UpdateAvailable>().having((s) => s.version, 'version', '0.10.0'),
    );
  });

  test('checks at most once per 24 hours', () async {
    feed.releases = [release('client-v0.1.0')];
    final c = container();

    await check(c);
    expect(feed.requests, hasLength(1));
    expect(
      await settings().read(AppSettingKeys.updateLastCheckedAt),
      clock.now(),
    );

    clock.advance(const Duration(hours: 23));
    await check(c);
    expect(feed.requests, hasLength(1));

    clock.advance(const Duration(hours: 1));
    await check(c);
    expect(feed.requests, hasLength(2));
  });

  test('a forced check ignores the 24-hour limit', () async {
    final c = container();
    await check(c);
    clock.advance(const Duration(minutes: 1));

    await check(c, force: true);

    expect(feed.requests, hasLength(2));
  });

  group('a failure leaves the state and records the check:', () {
    for (final (name, error) in <(String, Exception)>[
      ('offline', const SocketException('Failed host lookup')),
      ('timeout', TimeoutException('no answer', const Duration(seconds: 10))),
      ('non-200', const HttpException('GitHub answered 403')),
      ('garbage', const FormatException('not a list of releases')),
    ]) {
      test(name, () async {
        feed.releases = [release('client-v0.2.0')];
        final c = container();
        final before = await check(c);
        expect(before, isA<UpdateAvailable>());

        clock.advance(const Duration(days: 1));
        feed.error = error;
        expect(await check(c), before);
        expect(
          await settings().read(AppSettingKeys.updateLastCheckedAt),
          clock.now(),
        );

        clock.advance(const Duration(hours: 1));
        await check(c);
        expect(feed.requests, hasLength(2));
      });
    }
  });

  group('a release page elsewhere is rejected:', () {
    for (final url in [
      'https://example.com/owner/soundspan/releases/tag/client-v0.2.0',
      'https://github.com/other/soundspan/releases/tag/client-v0.2.0',
      'https://github.com/owner/soundspan/issues/1',
      'http://github.com/owner/soundspan/releases/tag/client-v0.2.0',
    ]) {
      test(url, () async {
        feed.releases = [
          ReleaseInfo(
            tag: 'client-v0.2.0',
            htmlUrl: Uri.parse(url),
            draft: false,
          ),
        ];

        expect(await check(container()), const UpToDate());
      });
    }
  });

  group('no request is made when', () {
    test('the repository is empty', () async {
      await check(container(repository: ''));
      expect(feed.requests, isEmpty);
    });

    test('the channel is dev', () async {
      await check(container(channel: 'dev'));
      expect(feed.requests, isEmpty);
    });

    test('the setting is off', () async {
      await settings().write(AppSettingKeys.updateCheck, false);
      await check(container(), force: true);
      expect(feed.requests, isEmpty);
    });

    for (final (name, capabilities) in [
      ('on Android', PlatformCapabilities.android),
      ('on iOS', PlatformCapabilities.iOS),
      ('on the web', PlatformCapabilities.web),
    ]) {
      test(name, () async {
        await check(container(capabilities: capabilities), force: true);
        expect(feed.requests, isEmpty);
      });
    }
  });

  test('desktop platforms have the update notice, others do not', () {
    expect(PlatformCapabilities.windowsAndLinux.hasUpdateNotice, isTrue);
    expect(PlatformCapabilities.macOS.hasUpdateNotice, isTrue);
    expect(PlatformCapabilities.android.hasUpdateNotice, isFalse);
    expect(PlatformCapabilities.iOS.hasUpdateNotice, isFalse);
    expect(PlatformCapabilities.web.hasUpdateNotice, isFalse);
  });

  group('the banner notice', () {
    test('is the available update until it is dismissed', () async {
      feed.releases = [release('client-v0.2.0')];
      final c = container();
      final sub = c.listen(updateNoticeProvider, (_, _) {});
      addTearDown(sub.close);
      await check(c);
      await pumpEventQueue();
      expect(sub.read()?.version, '0.2.0');

      await c.read(updateCheckerProvider.notifier).dismiss('0.2.0');
      await pumpEventQueue();
      expect(sub.read(), isNull);
      expect(
        await settings().read(AppSettingKeys.updateDismissedVersion),
        '0.2.0',
      );
    });

    test('returns for a higher version', () async {
      await settings().write(AppSettingKeys.updateDismissedVersion, '0.2.0');
      feed.releases = [release('client-v0.2.1')];
      final c = container();
      final sub = c.listen(updateNoticeProvider, (_, _) {});
      addTearDown(sub.close);
      await check(c);
      await pumpEventQueue();

      expect(sub.read()?.version, '0.2.1');
    });
  });
}
