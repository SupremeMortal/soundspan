// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/storage/app/app_database.dart' hide Profile;
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/features/settings/settings.dart';
import 'package:soundspan/platform/url_opener/url_opener.dart';
import 'package:soundspan_api/soundspan_api.dart' show ApiKeyCredentials;

import '../../core/profile/profile_harness.dart' show RecordingAppPaths;
import '../../helpers/fake_clock.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/in_memory_database_opener.dart';
import '../../helpers/in_memory_secret_store.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_root.dart';

class _RecordingUrlOpener implements UrlOpener {
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return true;
  }
}

void main() {
  Finder inTile(String profileId, Finder finder) => find.descendant(
    of: find.byKey(ValueKey<String>(profileId)),
    matching: finder,
  );

  Future<void> open(WidgetTester tester, TestRoot root) async {
    root.container.read(routerProvider).go(SettingsSection.servers.path);
    await tester.pumpAndSettle();
  }

  testWidgets('profiles are ordered by lastUsedAt', (tester) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      others: ['older', 'newer'],
    );
    await open(tester, root);
    final tops = [
      for (final name in [
        'music.example.com',
        'newer.example.com',
        'older.example.com',
      ])
        tester.getTopLeft(find.text(name)).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(find.text('ada on music.example.com'), findsOneWidget);
    expect(
      find.text('Active · Server version not known yet'),
      findsNWidgets(3),
    );
    await expectMeetsGuidelines(tester);
  });

  testWidgets('API-key profiles show when their link expires', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(database.close));
    final secrets = InMemorySecretStore();
    final clock = FakeClock();
    await tester.runAsync(() async {
      final repository = ProfileRepository(
        database,
        secrets,
        RecordingAppPaths(),
        InMemoryDatabaseOpener(),
        clock,
      );
      Future<Profile> add(String name, AuthKind kind, [DateTime? expiresAt]) =>
          repository.upsertSignedIn(
            baseUrl: Uri.parse('https://$name.example.com'),
            userId: 'user-$name',
            username: name,
            role: 'user',
            authKind: kind,
            credentials: ApiKeyCredentials(apiKey: '$name-key'),
            credentialCreatedAt: DateTime.utc(2026, 3, 3, 12),
            credentialExpiresAt: expiresAt,
          );
      final active = await add('music', AuthKind.password);
      await add('linked', AuthKind.deviceLink, DateTime.utc(2026, 6, 1, 12));
      await add('pasted', AuthKind.apiKey);
      await AppSettingsStore(database)
          .write(AppSettingKeys.activeProfileId, active.id);
    });
    final root = await tester.pumpSoundspanApp(
      database: database,
      secrets: secrets,
      clock: clock,
    );
    await open(tester, root);

    expect(
      find.text(
        'Active · Server version not known yet · Link expires Jun 1, 2026',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Active · Server version not known yet · Link expiry unknown'),
      findsOneWidget,
    );
    expect(find.text('Active · Server version not known yet'), findsOneWidget);
  });

  testWidgets('switch calls switchTo with the profile id', (tester) async {
    late RecordingProfileRuntime runtime;
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      others: ['other'],
      overrides: [recordingRuntimeOverride((r) => runtime = r)],
    );
    await open(tester, root);
    expect(inTile(root.profileId!, find.text('Switch')), findsNothing);
    runtime.delegate = false;
    await tester.tap(inTile(root.otherIds['other']!, find.text('Switch')));
    await tester.pumpAndSettle();
    expect(runtime.switched.last, root.otherIds['other']);
  });

  testWidgets('rename persists', (tester) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    await open(tester, root);
    await expectMeetsGuidelines(tester);
    await tester.tap(inTile(root.profileId!, find.text('Rename')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Home server');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final stored = await tester.runAsync(
      () =>
          root.container.read(profileRepositoryProvider).byId(root.profileId!),
    );
    expect(stored!.displayName, 'Home server');
    expect(find.text('Home server'), findsOneWidget);
  });

  testWidgets('cancelling rename changes nothing', (tester) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    await open(tester, root);
    await tester.tap(inTile(root.profileId!, find.text('Rename')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Other name');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('music.example.com'), findsOneWidget);
  });

  testWidgets('"Open server admin" is shown only for an admin', (tester) async {
    final opener = _RecordingUrlOpener();
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      role: 'admin',
      others: ['plain'],
      overrides: [urlOpenerProvider.overrideWithValue(opener)],
    );
    await open(tester, root);
    expect(
      inTile(root.otherIds['plain']!, find.text('Open server admin')),
      findsNothing,
    );
    await tester.tap(inTile(root.profileId!, find.text('Open server admin')));
    await tester.pumpAndSettle();
    expect(opener.opened, [Uri.parse('https://music.example.com/admin')]);
  });

  testWidgets('"Add server" goes to /connect', (tester) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    await open(tester, root);
    await tester.tap(find.text('Add server'));
    await tester.pumpAndSettle();
    expect(locationOf(root), '/connect');
  });

  testWidgets('/settings lists the sections and pushes one on compact', (
    tester,
  ) async {
    final root = await tester.pumpSoundspanApp(stored: StoredProfile.signedIn);
    root.container.read(routerProvider).go('/settings');
    await tester.pumpAndSettle();
    expect(find.text('Servers'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    await expectMeetsGuidelines(tester);

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    expect(locationOf(root), '/settings/appearance');
    expect(find.text('Theme'), findsOneWidget);
  });

  testWidgets('/settings is two columns on expanded', (tester) async {
    final root = await tester.pumpSoundspanApp(
      stored: StoredProfile.signedIn,
      size: TestSizes.expanded,
    );
    root.container.read(routerProvider).go('/settings');
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Add server'), findsOneWidget);
    await expectMeetsGuidelines(tester);

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    expect(locationOf(root), '/settings/appearance');
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Servers'), findsOneWidget);
  });
}
