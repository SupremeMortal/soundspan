// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/play_actions.dart';

import '../core/playback/controller/controller_harness.dart';

/// A [PlaybackController] over a fake engine that plays every source, for
/// screen tests that start playback; provide it through [overrides].
///
/// A playing row animates its equaliser bars, so tests [settle] with a few
/// pumps instead of `pumpAndSettle`, and [close] the rig before the end.
class PlayRig {
  /// The controller harness.
  final ControllerHarness harness = ControllerHarness(playAny: true);

  /// The controller the screens play through.
  PlaybackController get controller => harness.controller;

  /// The notices of the screens' play actions.
  final StreamController<PlayNotice> notices =
      StreamController<PlayNotice>.broadcast();

  /// Provides [controller] as the profile's playback controller, and
  /// [notices] as its play notices.
  List<Override> get overrides => [
    playbackControllerProvider.overrideWithValue(controller),
    playNoticesProvider.overrideWithValue(notices),
  ];

  /// The playback ids of the queue, in play order.
  List<String> get queued {
    final queue = controller.snapshot.queue;
    return [
      for (final index in queue.playOrder)
        switch (queue.items[index]) {
          TrackQueueItem(:final track) => track.playbackId!.value,
          EpisodeQueueItem(:final episode) => episode.id,
        },
    ];
  }

  /// The playback id of the current item, if it is a track.
  String? get current => switch (controller.snapshot.current) {
    TrackQueueItem(:final track) => track.playbackId?.value,
    _ => null,
  };

  /// The context of the queue.
  QueueContext? get context => controller.snapshot.queue.context;

  /// Lets the controller and the widgets handle what is pending.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// Removes the widgets and disposes the controller, so no timer is left.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    unawaited(controller.dispose());
    unawaited(notices.close());
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
  }
}
