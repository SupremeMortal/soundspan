// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_quota.dart';
import 'package:soundspan/core/downloads/download_scheduler.dart';
import 'package:soundspan/core/downloads/offline_repository.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/features/settings/ui/storage_settings_screen.dart';
import 'package:soundspan/features/settings/ui/storage_settings_view_model.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan/shared/storage/storage_actions.dart';
import 'package:soundspan/shared/storage/storage_usage.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../../helpers/fake_api.dart';
import '../../../helpers/fake_reachability.dart';
import '../../../helpers/golden.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';

const int _mb = 1024 * 1024;
const int _gb = 1024 * _mb;

final Profile _profile = Profile(
  id: 'p1',
  baseUrl: Uri.parse('https://music.example.com'),
  displayName: 'music.example.com',
  userId: 'user-1',
  username: 'ada',
  role: 'user',
  authKind: AuthKind.deviceLink,
  deviceId: 'd1',
  credentialCreatedAt: DateTime.utc(2026),
  credentialExpiresAt: DateTime.utc(2026, 4),
  state: ProfileState.active,
  lastUsedAt: DateTime.utc(2026),
);

final ProfilePaths _paths = ProfilePaths.derive(
  appSupport: '/support',
  appCache: '/cache',
  profileId: 'p1',
);

const StorageUsage _usage = StorageUsage(
  downloadsBytes: 1536 * _mb,
  downloadCount: 12,
  imageCacheBytes: 80 * _mb,
  databaseBytes: 6 * _mb,
  freeDiskBytes: 100 * _gb,
);

/// Records the controller calls the screen makes.
final class _FakeDownloads implements DownloadController {
  int rechecks = 0;

  @override
  Future<void> recheckSpace() async => rechecks++;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Records the storage actions the screen runs.
final class _FakeActions implements StorageActions {
  int clears = 0;
  int removals = 0;

  @override
  Future<void> clearCache() async => clears++;

  @override
  Future<void> removeAllDownloads() async => removals++;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// An offline client whose statistics request fails.
final class _FailingOfflineClient implements api.OfflineClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('the server failed');
}

/// The overrides of one profile, in memory.
final class _Rig {
  final StateDatabase db = StateDatabase(NativeDatabase.memory());
  late final DeviceSettingsDao settings = DeviceSettingsDao(db);
  final FakeOfflineClient server = FakeApi().offline;
  final FakeReachability reachability = FakeReachability();
  final _FakeDownloads downloads = _FakeDownloads();
  final _FakeActions actions = _FakeActions();
  api.OfflineClient? offlineClient;

