// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Album _$AlbumFromJson(Map<String, dynamic> json) => _Album(
  id: json['id'] as String,
  title: json['title'] as String,
  artistName: json['artistName'] as String,
  artistId: json['artistId'] as String,
  year: (json['year'] as num?)?.toInt(),
  artworkRef: json['artworkRef'] as String?,
  trackCount: (json['trackCount'] as num?)?.toInt(),
  releaseType: json['releaseType'] as String?,
);

Map<String, dynamic> _$AlbumToJson(_Album instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'artistName': instance.artistName,
  'artistId': instance.artistId,
  'year': instance.year,
  'artworkRef': instance.artworkRef,
  'trackCount': instance.trackCount,
  'releaseType': instance.releaseType,
};

_AlbumDetail _$AlbumDetailFromJson(Map<String, dynamic> json) => _AlbumDetail(
  album: Album.fromJson(json['album'] as Map<String, dynamic>),
  tracks: (json['tracks'] as List<dynamic>)
      .map((e) => Track.fromJson(e as Map<String, dynamic>))
      .toList(),
  owned: json['owned'] as bool,
);

Map<String, dynamic> _$AlbumDetailToJson(_AlbumDetail instance) =>
    <String, dynamic>{
      'album': instance.album,
      'tracks': instance.tracks,
      'owned': instance.owned,
    };
