// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/features/podcasts/data/podcast_mappers.dart';
import 'package:soundspan/features/podcasts/domain/podcast_detail.dart';
import 'package:soundspan/features/podcasts/domain/podcast_ref.dart';
import 'package:soundspan/features/podcasts/domain/podcast_repository.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// The list of the subscribed podcasts.
const subscribedPodcastsKey = 'podcasts:subscribed';

/// The list of the episodes of the podcast [podcastId].
String podcastEpisodesKey(String podcastId) => 'podcast:$podcastId:episodes';

/// How long the subscribed list and a podcast detail are fresh (doc 05,
/// TTL table).
const podcastTtl = Duration(minutes: 10);

/// [PodcastRepository] over the cache and the generated `PodcastsClient`.
///
/// The subscribed podcasts are the list `podcasts:subscribed` of podcast
/// rows. A detail is the podcast row with the list `podcast:<id>:episodes`
/// of episode rows, written in one transaction; it is a cache miss when the
/// podcast row is gone or an episode row fails to decode. Subscribe and
/// unsubscribe are direct calls, not outbox operations (doc 07, Operations).
class CachedPodcastRepository implements PodcastRepository {
  /// A repository reading [_client] into [_store] through [_swr].
  new(this._client, this._store, this._swr);

  final api.PodcastsClient _client;
  final CacheStore _store;
  final Swr _swr;

  @override
  Stream<Cached<List<Podcast>>> subscribed() => _swr.watch(
    key: subscribedPodcastsKey,
    ttl: podcastTtl,
    cache: () => _store.watchList(subscribedPodcastsKey).map((list) {
      if (list == null || !_whole(list)) return null;
      return (value: list.items.cast<Podcast>(), fetchedAt: list.fetchedAt);
    }),
    fetch: _fetchSubscribed,
  );

  @override
  Future<void> refreshSubscribed() =>
      _swr.refresh(subscribedPodcastsKey, _fetchSubscribed);

  @override
  Stream<Cached<PodcastDetail>> detail(String podcastId) => _swr.watch(
    key: podcastEpisodesKey(podcastId),
    ttl: podcastTtl,
    cache: () =>
        _store.watchList(podcastEpisodesKey(podcastId)).asyncMap((list) async {
          if (list == null || !_whole(list)) return null;
          final podcast = await _store.readPodcast(podcastId);
          if (podcast == null) return null;
          return (
            value: PodcastDetail(
              podcast: podcast.value,
              episodes: list.items.cast<Episode>(),
            ),
            fetchedAt: list.fetchedAt,
          );
        }),
    fetch: () => _fetchDetail(podcastId),
  );

  @override
  Future<void> refreshDetail(String podcastId) => _swr.refresh(
    podcastEpisodesKey(podcastId),
    () => _fetchDetail(podcastId),
  );

  @override
  Future<void> subscribe(PodcastRef ref) =>
      _swr.refresh('podcast:subscribe:$ref', () async {
        await _client.subscribePodcast(body: subscribeRequestFromRef(ref));
        await _store.markListStale(subscribedPodcastsKey);
      });

  @override
  Future<void> unsubscribe(String podcastId) =>
      _swr.refresh('podcast:unsubscribe:$podcastId', () async {
        await _client.unsubscribePodcast(id: podcastId);
        await _store.markListStale(subscribedPodcastsKey);
      });

  @override
  Future<void> postProgress({
    required String podcastId,
    required String episodeId,
    required double currentTimeSec,
    required int durationSec,
    required bool isFinished,
  }) async {
    await _client.updateEpisodeProgress(
      podcastId: podcastId,
      episodeId: episodeId,
      body: api.UpdateEpisodeProgressRequest(
        currentTime: currentTimeSec,
        duration: durationSec,
        isFinished: isFinished,
      ),
    );
    await _store.updateEpisode(
      episodeId,
      (episode) => episode.copyWith(
        progress: EpisodeProgress(
          currentTimeSec: currentTimeSec,
          isFinished: isFinished,
        ),
      ),
    );
  }

  Future<void> _fetchSubscribed() async {
    final podcasts = [
      for (final podcast in await _client.listPodcasts())
        podcastFromSubscribed(podcast),
    ];
    await _store.writePage(
      subscribedPodcastsKey,
      offset: 0,
      items: podcasts,
      total: podcasts.length,
      complete: true,
    );
  }

  Future<void> _fetchDetail(String podcastId) async {
    final detail = podcastDetailFromWire(
      await _client.getPodcast(id: podcastId),
    );
    await _store.transaction(() async {
      await _store.upsertPodcasts([detail.podcast]);
      await _store.writePage(
        podcastEpisodesKey(podcastId),
        offset: 0,
        items: detail.episodes,
        total: detail.episodes.length,
        complete: true,
      );
    });
  }

  /// Whether every entry of [list] decoded; a list missing one is a cache
  /// miss (doc 05).
  static bool _whole(CacheListSnapshot list) =>
      list.items.length == (list.total ?? list.items.length);
}