  List<Override> overrides({
    PlatformCapabilities capabilities = PlatformCapabilities.android,
    bool hasFiles = true,
    StorageUsage usage = _usage,
  }) => [
    deviceSettingsDaoProvider.overrideWithValue(settings),
    platformCapabilitiesProvider.overrideWithValue(capabilities),
    profileContextProvider.overrideWithValue(
      ProfileContext(profile: _profile, paths: hasFiles ? _paths : null),
    ),
    storageUsageProvider.overrideWith((ref) async => usage),
    downloadControllerProvider.overrideWithValue(downloads),
    storageActionsProvider.overrideWithValue(actions),
    offlineRepositoryProvider.overrideWithValue(
      OfflineRepository(offlineClient ?? server),
    ),
    reachabilityProvider.overrideWithValue(reachability),
  ];
}

void main() {
  late _Rig rig;

  setUp(() {
    rig = _Rig();
    rig.server
      ..cacheLimitBytes = 10 * _gb
      ..devices['d1'] = {'t1': (quality: 'original', sizeBytes: 3 * _mb)};
  });
  tearDown(() => rig.db.close());

  Future<void> pump(
    WidgetTester tester, {
    PlatformCapabilities capabilities = PlatformCapabilities.android,
    bool hasFiles = true,
    Size size = TestSizes.medium,
    double textScale = 1.0,
  }) async {
    await tester.pumpApp(
      const Scaffold(body: StorageSettingsScreen()),
      size: size,
      textScale: textScale,
      overrides: rig.overrides(capabilities: capabilities, hasFiles: hasFiles),
    );
    await tester.pumpAndSettle();
  }

  String? subtitleOf(WidgetTester tester, String title) {
    final tile = tester.widget<ListTile>(
      find.ancestor(of: find.text(title), matching: find.byType(ListTile)),
    );
    return switch (tile.subtitle) {
      final Text text => text.data,
      _ => null,
    };
  }

  Slider slider(WidgetTester tester) => tester.widget<Slider>(
    find.byKey(StorageSettingsScreen.deviceLimitSliderKey),
  );

  testWidgets('download quality shows the stored value and writes '
      'quality.download', (tester) async {
    await rig.settings.write(downloadQualityKey, 'high');
    await pump(tester);
    expect(subtitleOf(tester, 'Download quality'), 'High');
    expect(find.text('The quality applies to new downloads.'), findsOneWidget);

    await tester.tap(find.text('Download quality'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Low').last);
    await tester.pumpAndSettle();

    expect(await rig.settings.read(downloadQualityKey), 'low');
    expect(subtitleOf(tester, 'Download quality'), 'Low');
  });

  testWidgets('Wi-Fi only is on by default on Android and writes '
      'downloads.wifiOnly', (tester) async {
    await pump(tester);
    SwitchListTile tile() => tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Download on Wi-Fi only'),
    );
    expect(tile().value, isTrue);

    await tester.tap(find.text('Download on Wi-Fi only'));
    await tester.pumpAndSettle();

    expect(await rig.settings.read(downloadsWifiOnlyKey), isFalse);
    expect(tile().value, isFalse);
  });

  testWidgets('Wi-Fi only is off by default on desktop', (tester) async {
    await pump(tester, capabilities: PlatformCapabilities.windowsAndLinux);
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Download on Wi-Fi only'),
          )
          .value,
      isFalse,
    );
  });

  testWidgets('the device limit shows the stored value against the usage; '
      'raising it writes downloads.quotaBytes and calls recheckSpace', (
    tester,
  ) async {
    await rig.settings.write(downloadsQuotaKey, 20 * _gb);
    await pump(tester);
    expect(subtitleOf(tester, 'Device limit'), '1.5 GB of 20.0 GB used');
    // Up to 100 GB fits in free space plus usage, then "No limit".
    expect(slider(tester).divisions, 7);
    expect(slider(tester).value, 4);

    slider(tester).onChanged!(5);
    slider(tester).onChangeEnd!(5);
    await tester.pumpAndSettle();

    expect(await rig.settings.read(downloadsQuotaKey), 50 * _gb);
    expect(rig.downloads.rechecks, 1);
    expect(subtitleOf(tester, 'Device limit'), '1.5 GB of 50.0 GB used');

    slider(tester).onChanged!(7);
    slider(tester).onChangeEnd!(7);
    await tester.pumpAndSettle();

    expect(await rig.settings.read(downloadsQuotaKey), kNoDeviceLimitBytes);
    expect(rig.downloads.rechecks, 2);
    expect(subtitleOf(tester, 'Device limit'), '1.5 GB used, no limit');
  });

  testWidgets('an unset device limit shows the default limit', (tester) async {
    await pump(tester);
    expect(subtitleOf(tester, 'Device limit'), '1.5 GB of 20.0 GB used');
  });

  testWidgets('the slider exposes increase and decrease actions', (
    tester,
  ) async {
    await rig.settings.write(downloadsQuotaKey, 20 * _gb);
    final handle = tester.ensureSemantics();
    await pump(tester);
    final increase = find.semantics.byAction(SemanticsAction.increase);
    expect(increase, findsOne);
    final node = increase.evaluate().single;
    expect(node.getSemanticsData().hasAction(SemanticsAction.decrease), isTrue);
    expect(node.value, '20.0 GB');
    handle.dispose();
  });

