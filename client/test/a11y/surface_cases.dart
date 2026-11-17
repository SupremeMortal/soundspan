// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/gestures.dart' show PointerDeviceKind, kSecondaryButton;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/desktop/keep_playing_prompt.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/session/sign_out_participant.dart';
import 'package:soundspan/app/session/sign_out_sequence.dart';
import 'package:soundspan/app/shell/app_shell.dart';
import 'package:soundspan/app/shell/avatar_menu.dart';
import 'package:soundspan/app/shell/local_data_too_new_screen.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/connect/connect.dart';
import 'package:soundspan/features/downloads/ui/download_actions.dart';
import 'package:soundspan/features/listen_together/ui/listen_together_screen.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/features/podcasts/podcasts.dart';
import 'package:soundspan/shared/widgets/action_bar.dart';
import 'package:soundspan/shared/widgets/app_banner.dart';
import 'package:soundspan/shared/widgets/track_row.dart';
import 'package:soundspan_api/soundspan_api.dart' show ServerError;

import '../features/listen_together/ui/listen_together_ui_rig.dart';
import '../features/player/ui/player_rig.dart';
import '../helpers/fake_lyrics_repository.dart';
import '../helpers/fake_reachability.dart';
import '../helpers/pump_app.dart';
import 'registry_content.dart';
import 'screen_registry.dart';

/// The player bar's artist line in light: `contentSecondary` on
/// `surfaceRaised` (7.0:1), drawn too thin for the contrast sampler (see
/// `player_bar_test.dart` and doc 11, Golden Tests).
List<Finder> _playerBarArtist(PumpOptions options) => [
  if (options.theme == ThemeMode.light)
    find.descendant(
      of: find.byType(PlayerBar),
      matching: find.text('The Band a'),
    ),
];

/// Pumps a paused queue of a, b and c with lyrics for each, then opens
/// the right panel's [tooltip] on expanded windows, or on smaller ones the
/// now-playing screen and the sheet that button opens there.
Future<void> _pumpPlayerSurface(
  WidgetTester tester,
  PumpOptions options,
  String tooltip,
) async {
  final rig = PlayerRig();
  final lyrics = FakeLyricsRepository();
  for (final id in ['a', 'b', 'c']) {
    lyrics.byTitle['Song $id'] = const PlainLyrics(
      'The first line of the song\nA second line that is a little longer\n'
      'And a third',
    );
  }
  final overrides = [
    ...rig.overrides,
    lyricsRepositoryProvider.overrideWithValue(AsyncData(lyrics)),
    initialActiveProfileIdProvider.overrideWithValue(null),
  ];
  final expanded = windowClassOf(options.size) == WindowClass.expanded;
  final router = expanded
      ? null
      : GoRouter(
          initialLocation: RoutePaths.home,
          routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (_, _) => const Scaffold(body: Text('home page')),
            ),
            GoRoute(
              path: RoutePaths.nowPlaying,
              builder: (_, _) => const NowPlayingScreen(),
            ),
          ],
        );
  if (router != null) addTearDown(router.dispose);
  final container = await tester.pumpApp(
    router == null
        ? AppShell(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            onSearch: (_) {},
            child: const Center(child: Text('content')),
          )
        : Router.withConfig(config: router),
    size: options.size,
    theme: options.theme,
    overrides: overrides,
  );
  container.read(playbackControllerProvider);
  await rig.start(tester, play: false);
  if (router != null) unawaited(router.push<void>(RoutePaths.nowPlaying));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
  // Removes the widgets and disposes the controller before the test ends.
  addTearDown(() => rig.close(tester));
}

/// Pumps the signed-in app at [location], then runs [open].
Future<void> _pumpAndOpen(
  WidgetTester tester,
  PumpOptions options,
  String location,
  Future<void> Function() open, {
  RegistryContent? content,
  List<Override> overrides = const [],
}) async {
  await pumpRoute(
    tester,
    options,
    location,
    content: content,
    overrides: overrides,
  );
  await open();
  await tester.pumpAndSettle();
}

