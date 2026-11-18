// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_album_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackAlbumRef _$TrackAlbumRefFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['title'],
    disallowNullValues: const ['artist', 'id', 'title'],
  );
  return TrackAlbumRef(
    albumLoudnessLufs: json['albumLoudnessLufs'] as num?,
    albumTruePeakDb: json['albumTruePeakDb'] as num?,
    artist: json['artist'] == null
        ? null
        : ArtistRef.fromJson(json['artist'] as Map<String, dynamic>),
    coverArt: json['coverArt'] as String?,
    coverUrl: json['coverUrl'] as String?,
    id: json['id'] as String?,
    title: json['title'] as String,
    additionalProperties:
        TrackAlbumRef._extras(json, 'additionalProperties') == null
        ? const {}
        : TrackAlbumRef._readExtras(
            TrackAlbumRef._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$TrackAlbumRefToJson(TrackAlbumRef instance) =>
    <String, dynamic>{
      'albumLoudnessLufs': ?instance.albumLoudnessLufs,
      'albumTruePeakDb': ?instance.albumTruePeakDb,
      'artist': ?instance.artist?.toJson(),
      'coverArt': ?instance.coverArt,
      'coverUrl': ?instance.coverUrl,
      'id': ?instance.id,
      'title': instance.title,
    };
