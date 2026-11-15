// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:dio/dio.dart' show CancelToken, Options;
import 'package:soundspan_api/soundspan_api.dart' as api;

/// In-memory stand-ins for the generated resource clients of `SoundspanApi`
/// (doc 11, Test Doubles), so repository tests exercise real request
/// sequences against a small server model.
final class FakeApi {
  /// The offline resource: `rest.offline`.
  final FakeOfflineClient offline = FakeOfflineClient();
}

/// One file a device reported as written.
typedef FakeHeldItem = ({String quality, int sizeBytes});

/// An in-memory model of the server's offline API (doc 07): per-device item
/// sets, the user's cache limit, the admin "downloads disabled" switch and
/// per-track unavailability. Every request body and query is kept in
/// [requests].
final class FakeOfflineClient implements api.OfflineClient {
  /// Bytes in one megabyte, as the server counts them.
  static const int bytesPerMb = 1024 * 1024;

  /// The tracks of each album, by album id.
  final Map<String, List<String>> albums = {};

  /// The tracks of each playlist, by playlist id.
  final Map<String, List<String>> playlists = {};

  /// The wire `reason` of each track the server refuses, by `playbackId`:
  /// `TRACK_UNAVAILABLE`, `SOURCE_UNAVAILABLE`, or any other string.
  final Map<String, String> unavailable = {};

  /// The bytes the server would send for each track; [defaultTrackBytes]
  /// when absent. A null value means the server cannot say.
  final Map<String, int?> trackBytes = {};

  /// The size of a track missing from [trackBytes].
  int defaultTrackBytes = 1000;

  /// The user's server-side cache limit.
  int cacheLimitBytes = 10 * 1024 * bytesPerMb;

  /// The admin switch: when true every item is refused with
  /// `SOURCE_DOWNLOADS_DISABLED` and every held item is revoked.
  bool downloadsDisabled = false;

  /// When true and [downloadsDisabled], `POST /items` answers 409
  /// `SOURCE_DOWNLOADS_DISABLED` instead of listing refused items.
  bool rejectWhenDisabled = false;

  /// The items each device holds, by device id and `playbackId`.
  final Map<String, Map<String, FakeHeldItem>> devices = {};

  /// Every request body (or, for queries, a map of the query), in order.
  final List<Object> requests = [];

  int get _usedBytes => devices.values
      .expand((items) => items.values)
      .fold(0, (sum, item) => sum + item.sizeBytes);

  @override
  Future<api.OfflineItemsResponse> requestOfflineItems({
    required api.RequestOfflineItemsRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    requests.add(body);
    if (downloadsDisabled && rejectWhenDisabled) {
      throw const api.DownloadsDisabled(
        status: 409,
        code: 'SOURCE_DOWNLOADS_DISABLED',
      );
    }
    final kind = body.kind.toJson();
    final ids = switch (kind) {
      'album' => albums[body.id],
      'playlist' => playlists[body.id],
      _ => [body.id],
    };
    if (ids == null) {
      throw api.NotFound(
        status: 404,
        code: kind == 'album' ? 'ALBUM_NOT_FOUND' : 'PLAYLIST_NOT_FOUND',
      );
    }
    final quality = body.quality?.toJson() ?? 'original';
    var estimate = 0;
    final items = <api.OfflineItem>[];
    for (final id in ids) {
      final reason = downloadsDisabled
          ? 'SOURCE_DOWNLOADS_DISABLED'
          : unavailable[id];
      if (reason != null) {
        items.add(
          api.OfflineItem(
            playbackId: id,
            downloadable: false,
            reason: api.OfflineItemReason.fromJson(reason),
          ),
        );
        continue;
      }
      final size = trackBytes.containsKey(id)
          ? trackBytes[id]
          : defaultTrackBytes;
      estimate += size ?? 0;
      items.add(
        api.OfflineItem(
          playbackId: id,
          downloadable: true,
          downloadUrl: '/api/playback/stream/$id?quality=$quality&report=0',
          expectedSize: size,
          quality: api.OfflineItemQuality.fromJson(quality),
          contentType: 'FLAC',
        ),
      );
    }
    final used = _usedBytes;
    if (used + estimate > cacheLimitBytes) {
      throw api.CacheLimitExceeded(
        limitBytes: cacheLimitBytes,
        usedBytes: used,
        estimatedBytes: estimate,
        status: 409,
        code: 'CACHE_LIMIT_EXCEEDED',
      );
    }
    return api.OfflineItemsResponse(
      items: items,
      estimatedTotalBytes: estimate,
      cacheLimitBytes: cacheLimitBytes,
      cacheUsedBytes: used,
    );
  }

  @override
  Future<api.CompletedOfflineItem> completeOfflineItem({
    required api.CompleteOfflineItemRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    requests.add(body);
    final quality = body.quality.toJson();
    (devices[body.deviceId] ??= {})[body.playbackId] = (
      quality: quality,
      sizeBytes: body.sizeBytes,
    );
    return api.CompletedOfflineItem(
      playbackId: body.playbackId,
      quality: api.CompletedOfflineItemQuality.fromJson(quality),
      sizeBytes: body.sizeBytes,
    );
  }

  @override
  Future<api.DeleteOfflineItemsResponse> deleteOfflineItems({
    required api.DeleteOfflineItemsRequest body,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    requests.add(body);
    final held = devices[body.deviceId] ?? {};
    var deleted = 0;
    for (final id in body.playbackIds.toSet()) {
      if (held.remove(id) != null) deleted++;
    }
    return api.DeleteOfflineItemsResponse(deletedCount: deleted);
  }

  @override
  Future<api.DeviceOfflineItemsResponse> listOfflineItems({
    required String deviceId,
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    requests.add({'deviceId': deviceId});
    final held = devices[deviceId] ?? {};
    return api.DeviceOfflineItemsResponse(
      items: [
        for (final MapEntry(key: id, value: item) in held.entries)
          api.DeviceOfflineItem(
            playbackId: id,
            quality: api.DeviceOfflineItemQuality.fromJson(item.quality),
            sizeBytes: item.sizeBytes,
            revoked:
                downloadsDisabled || unavailable[id] == 'TRACK_UNAVAILABLE',
          ),
      ],
    );
  }

  @override
  Future<api.OfflineStats> getOfflineStats({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
    String? deviceId,
  }) async {
    requests.add({'deviceId': deviceId});
    final used = _usedBytes;
    final held = devices[deviceId] ?? const {};
    final deviceBytes = held.values.fold(0, (sum, i) => sum + i.sizeBytes);
    final maxMb = cacheLimitBytes ~/ bytesPerMb;
    return api.OfflineStats(
      usedMb: used / bytesPerMb,
      maxMb: maxMb,
      availableMb: maxMb - used / bytesPerMb,
      percentUsed: maxMb == 0 ? 0 : used / bytesPerMb / maxMb * 100,
      trackCount: devices.values.fold(0, (sum, items) => sum + items.length),
      device: deviceId == null
          ? null
          : api.OfflineStatsDevice(
              deviceId: deviceId,
              usedMb: deviceBytes / bytesPerMb,
              trackCount: held.length,
            ),
    );
  }
}
