// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:flutter/foundation.dart' show immutable;
import 'package:soundspan/shared/domain/podcast.dart';

/// The metadata stored with a downloaded podcast episode
/// (`download_items.metaJson`, doc 05): what is needed to render and play
/// it offline, and the latest position played on this device.
@immutable
final class EpisodeDownloadMeta {
  /// Creates the metadata of episode [episodeId] of podcast [podcastId].
  const new({
    required this.episodeId,
    required this.podcastId,
    required this.title,
    required this.podcastTitle,
    this.durationSec,
    this.publishedAt,
    this.artworkRef,
    this.description,
    this.positionSec,
  });

  /// The metadata of [episode] of [podcast]; the artwork is the episode's,
  /// else the podcast's.
  factory of(Podcast podcast, Episode episode) => EpisodeDownloadMeta(
    episodeId: episode.id,
    podcastId: podcast.id,
    title: episode.title,
    podcastTitle: podcast.title,
    durationSec: episode.durationSec,
    publishedAt: episode.publishedAt,
    artworkRef: episode.artworkRef ?? podcast.artworkRef,
    description: episode.description,
    positionSec: episode.progress?.currentTimeSec,
  );

  /// The episode's id.
  final String episodeId;

  /// The podcast's id.
  final String podcastId;

  /// The episode title.
  final String title;

  /// The podcast title.
  final String podcastTitle;

  /// The duration in whole seconds, if known.
  final int? durationSec;

  /// When the episode was published, in UTC, if known.
  final DateTime? publishedAt;

  /// The episode's or the podcast's cover, if any.
  final String? artworkRef;

  /// The episode's description, if any.
  final String? description;

  /// The latest position played on this device, in seconds; null when
  /// none is known.
  final double? positionSec;

  /// Decodes [json]; null when it is not episode metadata.
  static EpisodeDownloadMeta? fromJson(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, Object?>) return null;
    if (decoded case {
      'episodeId': final String episodeId,
      'podcastId': final String podcastId,
      'title': final String title,
      'podcastTitle': final String podcastTitle,
    }) {
      return EpisodeDownloadMeta(
        episodeId: episodeId,
        podcastId: podcastId,
        title: title,
        podcastTitle: podcastTitle,
        durationSec: switch (decoded['durationSec']) {
          final num value => value.toInt(),
          _ => null,
        },
        publishedAt: switch (decoded['publishedAt']) {
          final String value => DateTime.tryParse(value)?.toUtc(),
          _ => null,
        },
        artworkRef: decoded['artworkRef'] as String?,
        description: decoded['description'] as String?,
        positionSec: switch (decoded['positionSec']) {
          final num value => value.toDouble(),
          _ => null,
        },
      );
    }
    return null;
  }

  /// The stored form.
  String toJson() => jsonEncode({
    'episodeId': episodeId,
    'podcastId': podcastId,
    'title': title,
    'podcastTitle': podcastTitle,
    'durationSec': durationSec,
    'publishedAt': publishedAt?.toUtc().toIso8601String(),
    'artworkRef': artworkRef,
    'description': description,
    'positionSec': positionSec,
  });

  /// This metadata with [positionSec] replaced.
  EpisodeDownloadMeta withPosition(double positionSec) => EpisodeDownloadMeta(
    episodeId: episodeId,
    podcastId: podcastId,
    title: title,
    podcastTitle: podcastTitle,
    durationSec: durationSec,
    publishedAt: publishedAt,
    artworkRef: artworkRef,
    description: description,
    positionSec: positionSec,
  );

  @override
  bool operator ==(Object other) =>
      other is EpisodeDownloadMeta && other.toJson() == toJson();

  @override
  int get hashCode => toJson().hashCode;

  /// The podcast, as far as the metadata knows it.
  Podcast toPodcast() =>
      Podcast(id: podcastId, title: podcastTitle, artworkRef: artworkRef);

  /// The episode, with [positionSec] as its unfinished progress.
  Episode toEpisode() {
    final position = positionSec;
    return Episode(
      id: episodeId,
      podcastId: podcastId,
      title: title,
      description: description,
      durationSec: durationSec,
      publishedAt: publishedAt,
      artworkRef: artworkRef,
      progress: position == null || position <= 0
          ? null
          : EpisodeProgress(currentTimeSec: position, isFinished: false),
    );
  }
}
