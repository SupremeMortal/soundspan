// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/avatar_menu.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/reachability_binding.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/shared/widgets/offline_banner.dart';

import '../../../helpers/fake_reachability.dart';
import '../../../helpers/fakes/fake_download_controller.dart';
import '../../library/library_harness.dart';

void main() {
  late StateDatabase db;
  late DeviceSettingsDao settings;
  late FakeDownloadController downloads;

  setUp(() {
    db = StateDatabase(NativeDatabase.memory());
    settings = DeviceSettingsDao(db);
    downloads = FakeDownloadController();
  });
  tearDown(() => db.close());

  List<Override> overrides({bool canDownload = true}) => [
    ...downloads.overrides(canDownload: canDownload),
    deviceSettingsDaoProvider.overrideWithValue(settings),
  ];

  Future<Object?> forced(WidgetTester tester) =>
      tester.runAsync<Object?>(() => settings.read(offlineForcedKey));

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(AvatarButton.buttonKey));
    await tester.pumpAndSettle();
  }

  testWidgets('the "Offline mode" switch sets offline.forced, the Library '
      'banner offers "Go online", and tapping it clears the setting', (
    tester,
  ) async {
    final reachability = FakeReachability();
    await tester.pumpLibrary(
      tab: LibraryTab.songs,
      reachability: reachability,
      overrides: overrides(),
    );

    await openMenu(tester);
    final entry = find.byKey(AvatarButton.offlineModeKey);
    expect(entry, findsOneWidget);
    expect(tester.widget<SwitchListTile>(entry).value, isFalse);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(await forced(tester), isTrue);

    // The reachability controller follows the setting.
    reachability.set(Reachability.forcedOffline);
    await tester.pumpAndSettle();
    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(find.text('Offline mode is on.'), findsOneWidget);

    await openMenu(tester);
    expect(tester.widget<SwitchListTile>(entry).value, isTrue);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Go online'));
    await tester.pumpAndSettle();
    expect(await forced(tester), isFalse);
  });

  testWidgets('the switch is absent where the platform does not download', (
    tester,
  ) async {
    await tester.pumpLibrary(
      tab: LibraryTab.songs,
      overrides: overrides(canDownload: false),
    );
    await openMenu(tester);
    expect(find.text('Offline mode'), findsNothing);
  });

  testWidgets('"Go online" is offered only while offline mode is on', (
    tester,
  ) async {
    await tester.pumpLibrary(
      tab: LibraryTab.songs,
      reachability: FakeReachability(initial: Reachability.noNetwork),
      overrides: overrides(),
    );
    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(find.text('Go online'), findsNothing);
  });
}