/// A context inside the app's navigator, for showing a dialog.
BuildContext _screenContext(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).last);

/// Shows the dialog [show] builds over the Home screen of the signed-in app.
ScreenCase _dialog(
  String name,
  void Function(BuildContext context, ProviderContainer root) show,
) => ScreenCase(
  name: name,
  pump: (tester, options) async {
    final root = await pumpRoute(tester, options, RoutePaths.home);
    show(_screenContext(tester), root.container);
    await tester.pumpAndSettle();
  },
);

/// A sign-out sequence that reports downloads and two pending changes for
/// every profile, so the dialogs show all their parts, and does nothing.
class _RegistrySignOut implements SignOutSequence {
  @override
  Future<int> pendingChanges(String profileId) async => 2;

  @override
  Future<DownloadsSummary?> downloadsSummary(String profileId) async =>
      const DownloadsSummary(itemCount: 42, bytes: 420 * 1024 * 1024);

  @override
  Future<void> signOut(
    String profileId, {
    bool removeDownloads = false,
  }) async {}

  @override
  Future<void> removeServer(String profileId) async {}
}

/// The first track row of the album the content holds.
Finder get _firstTrackRow => find.byType(TrackRow).first;

/// The cases for the surfaces that are not routes: sheets, menus, panels,
/// dialogs, the offline state of a Library tab and the error state of
/// Home.
final List<ScreenCase> surfaceCases = [
  ScreenCase(
    name: 'Queue panel or sheet',
    contrastSamplingExempt: _playerBarArtist,
    pump: (tester, options) => _pumpPlayerSurface(tester, options, 'Queue'),
  ),
  ScreenCase(
    name: 'Lyrics panel or sheet',
    contrastSamplingExempt: _playerBarArtist,
    pump: (tester, options) => _pumpPlayerSurface(tester, options, 'Lyrics'),
  ),
  ScreenCase(
    name: 'Avatar sheet or menu',
    // On expanded windows the popup covers the right end of the Home
    // headers' full-width text boxes, so the sampler reads the popup's
    // surface there; the headers are checked by the Home case.
    contrastSamplingExempt: (options) => [
      if (windowClassOf(options.size) == WindowClass.expanded)
        for (final header in ['Good morning', 'Continue Listening'])
          find.text(header),
    ],
    pump: (tester, options) => _pumpAndOpen(
      tester,
      options,
      RoutePaths.home,
      () => tester.tap(find.byKey(AvatarButton.buttonKey)),
    ),
  ),
  ScreenCase(
    name: 'Track menu sheet',
    pump: (tester, options) => _pumpAndOpen(
      tester,
      options,
      '${RoutePaths.home}/album/$registryId',
      () => tester.longPress(_firstTrackRow),
    ),
  ),
  ScreenCase(
    name: 'Track menu popup',
    pump: (tester, options) => _pumpAndOpen(
      tester,
      options,
      '${RoutePaths.home}/album/$registryId',
      () async {
        final mouse = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryButton,
        );
        addTearDown(mouse.removePointer);
        await mouse.down(tester.getCenter(_firstTrackRow));
        await mouse.up();
      },
    ),
  ),
  ScreenCase(
    name: 'Library songs offline',
    // The offline banner's line is `contentBody` on `surfaceActive`
    // (12:1); in light its 13 px glyphs are too thin for the sampler, as
    // `home_screen_test.dart` notes.
    contrastSamplingExempt: (options) => [
      if (options.theme == ThemeMode.light)
        find.descendant(
          of: find.byType(AppBanner),
          matching: find.byType(Text),
        ),
    ],
    pump: (tester, options) => pumpRoute(
      tester,
      options,
      '${RoutePaths.library}/songs',
      overrides: [
        reachabilityProvider.overrideWithValue(
          FakeReachability(initial: Reachability.noNetwork),
        ),
      ],
    ),
  ),
  ScreenCase(
    name: 'Home error',
    pump: (tester, options) {
      final content = RegistryContent();
      content.repositories.home.errors.addAll({
        for (final method in [
          'recentlyListened',
          'recentlyAdded',
          'mixes',
          'topPodcasts',
        ])
          method: const ServerError(status: 500),
      });
      return pumpRoute(tester, options, RoutePaths.home, content: content);
    },
  ),
  // Confirmation dialogs.
  _dialog(
    'Remove download dialog',
    (context, _) => unawaited(confirmRemoveDownload(context)),
  ),
  _dialog(
    'Keep playing dialog',
    (context, _) => unawaited(showKeepPlayingDialog(context)),
  ),
  ScreenCase(
    name: 'Delete playlist dialog',
    pump: (tester, options) => _pumpAndOpen(
      tester,
      options,
      '${RoutePaths.home}/playlist/$registryId',
      () async {
        await tester.tap(find.byKey(ActionBar.menuKey));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete').last);
      },
    ),
  ),
  for (final label in ['Sign out', 'Remove this server'])
    ScreenCase(
      name: '$label dialog',
      pump: (tester, options) => _pumpAndOpen(
        tester,
        options,
        RoutePaths.settingsServers,
        overrides: [
          signOutSequenceProvider.overrideWithValue(_RegistrySignOut()),
        ],
        () async {
          await tester.ensureVisible(find.text(label).first);
          await tester.tap(find.text(label).first);
        },
      ),
    ),
  ScreenCase(
    name: 'Clear cache dialog',
    pump: (tester, options) =>
        _pumpAndOpen(tester, options, RoutePaths.settingsStorage, () async {
          await tester.ensureVisible(find.text('Clear cache').first);
          await tester.tap(find.text('Clear cache').first);
        }),
  ),
  ScreenCase(
    name: 'Unsubscribe dialog',
    pump: (tester, options) => _pumpAndOpen(
      tester,
      options,
      '${RoutePaths.podcasts}/$registryId',
      () => tester.tap(find.byKey(PodcastDetailScreen.subscriptionKey)),
    ),
  ),
  ScreenCase(
    name: 'Public cleartext dialog',
    pump: (tester, options) =>
        _pumpAndOpen(tester, options, RoutePaths.connect, () async {
          await tester.enterText(
            find.byKey(AddressScreen.addressFieldKey),
            'http://music.example.com',
          );
          await tester.testTextInput.receiveAction(TextInputAction.go);
        }),
  ),
  ScreenCase(
    name: 'Reset local data dialog',
    pump: (tester, options) async {
      await tester.pumpApp(
        const LocalDataTooNewScreen(profileId: 'p1'),
        size: options.size,
        theme: options.theme,
      );
      await tester.tap(find.text('Reset this server’s local data'));
      await tester.pumpAndSettle();
    },
  ),
  ScreenCase(
    name: 'End group dialog',
    pump: (tester, options) async {
      final controller = FakeListenTogetherController();
      final repository = FakeListenTogetherRepository()
        ..myGroup = sampleGroup(hostUserId: me);
      await tester.pumpApp(
        WindowClassScope(
          windowClass: windowClassOf(options.size),
          child: const ListenTogetherScreen(),
        ),
        size: options.size,
        theme: options.theme,
        overrides: [
          ...listenTogetherOverrides(controller, repository),
          profilesProvider.overrideWith(
            (ref) => Stream.value(const <Profile>[]),
          ),
          initialActiveProfileIdProvider.overrideWithValue(null),
        ],
      );
      controller.emit(activeOf(sampleGroup(hostUserId: me)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(ListenTogetherScreen.endKey));
      await tester.tap(find.byKey(ListenTogetherScreen.endKey));
      await tester.pumpAndSettle();
    },
  ),
];
