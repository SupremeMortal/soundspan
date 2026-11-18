// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundspan/shared/domain/playback_id.dart';

part 'track.freezed.dart';
part 'track.g.dart';

/// The user's preference for a track or album.
enum Preference {
  /// Liked.
  liked,

  /// Disliked.
  disliked,

  /// Neither liked nor disliked.
  neutral,
}

/// What the client shows and sends back as `metadata` on every write
/// (doc 02, Domain Model).
@freezed
abstract class TrackMeta with _$TrackMeta {
  /// Creates track metadata.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory TrackMeta({
    /// The track title.
    required String title,

    /// The artist name; empty when the server sent none.
    required String artist,

    /// The album title; empty when the server sent none.
    required String album,

    /// The duration in whole seconds.
    required int durationSec,

    /// The value to pass to the cover-art endpoint, if any.
    String? artworkRef,

    /// The ISRC, if known.
    String? isrc,
  }) = _TrackMeta;

  /// Decodes metadata written by [TrackMeta.toJson].
  factory fromJson(Map<String, Object?> json) => _$TrackMetaFromJson(json);
}

/// Loudness values of a track and its album, for gain (doc 06).
@freezed
abstract class Loudness with _$Loudness {
  /// Creates loudness values.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory Loudness({
    /// Integrated loudness of the track, in LUFS.
    double? loudnessLufs,

    /// True peak of the track, in dBTP.
    double? truePeakDb,

    /// Integrated loudness of the track's album, in LUFS.
    double? albumLoudnessLufs,

    /// True peak of the track's album, in dBTP.
    double? albumTruePeakDb,
  }) = _Loudness;

  /// Decodes loudness written by [Loudness.toJson].
  factory fromJson(Map<String, Object?> json) => _$LoudnessFromJson(json);
}

/// A track, whatever its source (doc 02, Domain Model).
@freezed
abstract class Track with _$Track {
  /// Creates a track.
  // freezed reads only the class-named factory form.
  // ignore: unnecessary_type_name_in_constructor
  const factory Track({
    /// What is shown and sent back as `metadata`.
    required TrackMeta meta,

    /// The id to play the track by; null means not playable, and the row is
    /// shown disabled.
    @PlaybackIdConverter() PlaybackId? playbackId,

    /// The library album id, if any.
    String? albumId,

    /// The library artist id, if any.
    String? artistId,

    /// Loudness values, if the server sent any.
    Loudness? loudness,

    /// The user's preference.
    @Default(Preference.neutral) Preference preference,

    /// The disc number, if known.
    int? discNumber,

    /// The track number on its disc, if known.
    int? trackNumber,

    /// The track id the server sent on the payload, for lyrics and vibe
    /// lookups. It says nothing about where the track comes from and is
    /// never used to decide playability or to branch.
    String? libraryTrackId,
  }) = _Track;

  /// Decodes a track written by [Track.toJson].
  factory fromJson(Map<String, Object?> json) => _$TrackFromJson(json);
}

/// What the like button of a track shows.
extension TrackLike on Track {
  /// Whether the heart is filled: the client has two states, so a disliked
  /// track shows as not liked.
  bool get isLiked => preference == Preference.liked;
}
