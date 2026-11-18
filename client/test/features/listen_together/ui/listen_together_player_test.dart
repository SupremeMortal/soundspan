// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/playback/playback_command.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/listen_together/domain/group.dart';
import 'package:soundspan/features/listen_together/domain/listen_together_state.dart';
import 'package:soundspan/features/listen_together/listen_together.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/shared/widgets/action_bar.dart';
import 'package:soundspan/shared/widgets/group_controls.dart';

import '../../../helpers/pump_app.dart';
import '../../player/ui/player_rig.dart';
import 'listen_together_ui_rig.dart';

/// Records the commands routed to it while attached.
class _Driver implements RemoteDriver {
  final List<PlaybackCommand> commands = [];

  @override
  Future<void> onCommand(PlaybackCommand command) async =>
      commands.add(command);

  @override
  void onCurrentItemFailed(String queueItemId) {}
}

const String _host = 'The host controls playback';

void main() {
  late FakeListenTogetherController listenTogether;
  late FakeListenTogetherRepository repository;
  late PlayerRig rig;
  late _Driver driver;

  setUp(() {
    listenTogether = FakeListenTogetherController();
    repository = FakeListenTogetherRepository();
    driver = _Driver();
  });

  /// Creates [rig] (inside the test, so its timers run on the test's
  /// clock) and the overrides of it and the fakes.
  List<Override> overrides() {
    rig = PlayerRig();
    return [
      ...rig.overrides,
      ...listenTogetherOverrides(listenTogether, repository),
    ];
  }

  /// Starts playback, then joins [group] as this device: attached, in
  /// control unless a follower.
  Future<void> joinGroup(
    WidgetTester tester,
    Group group, {
    Set<PlaybackCommand> pending = const {},
  }) async {
    // The profile's playback controller exists in the app before any of
    // these surfaces show.
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
        .read(playbackControllerProvider);
    await rig.start(tester);
    rig.controller
      ..attachRemoteDriver(driver)
      ..setRemoteCanControl(group.canControl(me));
    listenTogether.emit(activeOf(group, pending: pending));
    await rig.settle(tester);
  }

  SemanticsData semanticsOf(WidgetTester tester, Finder finder) =>
      tester.getSemantics(finder).getSemanticsData();

  void expectLocked(WidgetTester tester, Finder control) {
    final data = semanticsOf(tester, control);
    expect(data.hint, contains(_host));
    expect(data.flagsCollection.isEnabled, Tristate.isFalse);
  }

  group('follower', () {
    testWidgets('PlayerBar: transport and seek are locked; volume is not', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        const Align(alignment: Alignment.bottomCenter, child: PlayerBar()),
        size: TestSizes.expanded,
        overrides: overrides(),
      );
      await joinGroup(tester, sampleGroup());

      expectLocked(tester, find.byKey(PlayerTransport.previousKey));
      expectLocked(tester, find.byKey(PlayerTransport.playPauseKey));
      expectLocked(tester, find.byKey(PlayerTransport.nextKey));
      expectLocked(tester, find.byType(SeekBar));
      expect(find.byTooltip('Shuffle'), findsNothing);
      expect(find.byTooltip('Repeat'), findsNothing);
      expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNotNull);

      await tester.tap(
        find.byKey(PlayerTransport.nextKey),
        warnIfMissed: false,
      );
      await rig.settle(tester);
      expect(driver.commands, isEmpty);
      handle.dispose();
      await rig.close(tester);
    });

    testWidgets('MiniPlayer: play/pause and next are locked', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        const Align(alignment: Alignment.bottomCenter, child: MiniPlayer()),
        overrides: overrides(),
      );
      await joinGroup(tester, sampleGroup());

      expectLocked(tester, find.byKey(MiniPlayer.playPauseKey));
      expectLocked(tester, find.byKey(MiniPlayer.nextKey));
      handle.dispose();
      await rig.close(tester);
    });

    testWidgets('now playing: transport and seek locked; lyrics enabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        const WindowClassScope(
          windowClass: WindowClass.compact,
          child: NowPlayingScreen(),
        ),
        overrides: overrides(),
      );
      await joinGroup(tester, sampleGroup());

      expectLocked(tester, find.byKey(PlayerTransport.playPauseKey));
      expectLocked(tester, find.byKey(PlayerTransport.nextKey));
      expectLocked(tester, find.byType(SeekBar));
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byIcon(Icons.lyrics_outlined),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNotNull,
      );
      handle.dispose();
      await rig.close(tester);
    });

    testWidgets('the album Play action is disabled with the host tooltip', (
      tester,
    ) async {
      var plays = 0;
      await tester.pumpApp(
        WindowClassScope(
          windowClass: WindowClass.compact,
          child: Center(child: ActionBar(onPlay: () => plays++)),
        ),
        overrides: overrides(),
      );
      await joinGroup(tester, sampleGroup());

      expect(
        tester.widget<ButtonStyleButton>(find.byKey(ActionBar.playKey)).enabled,
        isFalse,
      );
      expect(find.byTooltip(_host), findsOneWidget);
      expect(plays, 0);
      await rig.close(tester);
    });
  });

  group('host or collaborative member', () {
    testWidgets('controls work; shuffle and repeat are hidden', (tester) async {
      await tester.pumpApp(
        const Align(alignment: Alignment.bottomCenter, child: PlayerBar()),
        size: TestSizes.expanded,
        overrides: overrides(),
      );
      await joinGroup(tester, sampleGroup(type: GroupType.collaborative));

      expect(find.byTooltip('Shuffle'), findsNothing);
      expect(find.byTooltip('Repeat'), findsNothing);
      await tester.tap(find.byTooltip('Next'));
      await rig.settle(tester);
      expect(driver.commands.single, isA<NextCommand>());
      expect(find.byTooltip(_host), findsNothing);
      await rig.close(tester);
    });

    testWidgets('a pending command shows the spinner in its control', (
      tester,
    ) async {
      await tester.pumpApp(
        const Align(alignment: Alignment.bottomCenter, child: PlayerBar()),
        size: TestSizes.expanded,
        overrides: overrides(),
      );
      await joinGroup(
        tester,
        sampleGroup(hostUserId: me),
        pending: {const NextCommand()},
      );

      expect(
        find.descendant(
          of: find.byKey(PlayerTransport.nextKey),
          matching: find.byKey(GroupCommandSpinner.spinnerKey),
        ),
        findsOneWidget,
      );
      expect(find.byKey(GroupCommandSpinner.spinnerKey), findsOneWidget);
      await rig.close(tester);
    });

    testWidgets('a failed command shows a snackbar', (tester) async {
      await tester.pumpApp(
        const Scaffold(body: ListenTogetherNoticeListener(child: SizedBox())),
        overrides: overrides(),
      );
      await joinGroup(tester, sampleGroup(hostUserId: me));

      listenTogether.emit(
        activeOf(
          sampleGroup(hostUserId: me),
          error: const GroupCommandTimedOut(),
        ),
      );
      await rig.settle(tester);
      expect(find.text('The server didn’t respond'), findsOneWidget);
      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .removeCurrentSnackBar();

      listenTogether.emit(
        activeOf(
          sampleGroup(hostUserId: me),
          error: const GroupCommandRejected(message: 'Queue is full'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Queue is full'), findsOneWidget);
      await rig.close(tester);
    });

    testWidgets('Play on an album asks before replacing the group’s queue', (
      tester,
    ) async {
      var plays = 0;
      await tester.pumpApp(
        WindowClassScope(
          windowClass: WindowClass.compact,
          child: Center(child: ActionBar(onPlay: () => plays++)),
        ),
        overrides: overrides(),
      );
      await joinGroup(tester, sampleGroup(hostUserId: me));

      await tester.tap(find.byKey(ActionBar.playKey));
      await tester.pumpAndSettle();
      expect(find.text('Replace the group’s queue?'), findsOneWidget);
      expect(plays, 0);
      await tester.tap(find.text('Replace'));
      await tester.pumpAndSettle();
      expect(plays, 1);
      await rig.close(tester);
    });
  });

  testWidgets('the queue header shows the group and member count and '
      'opens Listen Together', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: QueueView()),
        ),
        GoRoute(
          path: '/listen-together',
          builder: (_, _) => const Text('listen together'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpApp(
      Router.withConfig(config: router),
      overrides: overrides(),
    );
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
        .read(playbackControllerProvider);
    await rig.start(tester);
    expect(find.byKey(ListenTogetherQueueHeader.headerKey), findsNothing);

    rig.controller.attachRemoteDriver(driver);
    listenTogether.emit(activeOf(sampleGroup()));
    await rig.settle(tester);
    expect(find.text('Road trip · 3 listening'), findsOneWidget);

    await tester.tap(find.byKey(ListenTogetherQueueHeader.headerKey));
    await tester.pumpAndSettle();
    expect(find.text('listen together'), findsOneWidget);
    await rig.close(tester);
  });
}
