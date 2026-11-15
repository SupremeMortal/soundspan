// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/features/podcasts/podcasts.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan_api/soundspan_api.dart' show ServerError;

import '../../../helpers/fake_podcast_repository.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import 'podcast_fixtures.dart';

const _screen = PodcastsScreen();

Future<FakeRepositories> _pump(
  WidgetTester tester,
  FakePodcastRepository podcasts, {
  List<String> top = const ['t1', 't2'],
  Size size = TestSizes.compact,
}) async {
  final repositories = FakeRepositories();
  repositories.home.podcasts = [for (final id in top) fixtureTopPodcast(id)];
  await pumpPodcasts(
    tester,
    _screen,
    initialLocation: '/podcasts',
    podcasts: podcasts,
    repositories: repositories,
    size: size,
  );
  return repositories;
}

FakePodcastRepository _subscribed(int count) => FakePodcastRepository()
  ..subscribedList = [for (var n = 1; n <= count; n++) fixturePodcast('pc-$n')];

void main() {
  testWidgets('the grid shows the subscribed podcasts', (tester) async {
    await _pump(tester, _subscribed(2));

    expect(find.text('Podcasts'), findsOneWidget);
    expect(find.text('Your podcasts'), findsOneWidget);
    for (final id in ['pc-1', 'pc-2']) {
      final card = tester.widget<MediaCard>(
        find.byKey(PodcastsScreen.cardKey(id)),
      );
      expect(
        (card.title, card.subtitle, card.artworkRef),
        ('Show $id', 'A Host', 'cover-$id'),
      );
    }
  });

  for (final (size, columns) in [
    (TestSizes.compact, 2),
    (TestSizes.medium, 4),
    (TestSizes.expanded, 8),
  ]) {
    testWidgets('the grid has $columns columns at ${size.width.toInt()}', (
      tester,
    ) async {
      await _pump(tester, _subscribed(10), size: size);

      final top = tester
          .getTopLeft(find.byKey(PodcastsScreen.cardKey('pc-1')))
          .dy;
      final inFirstRow = [
        for (var n = 1; n <= 10; n++)
          if (find.byKey(PodcastsScreen.cardKey('pc-$n')).evaluate().isNotEmpty)
            tester.getTopLeft(find.byKey(PodcastsScreen.cardKey('pc-$n'))).dy,
      ].where((dy) => dy == top);
      expect(inFirstRow, hasLength(columns));
    });
  }

  testWidgets('an empty list shows the empty state with the shelf', (
    tester,
  ) async {
    await _pump(tester, FakePodcastRepository());

    expect(find.byType(EmptyState), findsOneWidget);
    expect(
      find.text('You haven’t subscribed to any podcasts yet'),
      findsOneWidget,
    );
    expect(find.byKey(PodcastsScreen.shelfKey), findsOneWidget);
    expect(find.text('Top podcasts'), findsOneWidget);
    expect(find.text('Top t1'), findsOneWidget);
  });

  testWidgets('a failed load without cache shows the error view, and Retry '
      'loads again', (tester) async {
    final podcasts = FakePodcastRepository()
      ..errors['subscribed'] = const ServerError(status: 500);
    await _pump(tester, podcasts);

    expect(find.text('Retry'), findsOneWidget);
    expect(podcasts.count('subscribed'), 1);

    podcasts.errors.clear();
    podcasts.subscribedList = [fixturePodcast('pc-1')];
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(podcasts.count('subscribed'), 2);
    expect(find.byKey(PodcastsScreen.cardKey('pc-1')), findsOneWidget);
  });

  testWidgets('the shelf is hidden when it is empty', (tester) async {
    await _pump(tester, _subscribed(1), top: const []);

    expect(find.byKey(PodcastsScreen.shelfKey), findsNothing);
    expect(find.text('Top podcasts'), findsNothing);
  });

  testWidgets('the shelf is hidden when it fails', (tester) async {
    final repositories = FakeRepositories();
    repositories.home.errors['topPodcasts'] = const ServerError(status: 500);
    await pumpPodcasts(
      tester,
      _screen,
      initialLocation: '/podcasts',
      podcasts: _subscribed(1),
      repositories: repositories,
    );

    expect(find.byKey(PodcastsScreen.shelfKey), findsNothing);
    expect(find.byKey(PodcastsScreen.cardKey('pc-1')), findsOneWidget);
  });

  testWidgets('tapping a subscribed card opens its podcast page', (
    tester,
  ) async {
    await _pump(tester, _subscribed(2));

    await tester.tap(find.byKey(PodcastsScreen.cardKey('pc-2')));
    await tester.pumpAndSettle();

    expect(find.text('podcast page pc-2'), findsOneWidget);
  });

  testWidgets('a top podcast that is already subscribed opens its page', (
    tester,
  ) async {
    final podcasts = FakePodcastRepository()
      ..subscribedList = [fixturePodcast('t1')];
    await _pump(tester, podcasts);

    await tester.tap(find.text('Top t1'));
    await tester.pumpAndSettle();

    expect(find.text('podcast page t1'), findsOneWidget);
    expect(podcasts.subscribedRefs, isEmpty);
  });

  testWidgets('an unsubscribed top podcast opens the dialog; Subscribe '
      'subscribes and opens the new podcast', (tester) async {
    final podcasts = _subscribed(1)..subscribeId = 'pc-9';
    await _pump(tester, podcasts);

    await tester.tap(find.text('Top t2'));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text('Top t2')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Top Host')),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Subscribe'));
    await tester.pumpAndSettle();

    expect(podcasts.subscribedRefs, [
      const PodcastRef.feed('https://example.com/top-t2.xml'),
    ]);
    expect(find.text('podcast page pc-9'), findsOneWidget);
  });

  testWidgets('Cancel closes the dialog without subscribing', (tester) async {
    final podcasts = _subscribed(1);
    await _pump(tester, podcasts);

    await tester.tap(find.text('Top t1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(podcasts.subscribedRefs, isEmpty);
  });

  testWidgets('a failed subscribe shows a snackbar and stays', (tester) async {
    final podcasts = _subscribed(1)
      ..errors['subscribe'] = const ServerError(status: 500);
    await _pump(tester, podcasts);

    await tester.tap(find.text('Top t1'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Subscribe'));
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t subscribe. Try again.'), findsOneWidget);
    expect(find.byKey(PodcastsScreen.cardKey('pc-1')), findsOneWidget);
  });

  testWidgets('pull to refresh fetches the list and the shelf again', (
    tester,
  ) async {
    final podcasts = _subscribed(2);
    final repositories = await _pump(tester, podcasts);

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(podcasts.count('refreshSubscribed'), 1);
    expect(repositories.home.refreshCount('refreshTopPodcasts'), 1);
  });

  testWidgets('meets the screen guidelines', (tester) async {
    await _pump(tester, _subscribed(3));

    await expectMeetsGuidelines(tester);
  });
}
