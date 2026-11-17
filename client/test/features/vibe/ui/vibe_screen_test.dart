// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/features/vibe/ui/vibe_screen.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/capability_refresh.dart';
import 'package:soundspan/shared/providers/play_actions.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../../helpers/fake_reachability.dart';
import '../../../helpers/fake_vibe_repository.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';

class _FixedCapabilities extends ServerCapabilitiesNotifier {
  new(this._value);

  final ServerCapabilities _value;

  @override
  ServerCapabilities build() => _value;
}

/// Records the commands the screen sends to playback.
class _RecordingController extends Fake implements PlaybackController {
  final List<(List<QueueItem>, int, QueueContext?)> plays = [];

  @override
  Future<void> playItems(
    List<QueueItem> items, {
    int startIndex = 0,
    QueueContext? context,
  }) async => plays.add((items, startIndex, context));
}

Track _track(String title, {String? libraryId, bool playable = true}) => Track(
  meta: TrackMeta(
    title: title,
    artist: 'Artist',
    album: 'Album',
    durationSec: 200,
  ),
  playbackId: playable ? PlaybackId('pb-$title') : null,
  libraryTrackId: libraryId,
);

PlaybackSnapshot _playing(Track? track) => PlaybackSnapshot(
  queue: QueueState.empty(),
  status: EngineStatus.idle,
  playing: false,
  current: track == null
      ? null
      : QueueItem.track(
          queueItemId: 'q-${track.meta.title}',
          track: track,
          context: const QueueContext(kind: QueueContextKind.library),
        ),
);

const _similarTitle = 'Similar to what’s playing';

