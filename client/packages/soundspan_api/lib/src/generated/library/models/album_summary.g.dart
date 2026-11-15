// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlbumSummary _$AlbumSummaryFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'artist',
      'artistId',
      'coverArt',
      'id',
      'rgMbid',
      'source',
      'title',
      'year',
    ],
    disallowNullValues: const [
      'artist',
      'artistId',
      'id',
      'peer',
      'remoteSources',
      'source',
      'title',
    ],
  );
  return AlbumSummary(
    artist: ArtistRef.fromJson(json['artist'] as Map<String, dynamic>),
    artistId: json['artistId'] as String,
    coverArt: json['coverArt'] as String?,
    id: json['id'] as String,
    peer: json['peer'] == null
        ? null
        : PeerRef.fromJson(json['peer'] as Map<String, dynamic>),
    remoteSources: AlbumSummary._read_remoteSources(json['remoteSources']),
    rgMbid: json['rgMbid'] as String?,
    source: AlbumSummary._read_source(json['source']),
    title: json['title'] as String,
    year: AlbumSummary._read_year(json['year']),
    additionalProperties:
        AlbumSummary._extras(json, 'additionalProperties') == null
        ? const {}
        : AlbumSummary._readExtras(
            AlbumSummary._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$AlbumSummaryToJson(
  AlbumSummary instance,
) => <String, dynamic>{
  'artist': instance.artist.toJson(),
  'artistId': instance.artistId,
  'coverArt': instance.coverArt,
  'id': instance.id,
  'peer': ?instance.peer?.toJson(),
  'remoteSources': ?AlbumSummary._write_remoteSources(instance.remoteSources),
  'rgMbid': instance.rgMbid,
  'source': ?AlbumSummary._write_source(instance.source),
  'title': instance.title,
  'year': AlbumSummary._write_year(instance.year),
};
