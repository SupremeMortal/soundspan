// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/podcast_settings.dart';
import 'package:soundspan/core/playback/stream_quality_policy.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/settings/settings_providers.dart';
import 'package:soundspan/core/profile/settings/settings_repository.dart';
import 'package:soundspan/core/profile/settings/user_settings.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/features/settings/ui/playback_settings_screen.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../../core/playback/controller/controller_harness.dart';
import '../../../helpers/fake_api.dart';
import '../../../helpers/fake_reachability.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';

/// A track entry [id].
QueueItem _track(String id) => QueueItem.track(
  queueItemId: id,
  track: Track(
    meta: TrackMeta(
      title: 'Song $id',
      artist: 'Band',
      album: 'Record',
      durationSec: 180,
    ),
    playbackId: PlaybackId('pb-$id'),
  ),
  context: const QueueContext(kind: QueueContextKind.album),
);

/// An episode entry [id].
QueueItem _episode(String id) => QueueItem.episode(
  queueItemId: id,
  episode: const Episode(
    id: 'e1',
    podcastId: 'pod1',
    title: 'Episode',
    durationSec: 600,
  ),
  podcast: const Podcast(id: 'pod1', title: 'Podcast'),
);

/// One profile's storage and server.
final class _Profile {
  final StateDatabase db = StateDatabase(NativeDatabase.memory());
  late final DeviceSettingsDao settings = DeviceSettingsDao(db);
  final FakeSessionClient server = FakeApi().session;

  List<Override> get overrides => [
    deviceSettingsDaoProvider.overrideWithValue(settings),
    settingsRepositoryProvider.overrideWithValue(SettingsRepository(server)),
  ];
}

