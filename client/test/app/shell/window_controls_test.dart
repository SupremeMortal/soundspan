// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/gestures.dart'
    show PointerDeviceKind, kDoubleTapMinTime, kSecondaryMouseButton;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/app_locales.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/shell/top_bar.dart';
import 'package:soundspan/app/shell/window_controls.dart';
import 'package:soundspan/app/shell/window_title_bar.dart';
import 'package:soundspan/app/theme/theme.dart';
import 'package:soundspan/platform/desktop_shell/desktop_shell.dart';
import 'package:soundspan/shared/widgets/context_menu.dart';
import 'package:soundspan/shared/widgets/wordmark.dart';

import '../../helpers/fake_desktop_shell.dart';
import '../../helpers/golden.dart';
import '../../helpers/pump_app.dart';

const WindowButton _min = WindowButton.minimize;
const WindowButton _max = WindowButton.maximize;
const WindowButton _close = WindowButton.close;

const Size _window = Size(1440, 200);

/// The [Tooltip]s showing [message].
Finder _tooltip(String message) => find.byWidgetPredicate(
  (widget) => widget is Tooltip && widget.message == message,
);

Future<FakeDesktopShell> _pumpControls(
  WidgetTester tester, {
  List<WindowButton> buttons = const [_min, _max, _close],
  WindowChromeState state = const WindowChromeState(),
  WindowControlsStyle style = WindowControlsStyle.linux,
}) async {
  final shell = FakeDesktopShell();
  await tester.pumpApp(
    Scaffold(
      body: Align(
        alignment: Alignment.topRight,
        child: WindowControls(
          buttons: buttons,
          state: state,
          side: WindowControlsSide.trailing,
          height: TopBar.titleBarHeight,
          style: style,
        ),
      ),
    ),
    size: _window,
    overrides: [desktopShellProvider.overrideWithValue(shell)],
  );
  return shell;
}

double _x(WidgetTester tester, WindowButton button) =>
    tester.getCenter(find.byKey(WindowControls.buttonKey(button))).dx;