  for (final (label, title, confirm) in [
    ('Remove all downloads', 'Remove all downloads?', 'Remove'),
    ('Clear cache', 'Clear cache?', 'Clear'),
  ]) {
    testWidgets('"$label" asks first; cancel does nothing', (tester) async {
      await pump(tester);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      if (label == 'Remove all downloads') {
        expect(
          find.text(
            'This frees 1.5 GB on this device. You can download them '
            'again later.',
          ),
          findsOneWidget,
        );
      }

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsNothing);
      expect(rig.actions.removals + rig.actions.clears, 0);

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(StorageSettingsScreen.confirmKey));
      await tester.pumpAndSettle();
      expect(find.text(confirm), findsNothing);
      expect(
        label == 'Clear cache' ? rig.actions.clears : rig.actions.removals,
        1,
      );
    });
  }

  testWidgets('the usage rows show formatted sizes', (tester) async {
    await pump(tester);
    expect(find.text('This device'), findsOneWidget);
    expect(find.text('12 items'), findsOneWidget);
    expect(find.text('1.5 GB'), findsOneWidget);
    expect(find.text('80.0 MB'), findsOneWidget);
    expect(find.text('6.0 MB'), findsOneWidget);
    expect(find.text('100.0 GB'), findsOneWidget);
  });

  testWidgets('the server section shows the statistics while online', (
    tester,
  ) async {
    await pump(tester, size: const Size(800, 1600));
    expect(find.text('Used on the server: 3.0 MB of 10.0 GB'), findsOneWidget);
    expect(find.text('From this device: 3.0 MB, 1 track'), findsOneWidget);
    expect(
      find.text('The server limit is changed in the server’s settings.'),
      findsOneWidget,
    );
  });

  testWidgets('the server section is absent offline', (tester) async {
    rig.reachability.set(Reachability.noNetwork);
    await pump(tester, size: const Size(800, 1600));
    expect(find.text('Server'), findsNothing);
    expect(find.textContaining('Used on the server'), findsNothing);
    expect(find.text('Clear cache'), findsOneWidget);
  });

  testWidgets('the server section is absent when the request fails', (
    tester,
  ) async {
    rig.offlineClient = _FailingOfflineClient();
    await pump(tester, size: const Size(800, 1600));
    expect(find.text('Server'), findsNothing);
    expect(find.textContaining('Used on the server'), findsNothing);
    expect(find.text('Clear cache'), findsOneWidget);
  });

  testWidgets('without downloads the Downloads and Server sections are '
      'absent and the Cache section remains', (tester) async {
    await pump(
      tester,
      capabilities: PlatformCapabilities.web,
      size: const Size(800, 1600),
    );
    expect(find.text('Download quality'), findsNothing);
    expect(find.text('Device limit'), findsNothing);
    expect(find.text('Remove all downloads'), findsNothing);
    expect(find.text('Server'), findsNothing);
    expect(find.text('Cache'), findsOneWidget);
    expect(find.text('Clear cache'), findsOneWidget);
  });

  testWidgets('without files (web) the device rows are absent', (tester) async {
    await pump(tester, capabilities: PlatformCapabilities.web, hasFiles: false);
    expect(find.text('This device'), findsNothing);
    expect(find.text('Images'), findsNothing);
    expect(find.text('Clear cache'), findsOneWidget);
  });

  for (final size in [TestSizes.compact, TestSizes.expanded]) {
    testWidgets('meets the guidelines at ${size.width.toInt()}', (
      tester,
    ) async {
      await rig.settings.write(downloadsQuotaKey, 20 * _gb);
      await pump(tester, size: size);
      await expectMeetsGuidelines(tester);
    });
  }

  testWidgets('text scale 2.0 at width 390 does not overflow', (tester) async {
    await pump(tester, size: TestSizes.compact, textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  goldenMatrix(
    'storage_settings_screen',
    overrides: _goldenRig.overrides(),
    builder: (_) => const StorageSettingsScreen(),
  );
}

/// The golden images' profile: a device limit of 20 GB, online.
final _Rig _goldenRig = () {
  final rig = _Rig();
  rig.server.devices['d1'] = {'t1': (quality: 'original', sizeBytes: 3 * _mb)};
  return rig;
}();
