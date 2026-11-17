// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Delivers the `episodeProgress` ops of the outbox (doc 07, Outbox) and
/// shows the pending ones on cached episodes. It lives outside
/// `lib/features/` because the outbox's handler registry in `core/sync`
/// may not import a feature.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/outbox_store.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/domain/podcast.dart';
import 'package:soundspan/shared/providers/cache.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// The op types the episode overlay reads.
const Set<String> episodeProgressOps = {EpisodeProgressOp.type};

/// Sends `episodeProgress` ops to
/// `POST /podcasts/:podcastId/episodes/:episodeId/progress`.
///
/// On success the sent progress is written into the cached episode. When
/// the server no longer has the episode (`notFound`) the episode is
/// removed from the cache, so its podcast is fetched again on its next
/// read. Every other outcome follows the worker's rules.
final class EpisodeProgressHandler implements OutboxHandler<EpisodeProgressOp> {
  /// Creates the handler over [_client] and the cache [_store] opens.
  const new(this._client, this._store);

  final api.PodcastsClient _client;
  final Future<CacheStore> Function() _store;

  @override
  Future<Object?> send(EpisodeProgressOp op) => _client.updateEpisodeProgress(
    podcastId: op.podcastId,
    episodeId: op.episodeId,
    body: api.UpdateEpisodeProgressRequest(
      currentTime: op.currentTime,
      duration: op.duration,
      isFinished: op.isFinished,
    ),
  );

  @override
  Future<void> onSuccess(EpisodeProgressOp op, Object? response) async {
    await (await _store()).updateEpisode(
      op.episodeId,
      (episode) => episode.copyWith(progress: progressOf(op)),
    );
  }

  @override
  Future<void> onDropped(EpisodeProgressOp op, OutboxDropReason reason) async {
    if (reason != OutboxDropReason.notFound) return;
    await (await _store()).removeEpisode(op.episodeId);
  }
}

/// The progress [op] saves.
EpisodeProgress progressOf(EpisodeProgressOp op) => EpisodeProgress(
  currentTimeSec: op.currentTime.toDouble(),
  isFinished: op.isFinished,
);

/// [episodes] with the progress of the pending `episodeProgress` ops of
/// [ops] (doc 07, Worker: optimistic state); the latest op of an episode
/// wins. Pure.
List<Episode> overlayEpisodeProgress(
  List<Episode> episodes,
  List<OutboxEntry> ops,
) {
  final pending = <String, EpisodeProgress>{
    for (final entry in ops)
      if (entry.op case final EpisodeProgressOp op)
        op.episodeId: progressOf(op),
  };
  if (pending.isEmpty) return episodes;
  return [
    for (final episode in episodes)
      if (pending[episode.id] case final progress?)
        episode.copyWith(progress: progress)
      else
        episode,
  ];
}

/// The handler of `episodeProgress` ops over [client] and the cache
/// [store] opens.
List<OutboxHandlerEntry> episodeProgressOutboxHandlers(
  api.PodcastsClient client,
  Future<CacheStore> Function() store,
) => [
  outboxHandlerEntry(
    EpisodeProgressOp.type,
    EpisodeProgressHandler(client, store),
  ),
];

/// The outbox handlers of episode progress.
final Provider<List<OutboxHandlerEntry>> episodeProgressOutboxHandlersProvider =
    Provider<List<OutboxHandlerEntry>>(
      (ref) => episodeProgressOutboxHandlers(
        ref.watch(soundspanApiProvider).rest.podcasts,
        () => ref.read(cacheStoreProvider.future),
      ),
      dependencies: [soundspanApiProvider, cacheStoreProvider],
    );
