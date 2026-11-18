// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/page_transitions.dart';
import 'package:soundspan/app/theme/theme.dart';

const _first = Key('first');
const _second = Key('second');

/// Pumps an app with the soundspan theme for [platform] whose home pushes a
/// second page, and pushes it. [canPop] is the second page's `PopScope`.
Future<void> _pumpTwoPages(
  WidgetTester tester,
  TargetPlatform platform, {
  bool canPop = true,
  TextDirection direction = TextDirection.ltr,
}) async {
  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      // The theme is built once, so its platform is set here per test.
      theme: SoundspanTheme.dark.copyWith(platform: platform),
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: const ColoredBox(key: _first, color: Color(0xFF000000)),
    ),
  );
  navigatorKey.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => PopScope(
        canPop: canPop,
        child: const ColoredBox(key: _second, color: Color(0xFF000000)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Where the second page is painted: its global rect and paint transform.
(Rect, Matrix4) _placement(WidgetTester tester) => (
  tester.getRect(find.byKey(_second)),
  tester.renderObject<RenderBox>(find.byKey(_second)).getTransformTo(null),
);

Future<void> _backGesture(String method, [double? progress]) async {
  const codec = StandardMethodCodec();
  await TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        SystemChannels.backGesture.name,
        codec.encodeMethodCall(
          MethodCall(
            method,
            progress == null
                ? null
                : <String, Object?>{
                    'touchOffset': <double>[5, 300],
                    'progress': progress,
                    'swipeEdge': 0,
                  },
          ),
        ),
        (_) {},
      );
}

void main() {
  group('Android predictive back', () {
    testWidgets('moves nothing until the gesture commits, then pops', (
      tester,
    ) async {
      await _pumpTwoPages(tester, TargetPlatform.android);
      final before = _placement(tester);

      await _backGesture('startBackGesture', 0);
      await tester.pump();
      await _backGesture('updateBackGestureProgress', 0.5);
      await tester.pump();

      expect(_placement(tester), before);
      expect(find.byKey(_first), findsNothing, reason: 'still offstage');

      await _backGesture('commitBackGesture');
      await tester.pumpAndSettle();

      expect(find.byKey(_second), findsNothing);
      expect(find.byKey(_first), findsOneWidget);
    });

    testWidgets('a cancelled gesture leaves the page in place', (tester) async {
      await _pumpTwoPages(tester, TargetPlatform.android);
      final before = _placement(tester);

      await _backGesture('startBackGesture', 0);
      await tester.pump();
      await _backGesture('updateBackGestureProgress', 0.5);
      await tester.pump();
      await _backGesture('cancelBackGesture');
      await tester.pump();

      expect(_placement(tester), before);
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpAndSettle();
      expect(find.byKey(_second), findsOneWidget);
      expect(find.byKey(_first), findsNothing);
    });
  });

  group('iOS edge swipe', () {
    /// Drags from [start] by [fraction] of the width in small steps, checks
    /// that nothing moved before releasing, and releases without velocity.
    Future<void> slowDrag(
      WidgetTester tester, {
      required Offset start,
      required double fraction,
      double sign = 1,
    }) async {
      final before = _placement(tester);
      final width = tester.getSize(find.byKey(_second)).width;
      final gesture = await tester.startGesture(start);
      const steps = 10;
      for (var i = 0; i < steps; i++) {
        await gesture.moveBy(Offset(sign * width * fraction / steps, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(_placement(tester), before, reason: 'nothing moves mid-drag');
      expect(find.byKey(_first), findsNothing, reason: 'still offstage');
      // A pause before release leaves no fling velocity.
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('a drag to half the width pops on release', (tester) async {
      await _pumpTwoPages(tester, TargetPlatform.iOS);
      await slowDrag(tester, start: const Offset(5, 300), fraction: 0.5);
      expect(find.byKey(_second), findsNothing);
      expect(find.byKey(_first), findsOneWidget);
    });

    testWidgets('a drag to a tenth of the width does not pop', (tester) async {
      await _pumpTwoPages(tester, TargetPlatform.iOS);
      await slowDrag(tester, start: const Offset(5, 300), fraction: 0.1);
      expect(find.byKey(_second), findsOneWidget);
    });

    testWidgets('a short fast fling pops', (tester) async {
      await _pumpTwoPages(tester, TargetPlatform.iOS);
      await tester.flingFrom(const Offset(5, 300), const Offset(60, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.byKey(_second), findsNothing);
    });

    testWidgets('a drag starting 100 px from the edge does nothing', (
      tester,
    ) async {
      await _pumpTwoPages(tester, TargetPlatform.iOS);
      await slowDrag(tester, start: const Offset(100, 300), fraction: 0.5);
      expect(find.byKey(_second), findsOneWidget);
    });

    testWidgets('PopScope(canPop: false) blocks it', (tester) async {
      await _pumpTwoPages(tester, TargetPlatform.iOS, canPop: false);
      await slowDrag(tester, start: const Offset(5, 300), fraction: 0.5);
      expect(find.byKey(_second), findsOneWidget);
    });

    testWidgets('starts at the right edge in a right-to-left layout', (
      tester,
    ) async {
      await _pumpTwoPages(
        tester,
        TargetPlatform.iOS,
        direction: TextDirection.rtl,
      );
      final width = tester.getSize(find.byKey(_second)).width;
      await slowDrag(
        tester,
        start: Offset(width - 5, 300),
        fraction: 0.5,
        sign: -1,
      );
      expect(find.byKey(_second), findsNothing);
    });
  });

  test('every platform uses the commit-only builder', () {
    final builders = SoundspanTheme.dark.pageTransitionsTheme.builders;
    for (final platform in TargetPlatform.values) {
      expect(
        builders[platform],
        isA<CommitOnlyPageTransitionsBuilder>().having(
          (builder) => builder.cupertino,
          'cupertino',
          platform == TargetPlatform.iOS || platform == TargetPlatform.macOS,
        ),
        reason: '$platform',
      );
    }
  });
}
