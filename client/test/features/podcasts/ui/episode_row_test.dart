// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/features/podcasts/ui/episode_row.dart';

import '../../../helpers/pump_app.dart';

final DateTime _published = DateTime.utc(2026, 3, 12, 12);

Future<void> _pump(WidgetTester tester, EpisodeRow row) => tester.pumpApp(
  Scaffold(
    body: Align(alignment: Alignment.topCenter, child: row),
  ),
);

EpisodeRow _row({Duration? position, bool isFinished = false}) => EpisodeRow(
  title: 'The Episode',
  publishedAt: _published,
  duration: const Duration(minutes: 42),
  position: position,
  isFinished: isFinished,
);

void main() {
  testWidgets('shows the date and the duration', (tester) async {
    await _pump(tester, _row());

    expect(find.text('The Episode'), findsOneWidget);
    expect(find.text('Mar 12, 2026 · 42:00'), findsOneWidget);
  });

  testWidgets('a started episode has a progress bar at its fraction', (
    tester,
  ) async {
    await _pump(tester, _row(position: const Duration(minutes: 21)));

    final bar = tester.widget<FractionallySizedBox>(
      find.byKey(EpisodeRow.progressKey),
    );
    expect(bar.widthFactor, closeTo(0.5, 1e-9));
    expect(find.byKey(EpisodeRow.playedKey), findsNothing);
  });

  testWidgets('a finished episode has the played check and no bar', (
    tester,
  ) async {
    await _pump(
      tester,
      _row(position: const Duration(minutes: 42), isFinished: true),
    );

    expect(find.byKey(EpisodeRow.playedKey), findsOneWidget);
    expect(find.text('Played'), findsOneWidget);
    expect(find.byKey(EpisodeRow.progressKey), findsNothing);
  });

  testWidgets('an untouched episode has no bar and no check', (tester) async {
    await _pump(tester, _row());

    expect(find.byKey(EpisodeRow.progressKey), findsNothing);
    expect(find.byKey(EpisodeRow.playedKey), findsNothing);
  });

  testWidgets('the row is one semantics node with the spoken label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      _row(position: const Duration(minutes: 42), isFinished: true),
    );
    expect(
      tester.getSemantics(find.byType(EpisodeRow)),
      isSemantics(label: 'The Episode, Mar 12, 2026, 42 minutes, played'),
    );

    await _pump(tester, _row(position: const Duration(minutes: 24)));
    expect(
      tester.getSemantics(find.byType(EpisodeRow)),
      isSemantics(
        label: 'The Episode, Mar 12, 2026, 42 minutes, 18 minutes left',
      ),
    );
    handle.dispose();
  });

  testWidgets('without onTap the row is not a button', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _row());
    expect(
      tester.getSemantics(find.byType(EpisodeRow)),
      isSemantics(isButton: false, hasTapAction: false),
    );

    var taps = 0;
    await _pump(tester, EpisodeRow(title: 'The Episode', onTap: () => taps++));
    expect(
      tester.getSemantics(find.byType(EpisodeRow)),
      isSemantics(isButton: true, hasTapAction: true),
    );
    await tester.tap(find.byType(EpisodeRow));
    expect(taps, 1);
    handle.dispose();
  });
}
