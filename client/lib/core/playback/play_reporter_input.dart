// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/sync/episode_progress_reporter.dart';
import 'package:soundspan/core/sync/play_reporter.dart';

/// The [ListeningSource] and [EpisodeListeningSource] of a
/// [PlaybackController]: its snapshots as [ListeningState]s and its
/// [PlaybackController.entryEnded] events, for the `PlayReporter` and the
/// `EpisodeProgressReporter` in `core/sync`, which may not import
/// `core/playback`.
class ControllerListeningSource
    implements ListeningSource, EpisodeListeningSource {
  /// Adapts [_controller].
  new(this._controller);

  final PlaybackController _controller;

  @override
  Stream<ListeningState> get states => _controller.snapshots.map(
    (snapshot) => ListeningState(
      current: snapshot.current,
      audible: snapshot.status == EngineStatus.ready && snapshot.playing,
      playing: snapshot.playing,
      position: snapshot.position,
      duration: snapshot.duration,
    ),
  );

  @override
  Stream<String> get entryEnded =>
      _controller.entryEnded.map((event) => event.queueItemId);

  @override
  Stream<EndedEntry> get ended => _controller.entryEnded.map(
    (event) => (queueItemId: event.queueItemId, natural: event.natural),
  );
}
