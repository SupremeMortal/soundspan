// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/desktop/desktop_controller.dart';
import 'package:soundspan/app/desktop/desktop_menu_bar.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/shortcuts/shortcut_intents.dart';
import 'package:soundspan/core/playback/playback_providers.dart';

import 'desktop_rig.dart';

/// Records the menus a [PlatformMenuBar] sets.
class _RecordingMenuDelegate extends PlatformMenuDelegate {
  List<PlatformMenuItem> menus = const [];

  @override
  void setMenus(List<PlatformMenuItem> topLevelMenus) => menus = topLevelMenus;

  @override
  void clearMenus() => menus = const [];

  @override
  bool debugLockDelegate(BuildContext context) => true;

  @override
  bool debugUnlockDelegate(BuildContext context) => true;
}

/// An action that records each intent it is invoked with.
class _Recording<T extends Intent> extends Action<T> {
  new(this.invoked);

  final List<Type> invoked;

  @override
  Object? invoke(T intent) {
    invoked.add(T);
    return null;
  }
}

void main() {
  late DesktopRig r;
  late _RecordingMenuDelegate delegate;
  late List<Type> invoked;

  setUp(() {
    r = DesktopRig(platform: TargetPlatform.macOS);
    delegate = _RecordingMenuDelegate();
    invoked = [];
  });

  /// Starts the rig in real time, playing a, b and c with [play]; it is
  /// closed when the test ends.
  Future<void> start(WidgetTester tester, {bool play = false}) async {
    await tester.runAsync(() async {
      await r.start();
      if (play) await r.play();
    });
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(r.close);
    });
  }

  Future<void> pumpMenuBar(WidgetTester tester) async {
    final binding = WidgetsBinding.instance;
    final previous = binding.platformMenuDelegate;
    binding.platformMenuDelegate = delegate;
    addTearDown(() => binding.platformMenuDelegate = previous);
    final container = ProviderContainer(
      overrides: [
        playbackControllerProvider.overrideWithValue(r.h.controller),
        desktopControllerProvider.overrideWithValue(r.desktop),
      ],
    );
    addTearDown(container.dispose);
    // The profile scope creates its controller before the shell shows.
    container.read(playbackControllerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Actions(
            actions: {
              for (final (type, action) in [
                (
                  TogglePlayPauseIntent,
                  _Recording<TogglePlayPauseIntent>(invoked),
                ),
                (NextTrackIntent, _Recording<NextTrackIntent>(invoked)),
                (PreviousTrackIntent, _Recording<PreviousTrackIntent>(invoked)),
                (ToggleShuffleIntent, _Recording<ToggleShuffleIntent>(invoked)),
                (CycleRepeatIntent, _Recording<CycleRepeatIntent>(invoked)),
                (ToggleQueueIntent, _Recording<ToggleQueueIntent>(invoked)),
                (ToggleLyricsIntent, _Recording<ToggleLyricsIntent>(invoked)),
                (OpenSettingsIntent, _Recording<OpenSettingsIntent>(invoked)),
              ])
                type: action,
            },
            child: const DesktopMenuBar(child: SizedBox.shrink()),
          ),
        ),
      ),
    );
    // The playback state arrives after the first frame.
    await tester.pump();
    await tester.pump();
  }

  /// What the menu bar sends the platform for the keys of [item], or of
  /// a [SingleActivator].
  Object? keysOf(Object item) => switch (item) {
    PlatformMenuItem(:final shortcut) =>
      shortcut?.serializeForMenu().toChannelRepresentation(),
    SingleActivator() => item.serializeForMenu().toChannelRepresentation(),
    _ => null,
  };

  /// The item labelled [label] in the menu labelled [menu].
  PlatformMenuItem itemOf(String menu, String label) {
    final top = delegate.menus.whereType<PlatformMenu>().singleWhere(
      (m) => m.label == menu,
    );
    final items = [
      for (final member in top.menus)
        if (member is PlatformMenuItemGroup) ...member.members else member,
    ];
    return items.singleWhere((item) => item.label == label);
  }

  testWidgets('the delegate receives the application, Playback, View and '
      'Window menus', (tester) async {
    await start(tester);
    await pumpMenuBar(tester);

    expect(delegate.menus.map((m) => m.label), [
      'soundspan',
      'Playback',
      'View',
      'Window',
    ]);
    expect((delegate.menus[1] as PlatformMenu).menus.map((m) => m.label), [
      'Play/Pause',
      'Next',
      'Previous',
      'Shuffle',
      'Repeat',
    ]);
    expect((delegate.menus[2] as PlatformMenu).menus.map((m) => m.label), [
      'Queue',
      'Lyrics',
    ]);
    expect(
      (delegate.menus[3] as PlatformMenu).menus,
      everyElement(isA<PlatformProvidedMenuItem>()),
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('each item dispatches its intent and shows its shortcut', (
    tester,
  ) async {
    await start(tester, play: true);
    await pumpMenuBar(tester);

    final expected = {
      ('Playback', 'Play/Pause'): TogglePlayPauseIntent,
      ('Playback', 'Next'): NextTrackIntent,
      ('Playback', 'Previous'): PreviousTrackIntent,
      ('Playback', 'Shuffle'): ToggleShuffleIntent,
      ('Playback', 'Repeat'): CycleRepeatIntent,
      ('View', 'Queue'): ToggleQueueIntent,
      ('View', 'Lyrics'): ToggleLyricsIntent,
      ('soundspan', 'Settings…'): OpenSettingsIntent,
    };
    for (final MapEntry(key: (menu, label), value: intent)
        in expected.entries) {
      invoked.clear();
      itemOf(menu, label).onSelected!();
      expect(invoked, [intent], reason: '$menu → $label');
    }

    expect(
      keysOf(itemOf('Playback', 'Shuffle')),
      keysOf(const SingleActivator(LogicalKeyboardKey.keyS, meta: true)),
    );
    expect(
      keysOf(itemOf('View', 'Queue')),
      keysOf(const SingleActivator(LogicalKeyboardKey.keyQ, control: true)),
    );
    expect(
      keysOf(itemOf('soundspan', 'Settings…')),
      keysOf(const SingleActivator(LogicalKeyboardKey.comma, meta: true)),
    );
    // Space and Cmd+arrows stay with text fields.
    expect(itemOf('Playback', 'Play/Pause').shortcut, isNull);
    expect(itemOf('Playback', 'Next').shortcut, isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('Quit, Cmd+Q, stops playback and quits', (tester) async {
    await start(tester, play: true);
    await pumpMenuBar(tester);

    final quit = itemOf('soundspan', 'Quit soundspan');
    expect(
      keysOf(quit),
      keysOf(const SingleActivator(LogicalKeyboardKey.keyQ, meta: true)),
    );
    await tester.runAsync(() async {
      quit.onSelected!();
      await r.h.settle();
    });

    expect(r.h.controller.snapshot.playing, isFalse);
    expect(r.shell.quitted, isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('the playback items and Lyrics are disabled with an empty '
      'queue', (tester) async {
    await start(tester);
    await pumpMenuBar(tester);

    for (final label in [
      'Play/Pause',
      'Next',
      'Previous',
      'Shuffle',
      'Repeat',
    ]) {
      expect(itemOf('Playback', label).onSelected, isNull, reason: label);
    }
    expect(itemOf('View', 'Lyrics').onSelected, isNull);
    expect(itemOf('View', 'Queue').onSelected, isNotNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('no menu bar is built on other platforms', (tester) async {
    await start(tester);
    await pumpMenuBar(tester);

    expect(find.byType(PlatformMenuBar), findsNothing);
    expect(delegate.menus, isEmpty);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
