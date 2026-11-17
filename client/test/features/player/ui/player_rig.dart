// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/queue/queue_reducer.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../../core/playback/controller/controller_harness.dart';
import '../../../core/playback/queue/queue_test_items.dart' show testContext;
import '../../../helpers/fake_clock.dart';

/// A track entry [id] (or [queueItemId]) titled "Song [id]" by
/// "The Band [id]" with the cover `cover-[id]`, linking to [artistId] when
/// given.
QueueItem playerItem(String id, {String? queueItemId, String? artistId}) =>
    QueueItem.track(
      queueItemId: queueItemId ?? id,
      track: Track(
        artistId: artistId,
        meta: TrackMeta(
          title: 'Song $id',
          artist: 'The Band $id',
          album: 'Record',
          durationSec: 10,
          artworkRef: 'cover-$id',
        ),
        playbackId: PlaybackId('pb-$id'),
      ),
      context: testContext,
    );

/// A [PlaybackController] over a [FakeEngine] for widget tests, provided
/// through [overrides].
class PlayerRig {
  /// Creates the rig; the controller keeps its volume in [settings] and
  /// shuffles with [reducer] when one is given.
  new({
    DeviceSettingsDao? settings,
    List<String> ids = const ['a', 'b', 'c'],
    QueueReducer reducer = const QueueReducer(),
  }) : harness = ControllerHarness(
         ids: ids,
         clock: FakeClock(),
         deviceSettings: settings,
         reducer: reducer,
       );

  /// The controller harness.
  final ControllerHarness harness;

  /// The controller under test.
  PlaybackController get controller => harness.controller;

  /// The engine behind the controller.
  FakeEngine get engine => harness.fake;

  /// Provides [controller] as the profile's playback controller.
  List<Override> get overrides => [
    playbackControllerProvider.overrideWithValue(controller),
  ];

  /// Lets the controller and the widgets handle what is pending.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  /// Queues [items], else [playerItem]s of [ids], and plays the first; the
  /// stream info is fetched at quality `original` (FLAC 16/44.1 kHz).
  Future<void> start(
    WidgetTester tester, {
    List<String> ids = const ['a', 'b', 'c'],
    List<QueueItem>? items,
    bool play = true,
  }) async {
    harness.resolver.quality = 'original';
    unawaited(
      controller.playItems(items ?? [for (final id in ids) playerItem(id)]),
    );
    await settle(tester);
    if (!play) {
      unawaited(controller.pause());
      await settle(tester);
    }
  }

  /// Lets [d] of playback pass on the engine, the clock and the test.
  Future<void> advance(WidgetTester tester, Duration d) async {
    engine.advance(d);
    (harness.clock as FakeClock).advance(d);
    await tester.pump(d);
  }

  /// Removes the widgets and disposes the controller, so no timer is left.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    unawaited(controller.dispose());
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
  }
}
