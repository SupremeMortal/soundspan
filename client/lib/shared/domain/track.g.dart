// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrackMeta _$TrackMetaFromJson(Map<String, dynamic> json) => _TrackMeta(
  title: json['title'] as String,
  artist: json['artist'] as String,
  album: json['album'] as String,
  durationSec: (json['durationSec'] as num).toInt(),
  artworkRef: json['artworkRef'] as String?,
  isrc: json['isrc'] as String?,
);

Map<String, dynamic> _$TrackMetaToJson(_TrackMeta instance) =>
    <String, dynamic>{
      'title': instance.title,
      'artist': instance.artist,
      'album': instance.album,
      'durationSec': instance.durationSec,
      'artworkRef': instance.artworkRef,
      'isrc': instance.isrc,
    };

_Loudness _$LoudnessFromJson(Map<String, dynamic> json) => _Loudness(
  loudnessLufs: (json['loudnessLufs'] as num?)?.toDouble(),
  truePeakDb: (json['truePeakDb'] as num?)?.toDouble(),
  albumLoudnessLufs: (json['albumLoudnessLufs'] as num?)?.toDouble(),
  albumTruePeakDb: (json['albumTruePeakDb'] as num?)?.toDouble(),
);

Map<String, dynamic> _$LoudnessToJson(_Loudness instance) => <String, dynamic>{
  'loudnessLufs': instance.loudnessLufs,
  'truePeakDb': instance.truePeakDb,
  'albumLoudnessLufs': instance.albumLoudnessLufs,
  'albumTruePeakDb': instance.albumTruePeakDb,
};

_Track _$TrackFromJson(Map<String, dynamic> json) => _Track(
  meta: TrackMeta.fromJson(json['meta'] as Map<String, dynamic>),
  playbackId: _$JsonConverterFromJson<String, PlaybackId>(
    json['playbackId'],
    const PlaybackIdConverter().fromJson,
  ),
  albumId: json['albumId'] as String?,
  artistId: json['artistId'] as String?,
  loudness: json['loudness'] == null
      ? null
      : Loudness.fromJson(json['loudness'] as Map<String, dynamic>),
  preference:
      $enumDecodeNullable(_$PreferenceEnumMap, json['preference']) ??
      Preference.neutral,
  discNumber: (json['discNumber'] as num?)?.toInt(),
  trackNumber: (json['trackNumber'] as num?)?.toInt(),
  libraryTrackId: json['libraryTrackId'] as String?,
);

Map<String, dynamic> _$TrackToJson(_Track instance) => <String, dynamic>{
  'meta': instance.meta,
  'playbackId': _$JsonConverterToJson<String, PlaybackId>(
    instance.playbackId,
    const PlaybackIdConverter().toJson,
  ),
  'albumId': instance.albumId,
  'artistId': instance.artistId,
  'loudness': instance.loudness,
  'preference': _$PreferenceEnumMap[instance.preference]!,
  'discNumber': instance.discNumber,
  'trackNumber': instance.trackNumber,
  'libraryTrackId': instance.libraryTrackId,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$PreferenceEnumMap = {
  Preference.liked: 'liked',
  Preference.disliked: 'disliked',
  Preference.neutral: 'neutral',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