void main() {
  late _Profile profile;
  late FakeReachability reachability;

  setUp(() {
    profile = _Profile();
    reachability = FakeReachability();
  });
  tearDown(() => profile.db.close());

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    PlatformCapabilities capabilities = PlatformCapabilities.android,
    double textScale = 1.0,
    List<Override> overrides = const [],
    bool settle = true,
  }) async {
    final container = await tester.pumpApp(
      const Scaffold(body: PlaybackSettingsScreen()),
      textScale: textScale,
      overrides: [
        ...profile.overrides,
        reachabilityProvider.overrideWithValue(reachability),
        platformCapabilitiesProvider.overrideWithValue(capabilities),
        ...overrides,
      ],
    );
    if (settle) await tester.pumpAndSettle();
    return container;
  }

  /// The subtitle of the row titled [title].
  String? subtitleOf(WidgetTester tester, String title) {
    final tile = tester.widget<ListTile>(
      find.ancestor(of: find.text(title), matching: find.byType(ListTile)),
    );
    return switch (tile.subtitle) {
      final Text text => text.data,
      _ => null,
    };
  }

  ListTile tileOf(WidgetTester tester, String title) => tester.widget<ListTile>(
    find.ancestor(of: find.text(title), matching: find.byType(ListTile)),
  );

  /// Opens the row [title] and picks [option] from its list.
  Future<void> choose(WidgetTester tester, String title, String option) async {
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  testWidgets('every row shows its default on a fresh profile', (tester) async {
    await pump(tester);
    expect(subtitleOf(tester, 'Quality on Wi-Fi'), 'Server default');
    expect(subtitleOf(tester, 'Quality on mobile data'), 'Server default');
    expect(subtitleOf(tester, 'Volume levelling'), 'Off');
    expect(subtitleOf(tester, 'Skip interval (podcasts)'), '15 seconds');
    expect(subtitleOf(tester, 'Default speed (podcasts)'), '1×');
    expect(
      find.text('Quality changes apply from the next item that starts.'),
      findsOneWidget,
    );
  });

  for (final (label, stored) in [
    ('Server default', 'serverDefault'),
    ('Original', 'original'),
    ('High', 'high'),
    ('Medium', 'medium'),
    ('Low', 'low'),
  ]) {
    testWidgets('choosing $label writes "$stored" to both quality keys and '
        'survives a rebuilt provider graph', (tester) async {
      await pump(tester);
      await choose(tester, 'Quality on Wi-Fi', label);
      await choose(tester, 'Quality on mobile data', label);
      expect(await profile.settings.read(qualityWifiKey), stored);
      expect(await profile.settings.read(qualityCellularKey), stored);

      await tester.pumpWidget(const SizedBox.shrink());
      await pump(tester);
      expect(subtitleOf(tester, 'Quality on Wi-Fi'), label);
      expect(subtitleOf(tester, 'Quality on mobile data'), label);
    });
  }

  testWidgets('Server default carries a caption in the choice list', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Quality on Wi-Fi'));
    await tester.pumpAndSettle();
    expect(
      find.text('The quality saved on the server applies.'),
      findsOneWidget,
    );
  });

  testWidgets('the mobile-data row is shown on Android', (tester) async {
    await pump(tester);
    expect(find.text('Quality on mobile data'), findsOneWidget);
    expect(find.text('Quality on Wi-Fi'), findsOneWidget);
    expect(find.text('Streaming quality'), findsNothing);
  });

  testWidgets('on Linux there is one quality row, labelled Streaming '
      'quality, and its choices open as a menu', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await pump(
      tester,
      capabilities: PlatformCapabilities.forTarget(TargetPlatform.linux),
    );
    expect(find.text('Quality on mobile data'), findsNothing);
    expect(find.text('Quality on Wi-Fi'), findsNothing);
    expect(find.text('Streaming quality'), findsOneWidget);

    await tester.tap(find.text('Streaming quality'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    await tester.tap(find.text('Low').last);
    await tester.pumpAndSettle();
    expect(await profile.settings.read(qualityWifiKey), 'low');
    expect(subtitleOf(tester, 'Streaming quality'), 'Low');
    debugDefaultTargetPlatformOverride = null;
  });

  group('volume levelling', () {
    testWidgets('shows the server value; choosing Album posts it and shows '
        'it at once', (tester) async {
      profile.server.loudnessMode = 'track';
      final container = await pump(tester);
      expect(subtitleOf(tester, 'Volume levelling'), 'Track');

      final gate = profile.server.gate = Completer<void>();
      await tester.tap(find.text('Volume levelling'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Album').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(subtitleOf(tester, 'Volume levelling'), 'Album');

      gate.complete();
      profile.server.gate = null;
      await tester.pumpAndSettle();
      expect(profile.server.updates.map((u) => u.loudnessMode), [
        api.LoudnessMode.album,
      ]);
      expect(subtitleOf(tester, 'Volume levelling'), 'Album');
      expect(container.read(loudnessModeProvider), LoudnessMode.album);
    });

    testWidgets('a failing post restores the old value and shows a '
        'snackbar', (tester) async {
      profile.server.loudnessMode = 'track';
      profile.server.failures['updateSettings'] = const api.ServerError(
        status: 500,
      );
      final container = await pump(tester);

      await choose(tester, 'Volume levelling', 'Album');
      expect(subtitleOf(tester, 'Volume levelling'), 'Track');
      expect(find.text('Couldn’t change volume levelling'), findsOneWidget);
      expect(container.read(loudnessModeProvider), LoudnessMode.track);
    });

    testWidgets('the row is disabled with a tooltip while the server is not '
        'reachable', (tester) async {
      profile.server.loudnessMode = 'album';
      await pump(tester);
      expect(tileOf(tester, 'Volume levelling').enabled, isTrue);

      reachability.set(Reachability.serverUnreachable);
      await tester.pumpAndSettle();
      expect(tileOf(tester, 'Volume levelling').enabled, isFalse);
      expect(
        find.byTooltip('Available when the server can be reached'),
        findsOneWidget,
      );
      await tester.tap(find.text('Volume levelling'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Automatic'), findsNothing);

      reachability.set(Reachability.online);
      await tester.pumpAndSettle();
      expect(tileOf(tester, 'Volume levelling').enabled, isTrue);
    });

    testWidgets('a skeleton shows until the first value arrives', (
      tester,
    ) async {
      profile.server.loudnessMode = 'auto';
      final gate = profile.server.gate = Completer<void>();
      await pump(tester, settle: false);
      await tester.pump();
      expect(find.byKey(PlaybackSettingsScreen.levellingSkeletonKey), findsOne);
      expect(subtitleOf(tester, 'Volume levelling'), isNull);
      expect(tileOf(tester, 'Volume levelling').enabled, isFalse);

      gate.complete();
      await tester.pumpAndSettle();
      expect(
        find.byKey(PlaybackSettingsScreen.levellingSkeletonKey),
        findsNothing,
      );
      expect(subtitleOf(tester, 'Volume levelling'), 'Automatic');
    });
  });

  testWidgets('choosing a skip interval writes playback.skipSeconds', (
    tester,
  ) async {
    await pump(tester);
    await choose(tester, 'Skip interval (podcasts)', '30 seconds');
    expect(await profile.settings.read(skipSecondsKey), 30);
    expect(subtitleOf(tester, 'Skip interval (podcasts)'), '30 seconds');
  });

  group('default speed', () {
    late ControllerHarness h;

    setUp(() => h = ControllerHarness(ids: ['t', 'e']));

    testWidgets('writes playback.speed.podcast and applies it to a playing '
        'episode', (tester) async {
      final container = await pump(
        tester,
        overrides: [playbackControllerProvider.overrideWithValue(h.controller)],
      );
      // The player bar reads the controller once a queue exists.
      await tester.runAsync(
        () => container.read(playbackControllerProvider).playItems([
          _episode('e'),
        ]),
      );
      await tester.pumpAndSettle();

      await choose(tester, 'Default speed (podcasts)', '1.5×');
      await tester.runAsync(h.settle);
      expect(await profile.settings.read(podcastSpeedKey), 1.5);
      expect(subtitleOf(tester, 'Default speed (podcasts)'), '1.5×');
      expect(h.fake.speed, 1.5);
    });

    testWidgets('is not applied to a playing track', (tester) async {
      final container = await pump(
        tester,
        overrides: [playbackControllerProvider.overrideWithValue(h.controller)],
      );
      // The player bar reads the controller once a queue exists.
      await tester.runAsync(
        () =>
            container.read(playbackControllerProvider).playItems([_track('t')]),
      );
      await tester.pumpAndSettle();

      await choose(tester, 'Default speed (podcasts)', '2×');
      await tester.runAsync(h.settle);
      expect(await profile.settings.read(podcastSpeedKey), 2.0);
      expect(h.fake.speed, 1.0);
    });
  });

  testWidgets('a second profile sees its own values', (tester) async {
    final first = profile;
    await pump(tester);
    await choose(tester, 'Quality on Wi-Fi', 'Low');
    await choose(tester, 'Skip interval (podcasts)', '45 seconds');

    final second = _Profile();
    addTearDown(second.db.close);
    profile = second;
    await tester.pumpWidget(const SizedBox.shrink());
    await pump(tester);
    expect(subtitleOf(tester, 'Quality on Wi-Fi'), 'Server default');
    expect(subtitleOf(tester, 'Skip interval (podcasts)'), '15 seconds');

    profile = first;
    await tester.pumpWidget(const SizedBox.shrink());
    await pump(tester);
    expect(subtitleOf(tester, 'Quality on Wi-Fi'), 'Low');
    expect(subtitleOf(tester, 'Skip interval (podcasts)'), '45 seconds');
  });

  for (final scale in [1.0, 2.0]) {
    for (final theme in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets('meets the guidelines at text scale $scale, ${theme.name}', (
        tester,
      ) async {
        await tester.pumpApp(
          const Scaffold(body: PlaybackSettingsScreen()),
          textScale: scale,
          theme: theme,
          overrides: [
            ...profile.overrides,
            reachabilityProvider.overrideWithValue(reachability),
          ],
        );
        await tester.pumpAndSettle();
        await expectMeetsGuidelines(tester);
      });
    }
  }
}
