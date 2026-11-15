// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlbumDetail _$AlbumDetailFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'artist',
      'artistId',
      'coverArt',
      'id',
      'matchedInLibrary',
      'matchedRgMbid',
      'owned',
      'rgMbid',
      'source',
      'title',
      'year',
    ],
    disallowNullValues: const [
      'artist',
      'artistId',
      'id',
      'matchedInLibrary',
      'owned',
      'remoteSources',
      'source',
      'title',
      'tracks',
    ],
  );
  return AlbumDetail(
    artist: ArtistRef.fromJson(json['artist'] as Map<String, dynamic>),
    artistId: json['artistId'] as String,
    coverArt: json['coverArt'] as String?,
    id: json['id'] as String,
    matchedInLibrary: json['matchedInLibrary'] as bool,
    matchedRgMbid: json['matchedRgMbid'] as String?,
    owned: json['owned'] as bool,
    peer: json['peer'] == null
        ? null
        : PeerRef.fromJson(json['peer'] as Map<String, dynamic>),
    remoteSources: AlbumDetail._read_remoteSources(json['remoteSources']),
    rgMbid: json['rgMbid'] as String?,
    source: AlbumDetail._read_source(json['source']),
    title: json['title'] as String,
    tracks: (json['tracks'] as List<dynamic>?)
        ?.map((e) => TrackSummary.fromJson(e as Map<String, dynamic>))
        .toList(),
    year: AlbumDetail._read_year(json['year']),
    additionalProperties:
        AlbumDetail._extras(json, 'additionalProperties') == null
        ? const {}
        : AlbumDetail._readExtras(
            AlbumDetail._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$AlbumDetailToJson(
  AlbumDetail instance,
) => <String, dynamic>{
  'artist': instance.artist.toJson(),
  'artistId': instance.artistId,
  'coverArt': instance.coverArt,
  'id': instance.id,
  'matchedInLibrary': instance.matchedInLibrary,
  'matchedRgMbid': instance.matchedRgMbid,
  'owned': instance.owned,
  'peer': ?instance.peer?.toJson(),
  'remoteSources': ?AlbumDetail._write_remoteSources(instance.remoteSources),
  'rgMbid': instance.rgMbid,
  'source': ?AlbumDetail._write_source(instance.source),
  'title': instance.title,
  'tracks': ?instance.tracks?.map((e) => e.toJson()).toList(),
  'year': AlbumDetail._write_year(instance.year),
};
