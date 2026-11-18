// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/features/mixes/mixes.dart';
import 'package:soundspan/features/playlist/playlist.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/capability_refresh.dart';
import 'package:soundspan/shared/providers/play_actions.dart';
import 'package:soundspan/shared/widgets/action_bar.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan/shared/widgets/mosaic_artwork.dart';
import 'package:soundspan/shared/widgets/track_row.dart';
import 'package:soundspan_api/soundspan_api.dart'
    show FeatureDisabled, Offline, ServerError;

import '../../../app/shell/shortcuts/selection_harness.dart';
import '../../../helpers/fake_mix_repository.dart';
import '../../../helpers/fake_reachability.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import '../../detail_fixtures.dart';

class _FixedCapabilities extends ServerCapabilitiesNotifier {
  new(this._value);

  final ServerCapabilities _value;

  @override
  ServerCapabilities build() => _value;
}

/// Records the commands the screen sends to playback.
class _RecordingController extends Fake implements PlaybackController {
  final List<bool> shuffles = [];
  final List<(List<QueueItem>, int, QueueContext?)> plays = [];

  @override
  Future<void> setShuffle(bool enabled) async => shuffles.add(enabled);

  @override
  Future<void> playItems(
    List<QueueItem> items, {
    int startIndex = 0,
    QueueContext? context,
  }) async => plays.add((items, startIndex, context));
}

MixDetail _mix({List<Track>? tracks, String? description = 'Upbeat picks'}) =>
    MixDetail(
      id: 'm1',
      name: 'Daily Mix 1',
      description: description,
      artworkRefs: const ['c1', 'c2', 'c3', 'c4', 'c5'],
      tracks:
          tracks ??
          [
            fixtureTrack(1, artworkRef: 'cover-1'),
            fixtureTrack(2, artworkRef: 'cover-2', playable: false),
            fixtureTrack(3, artworkRef: 'cover-3'),
          ],
    );

const _mixContext = QueueContext(
  kind: QueueContextKind.mix,
  id: 'm1',
  title: 'Daily Mix 1',
);

List<String?> _titles(List<QueueItem> items) => [
  for (final item in items) (item as TrackQueueItem).track.meta.title,
];

