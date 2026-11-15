// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/features/podcasts/podcasts.dart';
import 'package:soundspan/features/podcasts/ui/episode_row.dart';
import 'package:soundspan_api/soundspan_api.dart' show Offline, ServerError;

import '../../../helpers/fake_podcast_repository.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import 'podcast_fixtures.dart';

const _screen = PodcastDetailScreen(podcastId: 'pc-1');

/// A repository with `pc-1` subscribed and its detail of [episodes].
FakePodcastRepository _repository({
  List<String>? episodes,
  bool subscribed = true,
  String? description,
}) {
  final repository = FakePodcastRepository()
    ..subscribedList = [if (subscribed) fixturePodcast('pc-1')];
  repository.details['pc-1'] = fixtureDetail(
    episodes == null
        ? fixtureEpisodes()
        : [for (final (n, _) in episodes.indexed) fixtureEpisode(n + 1)],
    description: description,
  );
  return repository;
}

Future<void> _pump(
  WidgetTester tester,
  FakePodcastRepository podcasts, {
  Reachability reachability = Reachability.online,
  Size size = TestSizes.compact,
}) => pumpPodcasts(
  tester,
  _screen,
  initialLocation: '/podcasts/pc-1',
  podcasts: podcasts,
  reachability: reachability,
  size: size,
);

Finder get _button => find.byKey(PodcastDetailScreen.subscriptionKey);

ButtonStyleButton _buttonWidget(WidgetTester tester) =>
    tester.widget<ButtonStyleButton>(_button);

void main() {
  testWidgets('the header shows the podcast fields', (tester) async {
    await _pump(tester, _repository());

    expect(find.text('PODCAST'), findsOneWidget);
    expect(find.text('Show pc-1'), findsOneWidget);
    expect(find.text('A Host · 3 episodes'), findsOneWidget);
    expect(find.text('Unsubscribe'), findsOneWidget);
  });

  testWidgets('the description is collapsed to three lines and expands', (
    tester,
  ) async {
    await _pump(tester, _repository());

    Text description() =>
        tester.widget<Text>(find.byKey(PodcastDetailScreen.descriptionKey));
    expect(description().maxLines, 3);
    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();
    expect(description().maxLines, isNull);
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('a short description has no Show more', (tester) async {
    await _pump(tester, _repository(description: 'Short.'));

    expect(find.text('Short.'), findsOneWidget);
    expect(find.text('Show more'), findsNothing);
  });

  testWidgets('episodes are in server order', (tester) async {
    await _pump(tester, _repository(), size: TestSizes.expanded);

    final titles = tester
        .widgetList<EpisodeRow>(find.byType(EpisodeRow))
        .map((row) => row.title);
    expect(titles, ['Episode 1', 'Episode 2', 'Episode 3']);
    final rows = tester.widgetList<EpisodeRow>(find.byType(EpisodeRow));
    expect(rows.map((row) => row.isFinished), [false, false, true]);
    expect(rows.map((row) => row.position), [
      null,
      const Duration(minutes: 24),
      const Duration(minutes: 42),
    ]);
    expect(rows.every((row) => row.onTap == null), isTrue);
  });

  testWidgets('a 2,000-episode list builds only the visible rows', (
    tester,
  ) async {
    await _pump(
      tester,
      _repository(episodes: List.filled(2000, '')),
      size: TestSizes.expanded,
    );

    final built = find.byType(EpisodeRow).evaluate().length;
    expect(built, greaterThan(0));
    expect(built, lessThan(40));
  });

  testWidgets('Unsubscribe asks, then unsubscribes and returns to the list', (
    tester,
  ) async {
    final podcasts = _repository();
    await _pump(tester, podcasts);

    await tester.tap(_button);
    await tester.pumpAndSettle();
    expect(find.text('Unsubscribe from Show pc-1?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Unsubscribe'));
    await tester.pumpAndSettle();

    expect(podcasts.unsubscribed, ['pc-1']);
    expect(find.text('podcasts root'), findsOneWidget);
  });

  testWidgets('cancelling the confirmation changes nothing', (tester) async {
    final podcasts = _repository();
    await _pump(tester, podcasts);

    await tester.tap(_button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(podcasts.unsubscribed, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Show pc-1'), findsOneWidget);
  });

  testWidgets('Subscribe subscribes by the feed URL when the podcast is not '
      'subscribed', (tester) async {
    final podcasts = _repository(subscribed: false);
    await _pump(tester, podcasts);

    expect(find.text('Subscribe'), findsOneWidget);
    await tester.tap(_button);
    await tester.pumpAndSettle();

    expect(podcasts.subscribedRefs, [
      const PodcastRef.feed('https://example.com/pc-1.xml'),
    ]);
  });

  for (final subscribed in [true, false]) {
    testWidgets('${subscribed ? 'Unsubscribe' : 'Subscribe'} is disabled '
        'with a tooltip while not online', (tester) async {
      final podcasts = _repository(subscribed: subscribed);
      await _pump(
        tester,
        podcasts,
        reachability: Reachability.serverUnreachable,
      );

      expect(_buttonWidget(tester).onPressed, isNull);
      expect(
        find.ancestor(of: _button, matching: find.byType(Tooltip)),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Tooltip>(
              find.ancestor(of: _button, matching: find.byType(Tooltip)),
            )
            .message,
        'Subscriptions can be changed only while the server is reachable',
      );
    });
  }

  for (final (name, error) in [
    ('Offline', const Offline() as Exception),
    ('a server failure', const ServerError(status: 500)),
  ]) {
    testWidgets('$name on unsubscribe shows a snackbar and stays', (
      tester,
    ) async {
      final podcasts = _repository()..errors['unsubscribe'] = error;
      await _pump(tester, podcasts);

      await tester.tap(_button);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Unsubscribe'));
      await tester.pumpAndSettle();

      expect(find.text('Couldn’t unsubscribe. Try again.'), findsOneWidget);
      expect(find.text('Show pc-1'), findsOneWidget);
      expect(find.text('Unsubscribe'), findsOneWidget);
    });
  }

  testWidgets('a failed subscribe shows a snackbar', (tester) async {
    final podcasts = _repository(subscribed: false)
      ..errors['subscribe'] = const ServerError(status: 500);
    await _pump(tester, podcasts);

    await tester.tap(_button);
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t subscribe. Try again.'), findsOneWidget);
    expect(find.text('Subscribe'), findsOneWidget);
  });

  testWidgets('a podcast that is gone shows the not-found view', (
    tester,
  ) async {
    await _pump(tester, FakePodcastRepository());

    expect(find.text('This item is no longer available'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('meets the screen guidelines', (tester) async {
    await _pump(tester, _repository());

    await expectMeetsGuidelines(tester);
  });
}
