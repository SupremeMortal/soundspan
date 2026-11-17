// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:soundspan/app/l10n/app_locales.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/update_banner.dart';
import 'package:soundspan/core/storage/app/app_database.dart';
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/core/storage/providers.dart';
import 'package:soundspan/core/update/update_checker.dart';
import 'package:soundspan/features/settings/settings.dart';
import 'package:soundspan/features/settings/ui/about/about_section.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/release_feed/release_feed.dart';
import 'package:soundspan/platform/url_opener/url_opener.dart';
import 'package:soundspan/shared/providers/package_info.dart';

import '../../helpers/fake_release_feed.dart';
import '../../helpers/golden.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_root.dart';

/// A [UrlOpener] that records what it opened.
class _RecordingUrlOpener implements UrlOpener {
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return true;
  }
}

final Uri _page = Uri.parse(
  'https://github.com/owner/soundspan/releases/tag/client-v0.2.0',
);

/// The overrides of a stable Linux build of `0.1.0` that checks
/// [repository] in [feed]; [db] holds the app settings.
List<Override> _updateOverrides({
  required FakeReleaseFeed feed,
  AppDatabase? db,
  UrlOpener? opener,
  String repository = 'owner/soundspan',
}) => [
  ?(db == null ? null : appDatabaseProvider.overrideWithValue(db)),
  releaseFeedProvider.overrideWithValue(feed),
  releaseRepositoryProvider.overrideWithValue(repository),
  buildChannelProvider.overrideWithValue('stable'),
  platformCapabilitiesProvider.overrideWithValue(
    PlatformCapabilities.windowsAndLinux,
  ),
  packageInfoProvider.overrideWith(
    (ref) async => PackageInfo(
      appName: 'soundspan',
      packageName: 'com.soundspan.client',
      version: '0.1.0',
      buildNumber: '1',
    ),
  ),
  ?(opener == null ? null : urlOpenerProvider.overrideWithValue(opener)),
];