void main() {
  late FakeVibeRepository vibe;
  late FakeReachability reachability;
  late _RecordingController controller;
  late StreamController<PlaybackSnapshot> playback;
  late int refreshes;

  setUp(() {
    vibe = FakeVibeRepository()
      ..searchTracks = [
        _track('Rain', libraryId: 'l-10'),
        _track('Locked', libraryId: 'l-11', playable: false),
        _track('Storm', libraryId: 'l-12'),
      ]
      ..similarById['l-1'] = [
        _track('Near', libraryId: 'l-2'),
        _track('Close', libraryId: 'l-3'),
      ]
      ..similarById['l-5'] = [_track('Other', libraryId: 'l-6')];
    reachability = FakeReachability();
    controller = _RecordingController();
    playback = StreamController<PlaybackSnapshot>.broadcast();
    refreshes = 0;
  });

  tearDown(() => playback.close());

  Future<void> pump(
    WidgetTester tester, {
    bool audioAnalysis = true,
    bool search = true,
    Track? current,
    Size size = const Size(1440, 2400),
  }) async {
    final router = GoRouter(
      initialLocation: '/vibe',
      routes: [GoRoute(path: '/vibe', builder: (_, _) => const VibeScreen())],
    );
    addTearDown(router.dispose);
    final initial = _playing(current);
    final notices = StreamController<PlayNotice>.broadcast();
    addTearDown(notices.close);
    final overrides = <Override>[
      vibe.providerOverride,
      serverCapabilitiesProvider.overrideWith(
        () => _FixedCapabilities(
          ServerCapabilities(
            serverVersion: Version.tryParse('2.7.0'),
            hasP6SelfRevoke: true,
            hasP7PlayMarker: true,
            hasP8PlayedAt: true,
            audioAnalysis: audioAnalysis,
            vibe: search,
          ),
        ),
      ),
      capabilityRefreshProvider.overrideWithValue(() => refreshes++),
      playbackControllerProvider.overrideWithValue(controller),
      playNoticesProvider.overrideWithValue(notices),
      playbackStateProvider.overrideWith((ref) async* {
        yield initial;
        yield* playback.stream;
      }),
      reachabilityProvider.overrideWithValue(reachability),
      profilesProvider.overrideWith((ref) => Stream.value(const <Profile>[])),
      initialActiveProfileIdProvider.overrideWithValue(null),
    ];
    await tester.pumpApp(
      WindowClassScope(
        windowClass: windowClassOf(size),
        child: Router.withConfig(config: router),
      ),
      size: size,
      overrides: overrides,
    );
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(VibeScreen.searchKey), text);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  List<String> playedTitles() => [
    for (final item in controller.plays.single.$1)
      (item as TrackQueueItem).track.meta.title,
  ];

  group('enabled with vibe', () {
    testWidgets('typing a query lists results after the debounce; Play all '
        'queues the playable ones', (tester) async {
      await pump(tester);

      await tester.enterText(find.byKey(VibeScreen.searchKey), 'rainy day');
      await tester.pump(const Duration(milliseconds: 300));
      expect(vibe.queries, isEmpty);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(vibe.queries, ['rainy day']);
      expect(find.text('Rain'), findsOneWidget);
      expect(find.text('Storm'), findsOneWidget);

      await tester.tap(find.byKey(VibeScreen.playAllKey));
      await tester.pumpAndSettle();
      expect(playedTitles(), ['Rain', 'Storm']);
      expect(controller.plays.single.$3?.kind, QueueContextKind.search);
    });

    testWidgets('clearing the field shows similar tracks for the current '
        'track, which follow the track after a pause', (tester) async {
      await pump(tester, current: _track('Seed', libraryId: 'l-1'));
      await type(tester, 'rainy day');
      expect(find.text(_similarTitle), findsNothing);

      await tester.tap(find.byKey(VibeScreen.clearKey));
      await tester.pumpAndSettle();
      expect(find.text(_similarTitle), findsOneWidget);
      expect(find.text('Seed'), findsOneWidget);
      expect(find.text('Near'), findsOneWidget);
      // The screen asks again after the search; the repository memoises.
      expect(vibe.similarIds.toSet(), {'l-1'});

      playback.add(_playing(_track('Next', libraryId: 'l-5')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Near'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Other'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      await tester.tap(find.byKey(VibeScreen.playAllKey));
      await tester.pumpAndSettle();
      expect(playedTitles(), ['Other']);
      expect(controller.plays.single.$3?.kind, QueueContextKind.radio);
    });

    testWidgets('a search with no result says No matches', (tester) async {
      vibe.searchTracks = [];
      await pump(tester);
      await type(tester, 'nothing like it');

      expect(find.text('No matches'), findsOneWidget);
    });

    testWidgets('a 503 from search says it is unavailable, with Retry', (
      tester,
    ) async {
      vibe.searchError = const api.Upstream(status: 503);
      await pump(tester);
      await type(tester, 'rainy day');

      expect(find.text('Vibe search is unavailable right now'), findsOneWidget);
      vibe.searchError = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Rain'), findsOneWidget);
      expect(find.byKey(VibeScreen.searchKey), findsOneWidget);
      expect(refreshes, 0);
    });

    testWidgets('FeatureDisabled hides the feature and asks for a capability '
        'refresh', (tester) async {
      vibe.searchError = const api.FeatureDisabled(status: 404);
      await pump(tester);
      await type(tester, 'rainy day');

      expect(refreshes, 1);
      expect(find.byKey(VibeScreen.searchKey), findsNothing);
      expect(find.text('Not available on this server'), findsOneWidget);
    });

    testWidgets('meets the tap target, label and contrast guidelines, and the '
        'search field has a label', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        current: _track('Seed', libraryId: 'l-1'),
        size: const Size(390, 844),
      );

      expect(
        find.bySemanticsLabel(RegExp('Search by description')),
        findsWidgets,
      );
      handle.dispose();
      await expectMeetsGuidelines(tester);
      await type(tester, 'rainy day');
      await expectMeetsGuidelines(tester);
    });
  });

  group('enabled without vibe', () {
    testWidgets('no search field; the similar section still works', (
      tester,
    ) async {
      await pump(
        tester,
        search: false,
        current: _track('Seed', libraryId: 'l-1'),
      );

      expect(find.byKey(VibeScreen.searchKey), findsNothing);
      expect(find.text(_similarTitle), findsOneWidget);
      expect(find.text('Near'), findsOneWidget);
    });
  });

  testWidgets('disabled: Not available on this server, and no request', (
    tester,
  ) async {
    await pump(
      tester,
      audioAnalysis: false,
      current: _track('Seed', libraryId: 'l-1'),
    );

    expect(find.text('Not available on this server'), findsOneWidget);
    expect(find.byKey(VibeScreen.searchKey), findsNothing);
    expect(vibe.similarIds, isEmpty);
    expect(vibe.queries, isEmpty);
  });

  testWidgets('nothing playing shows what Vibe does', (tester) async {
    await pump(tester);

    expect(
      find.text('Play a track to see others that sound like it here.'),
      findsOneWidget,
    );
    expect(vibe.similarIds, isEmpty);
  });

  testWidgets('a current track without a library id shows what Vibe does', (
    tester,
  ) async {
    await pump(tester, current: _track('Seed'));

    expect(
      find.text('Play a track to see others that sound like it here.'),
      findsOneWidget,
    );
  });

  testWidgets('offline shows the offline state', (tester) async {
    reachability.set(Reachability.noNetwork);
    await pump(tester, current: _track('Seed', libraryId: 'l-1'));

    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    expect(vibe.similarIds, isEmpty);
  });
}
