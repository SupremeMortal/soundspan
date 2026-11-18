// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/realtime/socket_client.dart'
    show SocketConnectionState;
import 'package:soundspan/features/listen_together/domain/listen_together_state.dart';
import 'package:soundspan/features/listen_together/ui/listen_together_screen.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan_api/soundspan_api.dart' show NotFound;

import '../../../helpers/fake_reachability.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import '../../player/ui/player_rig.dart';
import 'listen_together_ui_rig.dart';

void main() {
  late FakeListenTogetherController controller;
  late FakeListenTogetherRepository repository;
  late FakeReachability reachability;

  setUp(() {
    controller = FakeListenTogetherController();
    repository = FakeListenTogetherRepository()
      ..myGroup = sampleGroup()
      ..discovered = [sampleSummary()];
    reachability = FakeReachability();
  });

  Future<void> pump(
    WidgetTester tester, {
    Size size = TestSizes.compact,
    double textScale = 1.0,
    SocketConnectionState connection = SocketConnectionState.connected,
    List<Override> overrides = const [],
  }) async {
    await tester.pumpApp(
      WindowClassScope(
        windowClass: windowClassOf(size),
        child: const ListenTogetherScreen(),
      ),
      size: size,
      textScale: textScale,
      overrides: [
        ...listenTogetherOverrides(
          controller,
          repository,
          connection: connection,
        ),
        reachabilityProvider.overrideWithValue(reachability),
        profilesProvider.overrideWith((ref) => Stream.value(const <Profile>[])),
        initialActiveProfileIdProvider.overrideWithValue(null),
        ...overrides,
      ],
    );
    await tester.pumpAndSettle();
  }

  group('lobby', () {
    testWidgets('lists the user’s group and the public groups', (tester) async {
      await pump(tester);

      expect(find.text('Your groups'), findsOneWidget);
      expect(find.text('Road trip'), findsOneWidget);
      expect(find.text('alex · 3 members'), findsOneWidget);
      expect(find.text('Public groups'), findsOneWidget);
      expect(find.text('Jazz night'), findsOneWidget);
      expect(find.text('kim · 4 members'), findsOneWidget);

      await tester.tap(find.byKey(ListenTogetherScreen.joinGroupKey('g2')));
      await tester.pumpAndSettle();
      expect(controller.calls, ['join(JAZZ42)']);
    });

    testWidgets('with no group shows the empty state and both actions', (
      tester,
    ) async {
      repository
        ..myGroup = null
        ..discovered = const [];
      await pump(tester);

      expect(find.text('Your groups'), findsNothing);
      expect(find.text('Public groups'), findsNothing);
      expect(
        find.widgetWithText(EmptyState, 'Listen with others in sync'),
        findsOneWidget,
      );
      expect(find.byKey(ListenTogetherScreen.createKey), findsOneWidget);
      expect(find.byKey(ListenTogetherScreen.joinWithCodeKey), findsOneWidget);
    });

    testWidgets('pull to refresh and F5 load the groups again', (tester) async {
      await pump(tester);
      expect(repository.loads, 1);

      repository.discovered = [sampleSummary(id: 'g3', name: 'Morning')];
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();
      expect(repository.loads, 2);
      expect(find.text('Morning'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.f5);
      await tester.pumpAndSettle();
      expect(repository.loads, 3);
    });

    testWidgets('offline shows the offline state and disables both actions', (
      tester,
    ) async {
      reachability.set(Reachability.serverUnreachable);
      await pump(tester);

      expect(find.text('Road trip'), findsNothing);
      expect(find.text('You’re offline'), findsOneWidget);
      expect(
        tester
            .widget<ButtonStyleButton>(
              find.byKey(ListenTogetherScreen.createKey),
            )
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<ButtonStyleButton>(
              find.byKey(ListenTogetherScreen.joinWithCodeKey),
            )
            .enabled,
        isFalse,
      );
    });
  });

  group('create', () {
    testWidgets('validates the name length', (tester) async {
      final rig = PlayerRig();
      await pump(tester, overrides: rig.overrides);
      await tester.tap(find.byKey(ListenTogetherScreen.createKey));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(ListenTogetherScreen.nameFieldKey),
        'x' * 81,
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Use at most 80 characters'), findsOneWidget);
      expect(controller.calls, isEmpty);
      await rig.close(tester);
    });

    testWidgets('submits the name, visibility and queue switch', (
      tester,
    ) async {
      final rig = PlayerRig();
      await pump(tester, overrides: rig.overrides);
      await rig.start(tester);
      await tester.tap(find.byKey(ListenTogetherScreen.createKey));
      await tester.pumpAndSettle();

      expect(find.byKey(ListenTogetherScreen.queueSwitchKey), findsOneWidget);
      await tester.enterText(
        find.byKey(ListenTogetherScreen.nameFieldKey),
        '  Party  ',
      );
      await tester.tap(find.text('Public'));
      await tester.tap(find.byKey(ListenTogetherScreen.queueSwitchKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(controller.calls, ['create(Party,public,false)']);
      await rig.close(tester);
    });

    testWidgets('hides the queue switch without a queue; private by default', (
      tester,
    ) async {
      final rig = PlayerRig();
      await pump(tester, size: TestSizes.expanded, overrides: rig.overrides);
      await tester.tap(find.byKey(ListenTogetherScreen.createKey));
      await tester.pumpAndSettle();

      expect(find.byKey(ListenTogetherScreen.queueSwitchKey), findsNothing);
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(controller.calls, ['create(null,private,false)']);
      await rig.close(tester);
    });
  });

  group('join', () {
    testWidgets('trims and upper-cases the code', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(ListenTogetherScreen.joinWithCodeKey));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(ListenTogetherScreen.codeFieldKey),
        '  abc123 ',
      );
      await tester.pump();
      expect(find.text('  ABC123 '), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Join'));
      await tester.pumpAndSettle();

      expect(controller.calls, ['join(ABC123)']);
    });

    testWidgets('NotFound says there is no group with that code', (
      tester,
    ) async {
      controller.joinError = const NotFound(status: 404);
      await pump(tester);
      await tester.tap(find.byKey(ListenTogetherScreen.joinWithCodeKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(ListenTogetherScreen.codeFieldKey),
        'nope',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Join'));
      await tester.pumpAndSettle();

      expect(find.text('No group with that code'), findsOneWidget);
    });
  });

  group('group view', () {
    testWidgets('shows the header, code and members with host and '
        'disconnected styles', (tester) async {
      await pump(tester, connection: SocketConnectionState.connecting);
      controller.emit(activeOf(sampleGroup()));
      await tester.pumpAndSettle();
      final colors = tester.element(find.byType(ListenTogetherScreen)).colors;

      expect(find.text('Road trip'), findsWidgets);
      expect(find.text('Private group'), findsOneWidget);
      expect(find.text('Hosted by alex'), findsOneWidget);
      expect(find.text('Reconnecting…'), findsOneWidget);
      expect(find.text('ABC123'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(ListenTogetherScreen.memberKey('u-alex')),
          matching: find.text('Host'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(ListenTogetherScreen.memberKey('u-sam')),
          matching: find.text('Host'),
        ),
        findsNothing,
      );
      Color colorOf(String name) =>
          tester.widget<Text>(find.text(name)).style!.color!;
      expect(colorOf('alex'), colors.content);
      expect(colorOf('sam'), colors.contentSecondary);
      expect(find.text('Song one'), findsOneWidget);
    });

    testWidgets('Copy code writes the code to the clipboard and announces', (
      tester,
    ) async {
      final copied = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') copied.add(call.arguments);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pump(tester);
      controller.emit(activeOf(sampleGroup()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ListenTogetherScreen.copyCodeKey));
      await tester.pumpAndSettle();

      expect(copied, [
        {'text': 'ABC123'},
      ]);
      expect(
        tester.takeAnnouncements().map((announcement) => announcement.message),
        contains('Copied'),
      );
    });

    testWidgets('End group shows for the host only and asks first', (
      tester,
    ) async {
      await pump(tester);
      controller.emit(activeOf(sampleGroup()));
      await tester.pumpAndSettle();
      expect(find.byKey(ListenTogetherScreen.endKey), findsNothing);

      controller.emit(activeOf(sampleGroup(hostUserId: me)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(ListenTogetherScreen.endKey));
      await tester.tap(find.byKey(ListenTogetherScreen.endKey));
      await tester.pumpAndSettle();
      expect(find.text('End the group?'), findsOneWidget);
      expect(controller.calls, isEmpty);

      await tester.tap(find.text('End group'));
      await tester.pumpAndSettle();
      expect(controller.calls, ['end']);
    });

    testWidgets('Leave group calls leave', (tester) async {
      await pump(tester);
      controller.emit(activeOf(sampleGroup()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(ListenTogetherScreen.leaveKey));
      await tester.tap(find.byKey(ListenTogetherScreen.leaveKey));
      await tester.pumpAndSettle();
      expect(controller.calls, ['leave']);
    });

    testWidgets('joining and leaving disable the actions', (tester) async {
      bool enabled(Key key) =>
          tester.widget<ButtonStyleButton>(find.byKey(key)).enabled;
      await pump(tester);

      controller.emit(const ListenTogetherJoining());
      await tester.pump();
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(enabled(ListenTogetherScreen.createKey), isFalse);
      expect(enabled(ListenTogetherScreen.joinWithCodeKey), isFalse);
      expect(enabled(ListenTogetherScreen.joinGroupKey('g2')), isFalse);

      controller.emit(activeOf(sampleGroup(hostUserId: me)));
      await tester.pumpAndSettle();
      expect(enabled(ListenTogetherScreen.leaveKey), isTrue);

      controller.emit(const ListenTogetherLeaving());
      await tester.pump();
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(enabled(ListenTogetherScreen.leaveKey), isFalse);
      expect(enabled(ListenTogetherScreen.endKey), isFalse);
      expect(enabled(ListenTogetherScreen.openQueueKey), isFalse);
    });

    testWidgets('traversal order is header, code, members, actions', (
      tester,
    ) async {
      await pump(tester, size: TestSizes.expanded);
      controller.emit(activeOf(sampleGroup(hostUserId: me)));
      await tester.pumpAndSettle();

      double top(Finder finder) => tester.getTopLeft(finder).dy;
      final order = [
        top(find.text('Hosted by me')),
        top(find.byKey(ListenTogetherScreen.copyCodeKey)),
        top(find.byKey(ListenTogetherScreen.memberKey('u-alex'))),
        top(find.byKey(ListenTogetherScreen.leaveKey)),
      ];
      expect(order, orderedEquals([...order]..sort()));
    });
  });

  group('after a group ends', () {
    for (final (reason, message) in [
      (GroupEndReason.ended, 'The host ended the group'),
      (GroupEndReason.membershipRevoked, 'You were removed from the group'),
    ]) {
      testWidgets('${reason.name} shows "$message" over the lobby', (
        tester,
      ) async {
        await pump(tester);
        controller.emit(activeOf(sampleGroup()));
        await tester.pumpAndSettle();
        expect(find.byKey(ListenTogetherScreen.createKey), findsNothing);

        controller.emit(ListenTogetherEnded(reason));
        await tester.pumpAndSettle();
        expect(find.text(message), findsOneWidget);
        expect(find.byKey(ListenTogetherScreen.createKey), findsOneWidget);
      });
    }
  });

  group('accessibility', () {
    testWidgets('the lobby meets the guidelines', (tester) async {
      await pump(tester);
      await expectMeetsGuidelines(tester);
    });

    testWidgets('the group view meets the guidelines', (tester) async {
      await pump(tester);
      controller.emit(activeOf(sampleGroup(hostUserId: me)));
      await tester.pumpAndSettle();
      await expectMeetsGuidelines(tester);
    });

    for (final active in [false, true]) {
      testWidgets('text scale 2.0 at 390 has no overflow '
          '(${active ? 'group view' : 'lobby'})', (tester) async {
        await pump(tester, textScale: 2);
        if (active) {
          controller.emit(activeOf(sampleGroup(hostUserId: me)));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}
