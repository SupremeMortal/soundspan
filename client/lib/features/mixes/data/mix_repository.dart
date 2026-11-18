// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/features/mixes/domain/mix_detail.dart';
import 'package:soundspan/features/mixes/domain/mix_repository.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/library/library_mappers.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/cached.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// The blob of the mix [mixId]: `mix:<id>`.
String mixBlobKey(String mixId) => 'mix:$mixId';

/// A generated mix (`GET /mixes/:id`). Its tracks map like the tracks of
/// an album or artist detail, so a track without a `playbackId` is not
/// playable; an empty description is null.
MixDetail mixDetailFromWire(api.MixDetail wire) => MixDetail(
  id: wire.id,
  name: wire.name,
  description: wire.description.isEmpty ? null : wire.description,
  artworkRefs: wire.coverUrls,
  tracks: [for (final track in wire.tracks) trackFromSummary(track)],
);

/// [MixRepository] over the cache and the generated `DiscoveryClient`.
/// Each mix is one blob, [mixBlobKey], with the detail TTL (doc 05, TTL
/// table).
class CachedMixRepository implements MixRepository {
  /// A repository reading [_client] into [_store] through [_swr].
  new(this._client, this._store, this._swr);

  final api.DiscoveryClient _client;
  final CacheStore _store;
  final Swr _swr;

  @override
  Stream<Cached<MixDetail>> mix(String mixId) => _swr.watch(
    key: mixBlobKey(mixId),
    ttl: detailTtl,
    cache: () => _store.watchBlob(
      mixBlobKey(mixId),
      (json) => MixDetail.fromJson(json! as Map<String, Object?>),
    ),
    fetch: () => _fetch(mixId),
  );

  @override
  Future<void> refreshMix(String mixId) =>
      _swr.refresh(mixBlobKey(mixId), () => _fetch(mixId));

  Future<void> _fetch(String mixId) async {
    final wire = await _client.getMix(id: mixId);
    await _store.putBlob(mixBlobKey(mixId), mixDetailFromWire(wire));
  }
}
