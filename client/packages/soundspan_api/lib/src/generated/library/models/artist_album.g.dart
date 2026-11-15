// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtistAlbum _$ArtistAlbumFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'artistId',
      'coverArt',
      'id',
      'owned',
      'rgMbid',
      'source',
      'title',
      'tracks',
      'year',
    ],
    disallowNullValues: const [
      'artistId',
      'id',
      'owned',
      'provenanceSource',
      'remoteSources',
      'source',
      'title',
      'tracks',
    ],
  );
  return ArtistAlbum(
    artistId: json['artistId'] as String,
    coverArt: json['coverArt'] as String?,
    id: json['id'] as String,
    owned: json['owned'] as bool,
    peer: json['peer'] == null
        ? null
        : PeerRef.fromJson(json['peer'] as Map<String, dynamic>),
    primaryType: json['primaryType'] as String?,
    provenanceSource: ArtistAlbum._read_provenanceSource(
      json['provenanceSource'],
    ),
    remoteSources: ArtistAlbum._read_remoteSources(json['remoteSources']),
    rgMbid: json['rgMbid'] as String?,
    source: ArtistAlbum._read_source(json['source']),
    title: json['title'] as String,
    tracks: (json['tracks'] as List<dynamic>)
        .map((e) => TrackSummary.fromJson(e as Map<String, dynamic>))
        .toList(),
    year: ArtistAlbum._read_year(json['year']),
    additionalProperties:
        ArtistAlbum._extras(json, 'additionalProperties') == null
        ? const {}
        : ArtistAlbum._readExtras(
            ArtistAlbum._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ArtistAlbumToJson(
  ArtistAlbum instance,
) => <String, dynamic>{
  'artistId': instance.artistId,
  'coverArt': instance.coverArt,
  'id': instance.id,
  'owned': instance.owned,
  'peer': ?instance.peer?.toJson(),
  'primaryType': ?instance.primaryType,
  'provenanceSource': ?ArtistAlbum._write_provenanceSource(
    instance.provenanceSource,
  ),
  'remoteSources': ?ArtistAlbum._write_remoteSources(instance.remoteSources),
  'rgMbid': instance.rgMbid,
  'source': ?ArtistAlbum._write_source(instance.source),
  'title': instance.title,
  'tracks': instance.tracks.map((e) => e.toJson()).toList(),
  'year': ArtistAlbum._write_year(instance.year),
};
