// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundspan/shared/domain/playback_id.dart';

part 'offline_models.freezed.dart';

/// What a download collection names: on the server (`POST /offline/items`,
/// doc 03) one track, or every visible track of an album or playlist; or,
/// on this device only, one podcast episode.
enum CollectionKind {
  /// One track; the id is its `playbackId`.
  track,

  /// An album; the id is the album id.
  album,

  /// A playlist; the id is the playlist id.
  playlist,

  /// A podcast episode; the id is `<podcastId>:<episodeId>`. Local only:
  /// it is never sent to the server's offline API.
  episode,
}

/// Why the server will not let a device download an item (doc 07,
/// Requesting a Download).
enum OfflineUnavailableReason {
  /// An admin turned offline downloads off (`SOURCE_DOWNLOADS_DISABLED`).
  downloadsDisabled,

  /// The track no longer exists (`TRACK_UNAVAILABLE`).
  trackUnavailable,

  /// The track cannot be streamed by this user (`SOURCE_UNAVAILABLE`).
  sourceUnavailable,

  /// A reason this client does not know.
  unknown,
}

/// The server's answer to an offline request: the items, and the byte
/// values of the user's server-side cache.
@freezed
abstract class OfflineResolution with _$OfflineResolution {
  /// Creates a resolution.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory OfflineResolution({
    /// The resolved items, in track order.
    required List<OfflineItem> items,

    /// The bytes the downloadable items are expected to take, if known.
    int? estimatedTotalBytes,

    /// The user's server-side cache limit in bytes, if known.
    int? cacheLimitBytes,

    /// The bytes the user's devices already hold, if known.
    int? cacheUsedBytes,
  }) = _OfflineResolution;
}

/// One item of an [OfflineResolution].
@freezed
abstract class OfflineItem with _$OfflineItem {
  /// Creates an item.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory OfflineItem({
    /// The track.
    required PlaybackId playbackId,

    /// Whether the device may download it.
    required bool downloadable,

    /// The server-relative URL of the file, kept verbatim; resolved with
    /// `StreamUrls.resolve`.
    String? downloadUrl,

    /// The bytes the server will send, if it can say.
    int? expectedBytes,

    /// The quality the server will send: `original`, `high`, `medium`,
    /// `low`, or a value a newer server added.
    String? quality,

    /// The content type of the file, if known.
    String? contentType,

    /// Why the item is not downloadable, when it is not.
    OfflineUnavailableReason? reason,
  }) = _OfflineItem;
}

/// An item the server believes a device holds (`GET /offline/items`).
@freezed
abstract class ServerOfflineItem with _$ServerOfflineItem {
  /// Creates a server item.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory ServerOfflineItem({
    /// The track.
    required PlaybackId playbackId,

    /// Whether the device must delete it.
    required bool revoked,

    /// The recorded quality.
    String? quality,

    /// The recorded size in bytes.
    int? sizeBytes,
  }) = _ServerOfflineItem;
}

/// The server's offline cache statistics (`GET /offline/stats`).
@freezed
abstract class OfflineStats with _$OfflineStats {
  /// Creates statistics.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory OfflineStats({
    /// Megabytes every device of the user holds.
    required double usedMb,

    /// The user's limit in megabytes.
    required double maxMb,

    /// Megabytes this device holds.
    required double deviceUsedMb,

    /// Tracks this device holds.
    required int deviceTrackCount,
  }) = _OfflineStats;
}
