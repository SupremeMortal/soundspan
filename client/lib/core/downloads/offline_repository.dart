// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// The most `playbackId`s one `DELETE /offline/items` may carry.
const maxOfflineDeleteBatch = 500;

/// The server's offline API (`/offline/items`, `/offline/stats`, doc 03),
/// mapped to domain types. Mapping is its only logic; `ApiException`
/// propagates unchanged.
final class OfflineRepository {
  /// Creates a repository over the generated offline client.
  new(this._client);

  final api.OfflineClient _client;

  /// Resolves the track, album or playlist [id] of [kind] to the items
  /// [deviceId] may download. A null [quality] leaves it to the server.
  ///
  /// Throws `CacheLimitExceeded` when the items would exceed the user's
  /// server-side limit, and `DownloadsDisabled` when the server refuses the
  /// request as a whole.
  Future<OfflineResolution> resolve(
    CollectionKind kind,
    String id, {
    required String deviceId,
    String? quality,
  }) async {
    final response = await _client.requestOfflineItems(
      body: api.RequestOfflineItemsRequest(
        deviceId: deviceId,
        id: id,
        kind: api.RequestOfflineItemsRequestKind.fromJson(kind.name),
        quality: quality == null
            ? null
            : api.RequestOfflineItemsRequestQuality.fromJson(quality),
      ),
    );
    return OfflineResolution(
      items: [for (final item in response.items) _item(item)],
      estimatedTotalBytes: response.estimatedTotalBytes,
      cacheLimitBytes: response.cacheLimitBytes,
      cacheUsedBytes: response.cacheUsedBytes,
    );
  }

  /// Records that [deviceId] holds [playbackId] at [quality], [sizeBytes]
  /// long.
  Future<void> complete({
    required String deviceId,
    required PlaybackId playbackId,
    required String quality,
    required int sizeBytes,
  }) async {
    await _client.completeOfflineItem(
      body: api.CompleteOfflineItemRequest(
        deviceId: deviceId,
        playbackId: playbackId.value,
        quality: api.CompleteOfflineItemRequestQuality.fromJson(quality),
        sizeBytes: sizeBytes,
      ),
    );
  }

  /// Removes [playbackIds] from what the server records for [deviceId] and
  /// returns how many it removed; unknown ids are ignored.
  ///
  /// Throws an [ArgumentError] for more than [maxOfflineDeleteBatch] ids;
  /// batching is the caller's job.
  Future<int> delete({
    required String deviceId,
    required List<PlaybackId> playbackIds,
  }) async {
    if (playbackIds.length > maxOfflineDeleteBatch) {
      throw ArgumentError.value(
        playbackIds.length,
        'playbackIds',
        'at most $maxOfflineDeleteBatch ids per request',
      );
    }
    final response = await _client.deleteOfflineItems(
      body: api.DeleteOfflineItemsRequest(
        deviceId: deviceId,
        playbackIds: [for (final id in playbackIds) id.value],
      ),
    );
    return response.deletedCount;
  }

  /// What the server believes [deviceId] holds.
  Future<List<ServerOfflineItem>> list({required String deviceId}) async {
    final response = await _client.listOfflineItems(deviceId: deviceId);
    return [
      for (final item in response.items)
        ServerOfflineItem(
          playbackId: PlaybackId(item.playbackId),
          quality: item.quality.toJson(),
          sizeBytes: item.sizeBytes,
          revoked: item.revoked,
        ),
    ];
  }

  /// The user's cache statistics, with [deviceId]'s share.
  Future<OfflineStats> stats({required String deviceId}) async {
    final response = await _client.getOfflineStats(deviceId: deviceId);
    return OfflineStats(
      usedMb: response.usedMb.toDouble(),
      maxMb: response.maxMb.toDouble(),
      deviceUsedMb: response.device?.usedMb.toDouble() ?? 0,
      deviceTrackCount: response.device?.trackCount ?? 0,
    );
  }

  static OfflineItem _item(api.OfflineItem item) => OfflineItem(
    playbackId: PlaybackId(item.playbackId),
    downloadable: item.downloadable,
    downloadUrl: item.downloadUrl,
    expectedBytes: item.expectedSize,
    quality: item.quality?.toJson(),
    contentType: item.contentType,
    reason: switch (item.reason) {
      null => null,
      api.OfflineItemReasonKnown(:final value) => switch (value) {
        api.OfflineItemReasonValue.sourceDownloadsDisabled =>
          OfflineUnavailableReason.downloadsDisabled,
        api.OfflineItemReasonValue.trackUnavailable =>
          OfflineUnavailableReason.trackUnavailable,
        api.OfflineItemReasonValue.sourceUnavailable =>
          OfflineUnavailableReason.sourceUnavailable,
      },
      api.OfflineItemReasonUnknown() => OfflineUnavailableReason.unknown,
    },
  );
}

/// The [OfflineRepository] of the profile scope.
final Provider<OfflineRepository> offlineRepositoryProvider =
    Provider<OfflineRepository>(
      (ref) => OfflineRepository(ref.watch(soundspanApiProvider).rest.offline),
      dependencies: [soundspanApiProvider],
    );
