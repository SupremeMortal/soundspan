// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/play_notice_listener.dart';
import 'package:soundspan/shared/providers/play_actions.dart';
import 'package:soundspan_api/soundspan_api.dart' show Offline, Unauthenticated;

import '../../helpers/pump_app.dart';

void main() {
  late StreamController<PlayNotice> notices;

  setUp(() => notices = StreamController<PlayNotice>.broadcast());
  tearDown(() => notices.close());

  Future<void> pump(WidgetTester tester) => tester.pumpApp(
    const PlayNoticeListener(child: Scaffold()),
    overrides: [playNoticesProvider.overrideWithValue(notices)],
  );

  testWidgets('a cut queue shows how many were queued', (tester) async {
    await pump(tester);

    notices.add(const QueueTruncated(5000));
    await tester.pump();

    expect(find.text('Only the first 5,000 songs were queued'), findsOneWidget);
  });

  testWidgets('a failed load shows the shared error message', (tester) async {
    await pump(tester);

    notices.add(const PlayLoadFailed(Offline()));
    await tester.pump();

    expect(find.text('You’re offline'), findsOneWidget);
  });

  testWidgets('an unauthenticated load shows nothing', (tester) async {
    await pump(tester);

    notices.add(const PlayLoadFailed(Unauthenticated()));
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });
}
