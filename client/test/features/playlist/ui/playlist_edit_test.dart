// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/app_shell.dart';
import 'package:soundspan/app/shell/sidebar_playlists.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/features/library/ui/playlists_tab.dart';
import 'package:soundspan/features/playlist/playlist.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import '../../detail_fixtures.dart';
import '../../library/library_harness.dart';

PlaylistDetail _detail(
  String id, {
  String name = 'Road Trip',
  bool isOwner = true,
  int items = 3,
}) => PlaylistDetail(
  summary: PlaylistSummary(
    id: id,
    name: name,
    trackCount: items,
    isOwner: isOwner,
    isPublic: false,
  ),
  items: [
    for (var n = 1; n <= items; n++)
      PlaylistItem(
        id: 'item-$n',
        sort: n,
        track: fixtureTrack(n),
        isPlayable: true,
      ),
  ],
);

/// Pumps a button that runs [action] with the context and ref of the app.
Future<ProviderContainer> _pumpLauncher(
  WidgetTester tester,
  Future<void> Function(BuildContext context, WidgetRef ref) action, {
  FakeRepositories? repositories,
  Size size = TestSizes.compact,
  ThemeMode theme = ThemeMode.dark,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  // The tester's default platform is Android; a test that picks another
  // one resets the override at its end.
  if (platform != TargetPlatform.android) {
    debugDefaultTargetPlatformOverride = platform;
  }
  final container = await tester.pumpApp(
    Scaffold(
      body: Consumer(
        builder: (context, ref, _) => Center(
          child: TextButton(
            onPressed: () => action(context, ref),
            child: const Text('launch'),
          ),
        ),
      ),
    ),
    size: size,
    theme: theme,
    overrides: [...?repositories?.overrides],
  );
  return container;
}

Future<void> _launch(WidgetTester tester) async {
  await tester.tap(find.text('launch'));
  await tester.pumpAndSettle();
}

/// Types [name] into the open name dialog and confirms it.
Future<void> _enterName(WidgetTester tester, String name) async {
  await tester.enterText(find.byKey(PlaylistNameDialog.fieldKey), name);
  await tester.pump();
  await tester.tap(find.byKey(PlaylistNameDialog.confirmKey));
  await tester.pumpAndSettle();
}

void main() {
  group('PlaylistNameDialog', () {
    testWidgets('confirm is disabled for an empty name and pops the trimmed '
        'name', (tester) async {
      String? answer = 'unset';
      await _pumpLauncher(tester, (context, _) async {
        answer = await PlaylistNameDialog.showCreate(context);
      });
      await _launch(tester);

      FilledButton confirm() => tester.widget<FilledButton>(
        find.byKey(PlaylistNameDialog.confirmKey),
      );
      expect(find.text('New playlist'), findsOneWidget);
      expect(confirm().onPressed, isNull);
      await tester.enterText(find.byKey(PlaylistNameDialog.fieldKey), '   ');
      await tester.pump();
      expect(confirm().onPressed, isNull);
      await tester.enterText(find.byKey(PlaylistNameDialog.fieldKey), ' Road ');
      await tester.pump();
      expect(confirm().onPressed, isNotNull);

      await tester.tap(find.byKey(PlaylistNameDialog.confirmKey));
      await tester.pumpAndSettle();
      expect(answer, 'Road');
    });

    testWidgets('rename starts with the name; Cancel pops null', (
      tester,
    ) async {
      String? answer = 'unset';
      await _pumpLauncher(tester, (context, _) async {
        answer = await PlaylistNameDialog.showRename(context, 'Road Trip');
      });
      await _launch(tester);

      expect(find.text('Rename playlist'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(PlaylistNameDialog.fieldKey))
            .controller!
            .text,
        'Road Trip',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(answer, isNull);
    });

    testWidgets('meets the guidelines', (tester) async {
      await _pumpLauncher(tester, (context, _) async {
        await PlaylistNameDialog.showCreate(context);
      });
      await _launch(tester);
      await expectMeetsGuidelines(tester);
    });
  });

  group('DeletePlaylistDialog', () {
    for (final (label, expected) in [('Delete', true), ('Cancel', false)]) {
      testWidgets('$label answers $expected', (tester) async {
        bool? answer;
        await _pumpLauncher(tester, (context, _) async {
          answer = await DeletePlaylistDialog.show(context, 'Road Trip');
        });
        await _launch(tester);

        expect(find.text('Delete Road Trip?'), findsOneWidget);
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(answer, expected);
      });
    }

    testWidgets('meets the guidelines', (tester) async {
      await _pumpLauncher(tester, (context, _) async {
        await DeletePlaylistDialog.show(context, 'Road Trip');
      });
      await _launch(tester);
      await expectMeetsGuidelines(tester);
    });
  });

  group('AddToPlaylistPicker', () {
    FakeRepositories repositories() => FakeRepositories(
      playlists: FakePlaylistRepository()
        ..playlistList = [
          ...playlists(2),
          const PlaylistSummary(
            id: 'theirs',
            name: 'Not Mine',
            trackCount: 1,
            isOwner: false,
            isPublic: true,
          ),
        ],
    );

    for (final (platform, sheet) in [
      (TargetPlatform.android, true),
      (TargetPlatform.linux, false),
    ]) {
      testWidgets('lists own playlists only on ${platform.name} '
          '(${sheet ? 'sheet' : 'dialog'})', (tester) async {
        PlaylistSummary? answer;
        await _pumpLauncher(
          tester,
          (context, _) async {
            answer = await AddToPlaylistPicker.show(context);
          },
          repositories: repositories(),
          platform: platform,
        );
        await _launch(tester);

        expect(find.byType(BottomSheet), sheet ? findsOneWidget : findsNothing);
        expect(find.byType(Dialog), sheet ? findsNothing : findsOneWidget);
        expect(find.text('Playlist 0'), findsOneWidget);
        expect(find.text('Playlist 1'), findsOneWidget);
        expect(find.text('Not Mine'), findsNothing);
        await tester.tap(find.text('Playlist 1'));
        await tester.pumpAndSettle();
        expect(answer?.id, 'pl1');
        debugDefaultTargetPlatformOverride = null;
      });
    }

    testWidgets('"New playlist" creates one, then answers it', (tester) async {
      final repos = repositories();
      repos.playlists.createdId = 'tmp_x';
      PlaylistSummary? answer;
      await _pumpLauncher(tester, (context, _) async {
        answer = await AddToPlaylistPicker.show(context);
      }, repositories: repos);
      await _launch(tester);

      await tester.tap(find.byKey(AddToPlaylistPicker.newKey));
      await tester.pumpAndSettle();
      await _enterName(tester, 'Fresh');

      expect(repos.playlists.edits, ['create Fresh']);
      expect(answer?.id, 'tmp_x');
      expect(answer?.name, 'Fresh');
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('adding confirms "Added N to name"', (tester) async {
      final repos = repositories();
      int? added;
      await _pumpLauncher(tester, (context, ref) async {
        added = await addTracksToPlaylist(context, ref, [
          fixtureTrack(1),
          fixtureTrack(2),
          fixtureTrack(3, playable: false),
        ]);
      }, repositories: repos);
      await _launch(tester);

      await tester.tap(find.text('Playlist 0'));
      await tester.pumpAndSettle();

      expect(added, 2);
      expect(repos.playlists.edits, ['add pl0 p-1-1,p-1-2']);
      expect(find.text('Added 2 songs to Playlist 0'), findsOneWidget);
    });

    testWidgets('meets the guidelines', (tester) async {
      await _pumpLauncher(tester, (context, _) async {
        await AddToPlaylistPicker.show(context);
      }, repositories: repositories());
      await _launch(tester);
      await expectMeetsGuidelines(tester);
    });
  });

  group('create entry points', () {
    testWidgets('the Library tab creates and opens the new playlist', (
      tester,
    ) async {
      final repository = FakePlaylistRepository()
        ..playlistList = playlists(1)
        ..createdId = 'tmp_new'
        ..playlistDetails['tmp_new'] = _detail(
          'tmp_new',
          name: 'Road',
          items: 0,
        );
      final harness = await tester.pumpLibrary(
        tab: LibraryTab.playlists,
        playlists: repository,
      );

      await tester.tap(find.byKey(PlaylistsTab.newKey));
      await tester.pumpAndSettle();
      await _enterName(tester, 'Road');

      expect(repository.edits, ['create Road']);
      expect(harness.location, '/library/playlists/playlist/tmp_new');
      expect(find.byType(PlaylistScreen), findsOneWidget);
    });

    testWidgets('the sidebar creates and opens the new playlist', (
      tester,
    ) async {
      final repository = FakePlaylistRepository()
        ..playlistList = playlists(1)
        ..createdId = 'tmp_new';
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => AppShell(
              selectedIndex: 2,
              onDestinationSelected: (_) {},
              onSearch: (_) {},
              child: const SizedBox.expand(),
            ),
          ),
          GoRoute(
            path: '/playlist/:playlistId',
            builder: (_, state) =>
                Text('opened ${state.pathParameters['playlistId']}'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpApp(
        Router.withConfig(config: router),
        size: TestSizes.expanded,
        overrides: <Override>[
          ...FakeRepositories(playlists: repository).overrides,
          profilesProvider.overrideWith(
            (ref) => Stream.value(const <Profile>[]),
          ),
          initialActiveProfileIdProvider.overrideWithValue(null),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(SidebarPlaylists.createKey));
      await tester.pumpAndSettle();
      await _enterName(tester, 'Road');

      expect(repository.edits, ['create Road']);
      expect(find.text('opened tmp_new'), findsOneWidget);
    });
  });

  group('playlist page', () {
    testWidgets('dragging a row by its handle reorders once', (tester) async {
      final repositories = FakeRepositories();
      repositories.playlists.playlistDetails['pl-1'] = _detail('pl-1');
      await pumpDetail(
        tester,
        const PlaylistScreen(playlistId: 'pl-1'),
        repositories: repositories,
      );

      final handle = find.byIcon(Icons.drag_handle_rounded);
      expect(handle, findsNWidgets(3));
      final gesture = await tester.startGesture(tester.getCenter(handle.first));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, 20));
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(repositories.playlists.edits, hasLength(1));
      expect(repositories.playlists.edits.single, startsWith('reorder pl-1 '));
      expect(
        repositories.playlists.edits.single,
        isNot('reorder pl-1 p-1-1,p-1-2,p-1-3'),
      );
    });

    testWidgets('a non-owner has no drag handle', (tester) async {
      final repositories = FakeRepositories();
      repositories.playlists.playlistDetails['pl-1'] = _detail(
        'pl-1',
        isOwner: false,
      );
      await pumpDetail(
        tester,
        const PlaylistScreen(playlistId: 'pl-1'),
        repositories: repositories,
      );

      expect(find.text('Song 1.1'), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle_rounded), findsNothing);
      expect(find.byType(ReorderableDragStartListener), findsNothing);
    });

    testWidgets('a temporary playlist stays mounted and shows the real id '
        'after it is resolved', (tester) async {
      final repository = FakePlaylistRepository()
        ..createdId = 'tmp_new'
        ..playlistDetails['tmp_new'] = _detail(
          'tmp_new',
          name: 'Road',
          items: 0,
        )
        ..playlistDetails['pl-9'] = _detail('pl-9', name: 'Road', items: 1);
      final harness = await tester.pumpLibrary(
        tab: LibraryTab.playlists,
        playlists: repository,
      );
      await tester.tap(find.byKey(PlaylistsTab.newKey));
      await tester.pumpAndSettle();
      await _enterName(tester, 'Road');
      final state = tester.state(find.byType(PlaylistScreen));
      expect(find.text('This playlist has no songs yet'), findsOneWidget);

      repository.resolved.add((tempId: 'tmp_new', realId: 'pl-9'));
      await tester.pumpAndSettle();

      expect(tester.state(find.byType(PlaylistScreen)), same(state));
      expect(harness.router.state.pathParameters['playlistId'], 'pl-9');
      expect(find.text('Song 1.1'), findsOneWidget);
    });
  });

  group('PlaylistViewModel', () {
    late FakePlaylistRepository repository;
    late PlaylistViewModel viewModel;

    setUp(() {
      repository = FakePlaylistRepository();
      viewModel = PlaylistViewModel(() async => repository, 'pl-1');
    });

    test(
      'rename, delete, removeItem and addTracks go to the repository',
      () async {
        final item = _detail('pl-1').items.first;
        await viewModel.rename('New');
        await viewModel.removeItem(item);
        expect(await viewModel.addTracks([fixtureTrack(4)]), 1);
        await viewModel.delete();

        expect(repository.edits, [
          'rename pl-1 New',
          'remove pl-1 item-1',
          'add pl-1 p-1-4',
          'delete pl-1',
        ]);
      },
    );

    test(
      'reorder sends the full order once, and nothing for no move',
      () async {
        final items = _detail('pl-1').items;
        await viewModel.reorder(items, 0, 2);
        await viewModel.reorder(items, 1, 1);

        expect(repository.edits, ['reorder pl-1 p-1-2,p-1-3,p-1-1']);
      },
    );
  });
}