/// Lets database work and the frames after it finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase db;
  late FakeReleaseFeed feed;
  late _RecordingUrlOpener opener;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    feed = FakeReleaseFeed(releases: [release('client-v0.2.0')]);
    opener = _RecordingUrlOpener();
  });
  tearDown(() => db.close());

  Future<ProviderContainer> pumpBanner(
    WidgetTester tester, {
    Size size = TestSizes.compact,
  }) async {
    final container = await tester.pumpApp(
      const Scaffold(body: Column(children: [UpdateBanner()])),
      size: size,
      overrides: _updateOverrides(feed: feed, db: db, opener: opener),
    );
    await settle(tester);
    return container;
  }

  testWidgets('shows the newer version after the first frame', (tester) async {
    await pumpBanner(tester);

    expect(feed.requests, ['owner/soundspan']);
    expect(find.text('soundspan 0.2.0 is available'), findsOneWidget);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('shows nothing when the release is not newer', (tester) async {
    feed.releases = [release('client-v0.1.0')];
    await pumpBanner(tester);

    expect(find.textContaining('is available'), findsNothing);
  });

  testWidgets('View release opens the release page', (tester) async {
    await pumpBanner(tester);

    await tester.tap(find.text('View release'));
    await tester.pump();

    expect(opener.opened, [_page]);
  });

  testWidgets('dismiss hides the banner and remembers the version', (
    tester,
  ) async {
    await pumpBanner(tester);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();

    expect(find.textContaining('is available'), findsNothing);
    expect(
      await tester.runAsync(
        () => AppSettingsStore(db).read(AppSettingKeys.updateDismissedVersion),
      ),
      '0.2.0',
    );
  });

  testWidgets('a dismissed version stays hidden', (tester) async {
    await tester.runAsync(
      () =>
          AppSettingsStore(db)
              .write(AppSettingKeys.updateDismissedVersion, '0.2.0'),
    );
    await pumpBanner(tester);

    expect(feed.requests, hasLength(1));
    expect(find.textContaining('is available'), findsNothing);
  });

  testWidgets('a higher version than the dismissed one shows again', (
    tester,
  ) async {
    await tester.runAsync(
      () =>
          AppSettingsStore(db)
              .write(AppSettingKeys.updateDismissedVersion, '0.2.0'),
    );
    feed.releases = [release('client-v0.3.0')];
    await pumpBanner(tester);

    expect(find.text('soundspan 0.3.0 is available'), findsOneWidget);
  });

  group('Settings → About', () {
    Future<ProviderContainer> pumpAbout(WidgetTester tester) async {
      final container = await tester.pumpApp(
        const Scaffold(body: Column(children: [VersionTile(), UpdateTiles()])),
        overrides: _updateOverrides(feed: feed, db: db, opener: opener),
      );
      await settle(tester);
      return container;
    }

    testWidgets('shows the newer version even when dismissed', (tester) async {
      await tester.runAsync(
        () =>
            AppSettingsStore(db)
                .write(AppSettingKeys.updateDismissedVersion, '0.2.0'),
      );
      final container = await pumpAbout(tester);
      unawaited(container.read(updateCheckerProvider.notifier).check());
      await settle(tester);

      expect(find.text('Version 0.2.0 is available'), findsOneWidget);
      await tester.tap(find.text('View release'));
      await tester.pump();
      expect(opener.opened, [_page]);
    });

    testWidgets('Check now asks again within 24 hours', (tester) async {
      final container = await pumpAbout(tester);
      unawaited(container.read(updateCheckerProvider.notifier).check());
      await settle(tester);
      expect(feed.requests, hasLength(1));

      await tester.tap(find.text('Check now'));
      await settle(tester);

      expect(feed.requests, hasLength(2));
      await expectMeetsGuidelines(tester);
    });

    testWidgets('has no update rows where the check does not run', (
      tester,
    ) async {
      await tester.pumpApp(
        const Scaffold(body: Column(children: [VersionTile(), UpdateTiles()])),
        overrides: _updateOverrides(feed: feed, db: db, repository: ''),
      );
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();

      expect(find.text('1.2.3 (45)'), findsNothing);
      expect(find.text('0.1.0 (1)'), findsOneWidget);
      expect(find.text('Check now'), findsNothing);
      expect(feed.requests, isEmpty);
    });
  });

  group('Settings → Desktop', () {
    testWidgets('the switch turns the check off', (tester) async {
      final root = await tester.pumpSoundspanApp(
        stored: StoredProfile.signedIn,
        size: TestSizes.expanded,
        overrides: _updateOverrides(feed: FakeReleaseFeed()),
      );
      root.container.read(routerProvider).go(SettingsSection.desktop.path);
      await tester.pumpAndSettle();

      expect(find.text('Check for new versions'), findsOneWidget);
      expect(
        find.text('Asks GitHub for the list of soundspan releases once a day.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(DesktopSection.updateCheckKey));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();

      expect(
        await tester.runAsync(
          () => root.container
              .read(appSettingsProvider)
              .read(AppSettingKeys.updateCheck),
        ),
        isFalse,
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
  });

  group('the shell', () {
    for (final size in [TestSizes.compact, TestSizes.expanded]) {
      testWidgets('shows the banner at ${size.width.toInt()} wide', (
        tester,
      ) async {
        final updates = FakeReleaseFeed(releases: [release('client-v0.2.0')]);
        await tester.pumpSoundspanApp(
          stored: StoredProfile.signedIn,
          size: size,
          overrides: _updateOverrides(feed: updates),
        );
        await tester.runAsync(pumpEventQueue);
        await tester.pumpAndSettle();

        expect(updates.requests, ['owner/soundspan']);
        expect(find.text('soundspan 0.2.0 is available'), findsOneWidget);
      });
    }
  });

  goldenMatrix(
    'update_banner',
    sizes: const [TestSizes.compact, TestSizes.expanded],
    builder: (context) =>
        const Align(alignment: Alignment.topCenter, child: UpdateBanner()),
    overrides: [
      updateCheckerProvider.overrideWith(_AvailableChecker.new),
      dismissedUpdateVersionProvider.overrideWithValue(const AsyncData(null)),
    ],
  );
}

/// An [UpdateChecker] that already found `0.2.0` and never asks.
class _AvailableChecker extends UpdateChecker {
  @override
  UpdateState build() => UpdateAvailable('0.2.0', _page);

  @override
  Future<void> check({bool force = false}) async {}
}
