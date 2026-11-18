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
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/features/discover/discover.dart';
import 'package:soundspan/features/explore/explore.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/capability_refresh.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan_api/soundspan_api.dart' show ServerError;

import '../../../helpers/fake_discovery_repository.dart';
import '../../../helpers/fake_radio_repository.dart';
import '../../../helpers/fake_reachability.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import '../../player/ui/player_rig.dart';

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

Track _track(String title, {bool playable = true}) => Track(
  meta: TrackMeta(
    title: title,
    artist: 'Artist',
    album: 'Album',
    durationSec: 200,
  ),
  playbackId: playable ? PlaybackId('pb-$title') : null,
);

const _byGenre = 'Radio by genre';
const _byDecade = 'Radio by decade';
const _thisWeek = 'This week’s discoveries';

void main() {
  late FakeDiscoveryRepository discovery;
  late FakeRadioRepository radio;
  late FakeReachability reachability;
  late _RecordingController controller;

  setUp(() {
    reachability = FakeReachability();
    controller = _RecordingController();
    discovery = FakeDiscoveryRepository()
      ..playlist = DiscoveryPlaylist(tracks: [_track('One')])
      ..recommended = const [DiscoveryArtist(name: 'Similar Soul')];
    radio = FakeRadioRepository()
      ..genreList = const [
        RadioGenre(name: 'jazz', trackCount: 18),
        RadioGenre(name: 'rock', trackCount: 40),
        RadioGenre(name: 'hip hop', trackCount: 25),
      ]
      ..decadeList = const [
        RadioDecade(decade: 1990, trackCount: 22),
        RadioDecade(decade: 2010, trackCount: 30),
        RadioDecade(decade: 2000, trackCount: 19),
      ]
      ..tracks = [
        _track('First'),
        _track('Locked', playable: false),
        _track('Second'),
      ];
  });

  Future<void> pump(
    WidgetTester tester, {
    bool discoveryOn = true,
    Size size = const Size(1440, 2400),
  }) async {
    final router = GoRouter(
      initialLocation: '/explore',
      routes: [
        GoRoute(path: '/explore', builder: (_, _) => const ExploreScreen()),
      ],
    );
    addTearDown(router.dispose);
    final overrides = <Override>[
      discovery.providerOverride,
      radio.providerOverride,
      serverCapabilitiesProvider.overrideWith(
        () => _FixedCapabilities(
          ServerCapabilities(
            serverVersion: Version.tryParse('2.7.0'),
            hasP6SelfRevoke: true,
            hasP7PlayMarker: true,
            hasP8PlayedAt: true,
            discovery: discoveryOn,
          ),
        ),
      ),
      capabilityRefreshProvider.overrideWithValue(() {}),
      playbackControllerProvider.overrideWithValue(controller),
      profilesProvider.overrideWith((ref) => Stream.value(const <Profile>[])),
      initialActiveProfileIdProvider.overrideWithValue(null),
      reachabilityProvider.overrideWithValue(reachability),
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

  Finder tile(RadioStation station) =>
      find.byKey(RadioSections.tileKey(station));

  /// The labels of the tiles of [section], in layout order.
  List<String> labels(WidgetTester tester, Key section) {
    final tiles = find.descendant(
      of: find.byKey(section),
      matching: find.byType(RadioStationTile),
    );
    return [
      for (final t in tester.widgetList<RadioStationTile>(tiles)) t.label,
    ];
  }

  group('discovery enabled', () {
    testWidgets('shows the discovery sections, then both radio sections', (
      tester,
    ) async {
      await pump(tester);

      final tops = [
        for (final title in [_thisWeek, _byGenre, _byDecade])
          tester.getTopLeft(find.text(title)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(radio.count('genres'), 1);
      expect(radio.count('decades'), 1);
    });
  });

  group('discovery disabled', () {
    testWidgets('shows only the radio sections and requests no discovery', (
      tester,
    ) async {
      await pump(tester, discoveryOn: false);

      expect(find.text(_byGenre), findsOneWidget);
      expect(find.text(_byDecade), findsOneWidget);
      expect(find.text(_thisWeek), findsNothing);
      expect(find.text('Not available on this server'), findsNothing);
      expect(discovery.reads, 0);
    });

    testWidgets('both lists empty shows the empty state', (tester) async {
      radio
        ..genreList = []
        ..decadeList = [];
      await pump(tester, discoveryOn: false);

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Nothing to explore yet'), findsOneWidget);
    });
  });

  testWidgets('genres are ordered by track count, decades newest first', (
    tester,
  ) async {
    await pump(tester, discoveryOn: false);

    expect(labels(tester, RadioSections.genresKey), [
      'Rock',
      'Hip Hop',
      'Jazz',
    ]);
    expect(labels(tester, RadioSections.decadesKey), [
      '2010s',
      '2000s',
      '1990s',
    ]);
    expect(find.text('40 tracks'), findsOneWidget);
  });

  testWidgets('shows 12 genres, and Show all shows the rest', (tester) async {
    radio.genreList = [
      for (var i = 0; i < 15; i++) RadioGenre(name: 'g$i', trackCount: 100 - i),
    ];
    await pump(tester, discoveryOn: false);

    expect(labels(tester, RadioSections.genresKey), hasLength(12));
    await tester.tap(find.text('Show all'));
    await tester.pumpAndSettle();
    expect(labels(tester, RadioSections.genresKey), hasLength(15));
    expect(find.text('Show all'), findsNothing);
  });

  testWidgets('an empty list hides its section', (tester) async {
    radio.genreList = [];
    await pump(tester, discoveryOn: false);

    expect(find.text(_byGenre), findsNothing);
    expect(find.text(_byDecade), findsOneWidget);
  });

  testWidgets('a genre tile replaces the queue with the playable tracks '
      'under a radio context', (tester) async {
    await pump(tester, discoveryOn: false);

    await tester.tap(tile(const GenreStation('rock')));
    await tester.pumpAndSettle();

    expect(radio.stations, [const GenreStation('rock')]);
    final (items, start, context) = controller.plays.single;
    expect(
      [for (final item in items) (item as TrackQueueItem).track.meta.title],
      ['First', 'Second'],
    );
    expect(start, 0);
    expect(context?.kind, QueueContextKind.radio);
    expect(context?.title, 'Rock');
    expect(
      (items.first as TrackQueueItem).context.kind,
      QueueContextKind.radio,
    );
  });

  testWidgets('a decade tile starts the decade station', (tester) async {
    await pump(tester, discoveryOn: false);

    await tester.tap(tile(const DecadeStation(1990)));
    await tester.pumpAndSettle();

    expect(radio.stations, [const DecadeStation(1990)]);
    expect(controller.plays.single.$3?.title, '1990s');
  });

  testWidgets('the tile shows progress while loading and ignores a second '
      'tap', (tester) async {
    radio.gate = Completer<void>();
    await pump(tester, discoveryOn: false);

    await tester.tap(tile(const GenreStation('rock')));
    await tester.pump();
    expect(
      find.descendant(
        of: tile(const GenreStation('rock')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    await tester.tap(tile(const GenreStation('rock')));
    await tester.pump();
    expect(radio.count('station'), 1);

    radio.gate!.complete();
    await tester.pumpAndSettle();
    expect(controller.plays, hasLength(1));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('an empty station shows a snackbar and leaves the queue', (
    tester,
  ) async {
    radio.tracks = [_track('Locked', playable: false)];
    await pump(tester, discoveryOn: false);

    await tester.tap(tile(const GenreStation('rock')));
    await tester.pumpAndSettle();

    expect(find.text('No tracks for this station'), findsOneWidget);
    expect(controller.plays, isEmpty);
  });

  testWidgets('a failed station shows Retry, which starts it again', (
    tester,
  ) async {
    radio.stationError = const ServerError(status: 500);
    await pump(tester, discoveryOn: false);

    await tester.tap(tile(const GenreStation('rock')));
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t start the station'), findsOneWidget);
    expect(controller.plays, isEmpty);

    radio.stationError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(radio.stations, hasLength(2));
    expect(controller.plays, hasLength(1));
  });

  testWidgets('offline, the tiles are disabled with the reason', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    reachability.set(Reachability.serverUnreachable);
    await pump(tester, discoveryOn: false);

    expect(
      find.bySemanticsLabel(
        'Rock, 40 tracks, radio station, Not available offline',
      ),
      findsOneWidget,
    );
    await tester.tap(tile(const GenreStation('rock')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(radio.count('station'), 0);
    handle.dispose();
  });

  testWidgets('each tile is labelled with its name, count and kind', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, discoveryOn: false);

    expect(
      find.bySemanticsLabel('Rock, 40 tracks, radio station'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('1990s, 22 tracks, radio station'),
      findsOneWidget,
    );
    handle.dispose();
  });

  for (final size in [
    TestSizes.compact,
    TestSizes.medium,
    TestSizes.expanded,
  ]) {
    testWidgets('meets the guidelines at ${size.width.toInt()}', (
      tester,
    ) async {
      await pump(tester, discoveryOn: false, size: size);

      await expectMeetsGuidelines(tester);
    });
  }

  testWidgets('the queue header shows the station', (tester) async {
    final rig = PlayerRig();
    final container = await tester.pumpApp(
      const Scaffold(body: QueueView()),
      overrides: rig.overrides,
    );
    container.read(playbackControllerProvider);
    rig.harness.resolver.quality = 'original';
    const context = QueueContext(kind: QueueContextKind.radio, title: 'Rock');
    unawaited(
      rig.controller.playItems([
        for (final id in ['a', 'b']) playerItem(id),
      ], context: context),
    );
    await rig.settle(tester);

    expect(find.text('Radio · Rock'), findsOneWidget);
    await rig.close(tester);
  });
}
