// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/sync/data/playback_metadata.dart';
import 'package:soundspan/core/sync/play_report_result.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// Reports plays to the server (`POST /plays`, P8). `ApiException`
/// propagates.
final class PlaysRepository {
  /// Creates a repository over the generated playback client.
  new(this._client);

  final api.PlaybackClient _client;

  /// Reports a play of [playbackId] that began at [playedAt] and was heard
  /// for [listenedMs] in total. A repeat of the same report is answered with
  /// the play already recorded.
  Future<PlayReportResult> report({
    required PlaybackId playbackId,
    required TrackMeta meta,
    required DateTime playedAt,
    required int listenedMs,
  }) async {
    final response = await _client.recordPlay(
      body: api.RecordPlayRequest(
        playbackId: playbackId.value,
        metadata: playbackMetadataFromMeta(meta),
        playedAt: playedAt.toUtc(),
        listenedMs: listenedMs,
      ),
    );
    return response.hasPlayRecord
        ? PlayReportResult.recorded
        : PlayReportResult.notRecorded;
  }
}