void main() {
  group('WindowControls', () {
    testWidgets('shows the buttons in the given order', (tester) async {
      await _pumpControls(tester, buttons: const [_close, _min, _max]);
      expect(_x(tester, _close), lessThan(_x(tester, _min)));
      expect(_x(tester, _min), lessThan(_x(tester, _max)));

      await _pumpControls(tester, buttons: const [_close]);
      expect(find.byKey(WindowControls.buttonKey(_close)), findsOneWidget);
      expect(find.byKey(WindowControls.buttonKey(_min)), findsNothing);
      expect(find.byKey(WindowControls.buttonKey(_max)), findsNothing);
    });

    testWidgets('Linux circles are 33 px apart and 7 px from the edge', (
      tester,
    ) async {
      await _pumpControls(tester);
      expect(_x(tester, _max) - _x(tester, _min), WindowControls.circlePitch);
      final close = tester.getCenter(
        find.byKey(WindowControls.buttonKey(_close)),
      );
      final circleRight = close.dx + WindowControls.circleSize / 2;
      expect(_window.width - circleRight, closeTo(7.5, 0.01));
      expect(close.dy, TopBar.titleBarHeight / 2);
    });

    testWidgets('Windows buttons are 46 × 32, flush with the top right', (
      tester,
    ) async {
      await _pumpControls(tester, style: WindowControlsStyle.windows);
      final close = tester.getRect(
        find.byKey(WindowControls.buttonKey(_close)),
      );
      expect(close.size, WindowControls.rectSize);
      expect(close.top, 0);
      expect(close.right, _window.width);
    });

    testWidgets('labels maximise as restore while maximised', (tester) async {
      await _pumpControls(tester);
      expect(_tooltip('Maximise'), findsOneWidget);
      expect(_tooltip('Restore'), findsNothing);
      expect(find.bySemanticsLabel('Minimise'), findsOneWidget);
      expect(find.bySemanticsLabel('Close'), findsOneWidget);

      await _pumpControls(
        tester,
        state: const WindowChromeState(maximized: true),
      );
      expect(_tooltip('Restore'), findsOneWidget);
      expect(_tooltip('Maximise'), findsNothing);
    });

    testWidgets('dims while the window is not focused', (tester) async {
      double opacity() => tester
          .widget<AnimatedOpacity>(
            find.descendant(
              of: find.byType(WindowControls),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity;

      await _pumpControls(tester);
      expect(opacity(), 1);
      await _pumpControls(
        tester,
        state: const WindowChromeState(focused: false),
      );
      expect(opacity(), WindowControls.unfocusedOpacity);
    });

    testWidgets('each button calls its DesktopShell member', (tester) async {
      final shell = await _pumpControls(tester);
      await tester.tap(find.byKey(WindowControls.buttonKey(_min)));
      await tester.tap(find.byKey(WindowControls.buttonKey(_max)));
      await tester.pumpAndSettle();
      expect(shell.calls, ['minimize', 'toggleMaximize']);
    });

    testWidgets('close goes through the close request path', (tester) async {
      final shell = await _pumpControls(tester);
      await shell.setPreventClose(true);
      var requests = 0;
      final subscription = shell.closeRequests.listen((_) => requests++);
      addTearDown(subscription.cancel);
      await tester.tap(find.byKey(WindowControls.buttonKey(_close)));
      await tester.pumpAndSettle();
      expect(shell.calls, contains('close'));
      expect(requests, 1);
      expect(shell.quitted, isFalse);
    });
  });

  group('TopBar as the title bar', () {
    Future<FakeDesktopShell> pumpBar(WidgetTester tester) async {
      final shell = FakeDesktopShell();
      await tester.pumpApp(
        Scaffold(
          body: Column(
            children: [
              TopBar(
                onBack: null,
                onForward: null,
                onSearch: (_) {},
                avatar: const SizedBox.square(dimension: 40),
                titleBarMode: true,
                trailingControls: const WindowControls(
                  buttons: [_min, _max, _close],
                  state: WindowChromeState(),
                  side: WindowControlsSide.trailing,
                  height: TopBar.titleBarHeight,
                ),
              ),
            ],
          ),
        ),
        size: _window,
        overrides: [desktopShellProvider.overrideWithValue(shell)],
      );
      return shell;
    }

    Offset emptySpace(WidgetTester tester) {
      final search = tester.getRect(find.byKey(TopBar.searchFieldKey));
      return Offset(search.right + 100, search.center.dy);
    }

    Future<void> doubleTap(WidgetTester tester, Finder finder) async {
      await tester.tap(finder, warnIfMissed: false);
      await tester.pump(kDoubleTapMinTime);
      await tester.tap(finder, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    testWidgets('is 48 px tall with the buttons in the row', (tester) async {
      await pumpBar(tester);
      expect(tester.getSize(find.byType(TopBar)).height, TopBar.titleBarHeight);
      final close = tester.getCenter(
        find.byKey(WindowControls.buttonKey(_close)),
      );
      final search = tester.getCenter(find.byKey(TopBar.searchFieldKey));
      expect(close.dy, search.dy);
    });

    testWidgets('a double click on empty space maximises', (tester) async {
      final shell = await pumpBar(tester);
      await tester.tapAt(emptySpace(tester));
      await tester.pump(kDoubleTapMinTime);
      await tester.tapAt(emptySpace(tester));
      await tester.pumpAndSettle();
      expect(shell.calls, ['toggleMaximize']);
    });

    testWidgets('a double click on the search field does not', (tester) async {
      final shell = await pumpBar(tester);
      await doubleTap(tester, find.byKey(TopBar.searchFieldKey));
      expect(shell.calls, isNot(contains('toggleMaximize')));
    });

    testWidgets('a double click on the wordmark maximises', (tester) async {
      final shell = await pumpBar(tester);
      final wordmark = tester.getCenter(find.byType(Wordmark));
      await tester.tapAt(wordmark);
      await tester.pump(kDoubleTapMinTime);
      await tester.tapAt(wordmark);
      await tester.pumpAndSettle();
      expect(shell.calls, ['toggleMaximize']);
    });

    testWidgets('dragging empty space moves the window', (tester) async {
      final shell = await pumpBar(tester);
      await tester.dragFrom(emptySpace(tester), const Offset(80, 40));
      await tester.pumpAndSettle();
      expect(shell.calls, ['startDragging']);
    });

    testWidgets('a right click on empty space opens the window menu', (
      tester,
    ) async {
      final shell = await pumpBar(tester);
      final at = emptySpace(tester);
      final gesture = await tester.startGesture(
        at,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      // Opened on the press, while the button is down.
      expect(shell.windowMenus, [at]);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a right click on the search field does not', (tester) async {
      final shell = await pumpBar(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(TopBar.searchFieldKey)),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(shell.windowMenus, isEmpty);
    });
  });

  group('WindowTitleBarHost', () {
    Future<FakeDesktopShell> pumpHost(
      WidgetTester tester, {
      required bool integrated,
      required bool claimed,
      WindowChromeState state = const WindowChromeState(),
    }) async {
      final shell = FakeDesktopShell()
        ..integrated = integrated
        ..state = state;
      await tester.pumpApp(
        WindowTitleBarHost(
          child: Scaffold(
            body: claimed
                ? const WindowTitleBarClaim(child: Text('top bar'))
                : const Text('screen'),
          ),
        ),
        size: _window,
        overrides: [desktopShellProvider.overrideWithValue(shell)],
      );
      await tester.pumpAndSettle();
      return shell;
    }

    testWidgets('shows the strip above a screen without a top bar', (
      tester,
    ) async {
      await pumpHost(tester, integrated: true, claimed: false);
      expect(find.byKey(WindowTitleBarHost.stripKey), findsOneWidget);
      expect(find.byKey(WindowControls.buttonKey(_close)), findsOneWidget);
    });

    testWidgets('leaves it out where a top bar claims the buttons', (
      tester,
    ) async {
      await pumpHost(tester, integrated: true, claimed: true);
      expect(find.byKey(WindowTitleBarHost.stripKey), findsNothing);
    });

    testWidgets('leaves it out with the system title bar', (tester) async {
      await pumpHost(tester, integrated: false, claimed: false);
      expect(find.byKey(WindowTitleBarHost.stripKey), findsNothing);
    });

    testWidgets('leaves it out in fullscreen', (tester) async {
      await pumpHost(
        tester,
        integrated: true,
        claimed: false,
        state: const WindowChromeState(fullscreen: true),
      );
      expect(find.byKey(WindowTitleBarHost.stripKey), findsNothing);
    });

    testWidgets(
      'keeps the claim under a popup or dialog, not under an opaque page',
      (tester) async {
        // As lib/app/app.dart: the host wraps the root navigator, so menus
        // and dialogs are routes above the claiming page.
        final shell = FakeDesktopShell()..integrated = true;
        late BuildContext barContext;
        tester.view
          ..physicalSize = _window
          ..devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [desktopShellProvider.overrideWithValue(shell)],
            child: MaterialApp(
              theme: SoundspanTheme.dark,
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => WindowTitleBarHost(child: child!),
              home: Scaffold(
                body: WindowTitleBarClaim(
                  child: Builder(
                    builder: (context) {
                      barContext = context;
                      return const Text('top bar');
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final strip = find.byKey(WindowTitleBarHost.stripKey);
        expect(strip, findsNothing);

        unawaited(
          showContextMenu(barContext, [
            MenuEntry(
              id: 'queue',
              label: 'Add to queue',
              icon: Icons.add,
              onSelected: () {},
            ),
          ], position: const Offset(200, 100)),
        );
        await tester.pumpAndSettle();
        expect(strip, findsNothing);
        expect(tester.getTopLeft(find.text('top bar')).dy, 0);
        Navigator.of(barContext).pop();
        await tester.pumpAndSettle();

        showDialog<void>(
          context: barContext,
          builder: (_) => const AlertDialog(content: Text('dialog')),
        );
        await tester.pumpAndSettle();
        expect(strip, findsNothing);
        expect(tester.getTopLeft(find.text('top bar')).dy, 0);
        Navigator.of(barContext).pop();
        await tester.pumpAndSettle();

        Navigator.of(barContext).push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('settings')),
          ),
        );
        await tester.pumpAndSettle();
        expect(strip, findsOneWidget);

        Navigator.of(barContext).pop();
        await tester.pumpAndSettle();
        expect(strip, findsNothing);
      },
    );

    testWidgets('follows layout and state changes', (tester) async {
      final shell = await pumpHost(tester, integrated: true, claimed: false);
      shell.emitLayout(const WindowButtonLayout(leading: [_close]));
      await tester.pumpAndSettle();
      expect(find.byKey(WindowControls.buttonKey(_min)), findsNothing);
      expect(
        tester.getCenter(find.byKey(WindowControls.buttonKey(_close))).dx,
        lessThan(_window.width / 2),
      );
      shell.emitChromeState(const WindowChromeState(maximized: true));
      await tester.pumpAndSettle();
      expect(_tooltip('Close'), findsOneWidget);
      unawaited(shell.close());
    });
  });

  for (final style in WindowControlsStyle.values) {
    goldenMatrix(
      'window_controls.${style.name}',
      sizes: const [Size(360, 200)],
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Maximised, unfocused, then at rest with the pointer on close
          // (its tooltip below it).
          for (final state in const [
            WindowChromeState(maximized: true),
            WindowChromeState(focused: false),
            WindowChromeState(),
          ])
            WindowControls(
              buttons: const [_min, _max, _close],
              state: state,
              side: WindowControlsSide.trailing,
              height: 48,
              style: style,
            ),
        ],
      ),
      overrides: [desktopShellProvider.overrideWithValue(FakeDesktopShell())],
      act: (tester) async {
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await gesture.moveTo(
          tester.getCenter(find.byKey(WindowControls.buttonKey(_close)).last),
        );
      },
    );
  }
}
