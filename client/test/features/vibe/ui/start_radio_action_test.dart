// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/shared/actions/app_menu_commands.dart';
import 'package:soundspan/shared/actions/track_actions.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/capability_refresh.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../../helpers/fake_reachability.dart';
import '../../../helpers/fake_vibe_repository.dart';
import '../../../helpers/pump_app.dart';

class _FixedCapabilities extends ServerCapabilitiesNotifier {
  new(this._value);

  final ServerCapabilities _value;

  @override
  ServerCapabilities build() => _value;
}

/// Records the commands the action sends to playback.
class _RecordingController extends Fake implements PlaybackController {
  final List<(List<QueueItem>, QueueContext?)> plays = [];

  @override
  Future<void> playItems(
    List<QueueItem> items, {
    int startIndex = 0,
    QueueContext? context,
  }) async => plays.add((items, context));
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

const _startRadio = 'Start radio';

void main() {
  late FakeVibeRepository vibe;
  late FakeReachability reachability;
  late _RecordingController controller;
  late int refreshes;

  setUp(() {
    vibe = FakeVibeRepository()
      ..similarTracks = [
        _track('Near', libraryId: 'l-2'),
        _track('Locked', libraryId: 'l-3', playable: false),
        _track('Close', libraryId: 'l-4'),
      ];
    reachability = FakeReachability();
    controller = _RecordingController();
    refreshes = 0;
  });

  Future<void> pump(
    WidgetTester tester,
    Track track, {
    bool audioAnalysis = true,
  }) async {
    await tester.pumpApp(
      Scaffold(
        body: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => unawaited(
              openTrackMenu(
                context,
                ref,
                TrackActionScope(
                  track: track,
                  tracks: [track],
                  index: 0,
                  context: const QueueContext(kind: QueueContextKind.library),
                ),
              ),
            ),
            child: const Text('menu'),
          ),
        ),
      ),
      overrides: [
        vibe.providerOverride,
        serverCapabilitiesProvider.overrideWith(
          () => _FixedCapabilities(
            ServerCapabilities(
              serverVersion: Version.tryParse('2.7.0'),
              hasP6SelfRevoke: true,
              hasP7PlayMarker: true,
              hasP8PlayedAt: true,
              audioAnalysis: audioAnalysis,
            ),
          ),
        ),
        capabilityRefreshProvider.overrideWithValue(() => refreshes++),
        playbackControllerProvider.overrideWithValue(controller),
        reachabilityProvider.overrideWithValue(reachability),
      ],
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.text('menu'));
    await tester.pumpAndSettle();
  }

  group('enabled', () {
    testWidgets('the track menu shows Start radio for a track with a library '
        'id; choosing it queues the track then the playable results as radio '
        'and plays', (tester) async {
      final seed = _track('Seed', libraryId: 'l-1');
      await pump(tester, seed);
      await openMenu(tester);

      expect(find.text(_startRadio), findsOneWidget);
      await tester.tap(find.text(_startRadio));
      await tester.pumpAndSettle();

      expect(vibe.similarIds, ['l-1']);
      final (items, context) = controller.plays.single;
      expect(
        [for (final item in items) (item as TrackQueueItem).track.meta.title],
        ['Seed', 'Near', 'Close'],
      );
      expect(context?.kind, QueueContextKind.radio);
      expect(context?.title, 'Seed');
      expect(
        items.every((item) => (item as TrackQueueItem).context == context),
        isTrue,
      );
    });

    testWidgets('an empty result shows a snackbar and leaves the queue alone', (
      tester,
    ) async {
      vibe.similarTracks = [];
      await pump(tester, _track('Seed', libraryId: 'l-1'));
      await openMenu(tester);
      await tester.tap(find.text(_startRadio));
      await tester.pumpAndSettle();

      expect(find.text('No similar tracks found'), findsOneWidget);
      expect(controller.plays, isEmpty);
    });

    testWidgets('a failure shows a snackbar', (tester) async {
      vibe.similarError = const api.ServerError(status: 500);
      await pump(tester, _track('Seed', libraryId: 'l-1'));
      await openMenu(tester);
      await tester.tap(find.text(_startRadio));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(controller.plays, isEmpty);
    });

    testWidgets('FeatureDisabled hides the action and asks for a capability '
        'refresh', (tester) async {
      vibe.similarError = const api.FeatureDisabled(status: 404);
      await pump(tester, _track('Seed', libraryId: 'l-1'));
      await openMenu(tester);
      await tester.tap(find.text(_startRadio));
      await tester.pumpAndSettle();
      expect(refreshes, 1);

      await openMenu(tester);
      expect(find.text('Play now'), findsOneWidget);
      expect(find.text(_startRadio), findsNothing);
    });

    testWidgets('hidden for a track without a library id', (tester) async {
      await pump(tester, _track('Seed'));
      await openMenu(tester);

      expect(find.text(_startRadio), findsNothing);
    });

    testWidgets('hidden while offline', (tester) async {
      reachability.set(Reachability.noNetwork);
      await pump(tester, _track('Seed', libraryId: 'l-1'));
      await openMenu(tester);

      expect(find.text(_startRadio), findsNothing);
    });
  });

  testWidgets('disabled: no action and no request', (tester) async {
    await pump(tester, _track('Seed', libraryId: 'l-1'), audioAnalysis: false);
    await openMenu(tester);

    expect(find.text(_startRadio), findsNothing);
    expect(vibe.similarIds, isEmpty);
  });
}