void main() {
  late FakeMixRepository mixes;
  late FakeRepositories repositories;
  late FakeReachability reachability;
  late _RecordingController controller;
  late int capabilityRefreshes;

  setUp(() {
    mixes = FakeMixRepository()..mixes['m1'] = _mix();
    repositories = FakeRepositories();
    reachability = FakeReachability();
    controller = _RecordingController();
    capabilityRefreshes = 0;
  });

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  Future<GoRouter> pump(
    WidgetTester tester, {
    String mixId = 'm1',
    bool autoPlaylists = true,
    Size size = TestSizes.compact,
    ThemeMode theme = ThemeMode.dark,
    double textScale = 1.0,
    bool shellShortcuts = false,
  }) async {
    Widget scoped(Widget child) => Builder(
      builder: (context) => WindowClassScope(
        windowClass: windowClassOf(MediaQuery.sizeOf(context)),
        child: child,
      ),
    );
    final router = GoRouter(
      initialLocation: '/mix/$mixId',
      routes: [
        GoRoute(
          path: '/mix/:mixId',
          builder: (_, state) =>
              scoped(MixDetailScreen(mixId: state.pathParameters['mixId']!)),
        ),
        GoRoute(
          path: '/playlist/:playlistId',
          builder: (_, state) =>
              Text('playlist page ${state.pathParameters['playlistId']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    final notices = StreamController<PlayNotice>.broadcast();
    addTearDown(notices.close);
    final overrides = <Override>[
      ...repositories.overrides,
      mixes.providerOverride,
      serverCapabilitiesProvider.overrideWith(
        () => _FixedCapabilities(
          ServerCapabilities(
            serverVersion: Version.tryParse('2.7.0'),
            hasP6SelfRevoke: true,
            hasP7PlayMarker: true,
            hasP8PlayedAt: true,
            autoPlaylists: autoPlaylists,
          ),
        ),
      ),
      capabilityRefreshProvider.overrideWithValue(() => capabilityRefreshes++),
      playbackControllerProvider.overrideWithValue(controller),
      playNoticesProvider.overrideWithValue(notices),
      profilesProvider.overrideWith((ref) => Stream.value(const <Profile>[])),
      initialActiveProfileIdProvider.overrideWithValue(null),
      reachabilityProvider.overrideWithValue(reachability),
    ];
    final app = Router.withConfig(config: router);
    await tester.pumpApp(
      shellShortcuts ? underShellShortcuts(app) : app,
      size: size,
      theme: theme,
      textScale: textScale,
      overrides: overrides,
    );
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pumpAndSettle();
    return router;
  }

  List<TrackRow> rows(WidgetTester tester) =>
      tester.widgetList<TrackRow>(find.byType(TrackRow)).toList();

  IconButton saveButton(WidgetTester tester) =>
      tester.widget<IconButton>(find.byKey(ActionBar.saveAsPlaylistKey));

  group('enabled', () {
    testWidgets('shows the header and the rows; a track without a '
        'playbackId is disabled', (tester) async {
      await pump(tester);

      expect(find.text('Daily Mix 1'), findsOneWidget);
      expect(find.text('MIX'), findsOneWidget);
      expect(find.text('Upbeat picks'), findsOneWidget);
      expect(find.textContaining('3 songs'), findsOneWidget);
      expect(tester.widget<MosaicArtwork>(find.byType(MosaicArtwork)).refs, [
        'c1',
        'c2',
        'c3',
        'c4',
      ]);
      expect(
        [for (final row in rows(tester)) row.enabled],
        [true, false, true],
      );
      expect(find.byKey(ActionBar.likeKey), findsNothing);
      expect(mixes.calls, ['mix m1']);
    });

    testWidgets('rows have the album column only on expanded windows', (
      tester,
    ) async {
      await pump(tester, size: TestSizes.expanded);
      expect(rows(tester).first.showAlbumColumn, isTrue);
    });

    testWidgets('Play queues every playable track with the mix context', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.byKey(ActionBar.playKey));
      await tester.pumpAndSettle();

      expect(controller.shuffles, isEmpty);
      final (items, start, context) = controller.plays.single;
      expect(_titles(items), ['Song 1.1', 'Song 1.3']);
      expect(start, 0);
      expect(context, _mixContext);
    });

    testWidgets('Shuffle sets shuffle and queues the playable tracks', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.byKey(ActionBar.shuffleKey));
      await tester.pumpAndSettle();

      expect(controller.shuffles, [true]);
      final (items, _, context) = controller.plays.single;
      expect(_titles(items), ['Song 1.1', 'Song 1.3']);
      expect(context?.kind, QueueContextKind.mix);
    });

    testWidgets('a row plays the mix from it', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Song 1.3'));
      await tester.pumpAndSettle();

      final (items, start, context) = controller.plays.single;
      expect(_titles(items), ['Song 1.1', 'Song 1.3']);
      expect(start, 1);
      expect(context, _mixContext);
    });

    testWidgets('an empty mix shows its empty state and no playing actions', (
      tester,
    ) async {
      mixes.mixes['m1'] = _mix(tracks: const []);
      await pump(tester);

      expect(find.text('This mix has no tracks right now'), findsOneWidget);
      expect(find.byKey(ActionBar.playKey), findsNothing);
      expect(saveButton(tester).onPressed, isNull);
    });

    testWidgets('a failed read with nothing cached shows the error view '
        'with Retry', (tester) async {
      mixes.errors['m1'] = const ServerError(status: 500);
      await pump(tester);

      expect(find.byType(ErrorView), findsOneWidget);
      mixes.errors.clear();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.byType(TrackRow), findsNWidgets(3));
    });

    testWidgets('offline, the cached mix shows under the offline banner', (
      tester,
    ) async {
      reachability.set(Reachability.serverUnreachable);
      mixes.refreshErrors['m1'] = const Offline();
      await pump(tester);

      expect(find.byType(TrackRow), findsNWidgets(3));
      expect(
        find.text(
          'Can’t reach the server. Showing what’s saved on this device.',
        ),
        findsOneWidget,
      );
      expect(find.byType(ErrorView), findsNothing);
    });
  });

  group('disabled', () {
    testWidgets('shows the neutral view without asking the API', (
      tester,
    ) async {
      await pump(tester, mixId: 'abc', autoPlaylists: false);

      expect(find.text('Not available on this server'), findsOneWidget);
      expect(find.byType(TrackRow), findsNothing);
      expect(mixes.calls, isEmpty);
    });
  });

  testWidgets('FeatureDisabled shows the neutral view and requests a '
      'capability refresh', (tester) async {
    mixes.errors['m1'] = const FeatureDisabled(status: 404);
    await pump(tester);

    expect(find.text('Not available on this server'), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
    expect(capabilityRefreshes, 1);
  });

  testWidgets('FeatureDisabled refreshing a cached mix shows the neutral '
      'view and requests a capability refresh', (tester) async {
    mixes.refreshErrors['m1'] = const FeatureDisabled(status: 404);
    await pump(tester);

    expect(find.text('Not available on this server'), findsOneWidget);
    expect(find.byType(TrackRow), findsNothing);
    expect(capabilityRefreshes, 1);
  });

  group('Save as playlist', () {
    testWidgets('the dialog is prefilled; confirming creates the playlist '
        'and adds the playable tracks in mix order', (tester) async {
      final router = await pump(tester);

      await tester.tap(find.byKey(ActionBar.saveAsPlaylistKey));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.byKey(PlaylistNameDialog.fieldKey),
      );
      expect(field.controller!.text, 'Daily Mix 1');
      await tester.tap(find.byKey(PlaylistNameDialog.confirmKey));
      await tester.pumpAndSettle();

      expect(repositories.playlists.edits, [
        'create Daily Mix 1',
        'add tmp_new p-1-1,p-1-3',
      ]);
      expect(find.text('Saved to your playlists'), findsOneWidget);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(location(router), '/playlist/tmp_new');
      expect(find.text('playlist page tmp_new'), findsOneWidget);
    });

    testWidgets('cancelling saves nothing', (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(ActionBar.saveAsPlaylistKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repositories.playlists.edits, isEmpty);
    });

    testWidgets('is disabled for a mix with no playable track', (tester) async {
      mixes.mixes['m1'] = _mix(tracks: [fixtureTrack(1, playable: false)]);
      await pump(tester);

      expect(find.byKey(ActionBar.saveAsPlaylistKey), findsOneWidget);
      expect(saveButton(tester).onPressed, isNull);
    });
  });

  for (final size in [TestSizes.compact, TestSizes.expanded]) {
    for (final theme in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets('meets the screen guidelines at ${size.width.toInt()} in '
          '${theme.name}', (tester) async {
        await pump(tester, size: size, theme: theme);
        await expectMeetsGuidelines(tester);
      });
    }
  }

  testWidgets('lays out without overflow at text scale 2.0 at 390', (
    tester,
  ) async {
    await pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the neutral view meets the screen guidelines', (tester) async {
    await pump(tester, autoPlaylists: false);
    await expectMeetsGuidelines(tester);
    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('rows select on click, Ctrl+click adds a row, Enter plays the '
      'selection and the menu is the selection menu', (tester) async {
    mixes.mixes['m1'] = _mix(
      tracks: [fixtureTrack(1), fixtureTrack(2), fixtureTrack(3)],
    );
    await pump(tester, size: TestSizes.expanded, shellShortcuts: true);

    await click(tester, 'Song 1.3');
    expect(selectedTitles(tester), ['Song 1.3']);
    expect(controller.plays, isEmpty);
    await click(tester, 'Song 1.1', modifier: LogicalKeyboardKey.controlLeft);
    expect(selectedTitles(tester), ['Song 1.1', 'Song 1.3']);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    final (items, start, context) = controller.plays.single;
    expect(_titles(items), ['Song 1.1', 'Song 1.3']);
    expect(start, 0);
    expect(context, _mixContext);
    await expectSelectionMenu(tester, 'Song 1.3');
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
