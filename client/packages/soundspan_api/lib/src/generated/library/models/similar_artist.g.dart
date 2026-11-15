// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'similar_artist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimilarArtist _$SimilarArtistFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'albumCount',
      'coverArt',
      'id',
      'inLibrary',
      'mbid',
      'name',
      'ownedAlbumCount',
      'weight',
    ],
    disallowNullValues: const [
      'albumCount',
      'id',
      'inLibrary',
      'name',
      'ownedAlbumCount',
      'weight',
    ],
  );
  return SimilarArtist(
    albumCount: SimilarArtist._read_albumCount(json['albumCount']),
    coverArt: json['coverArt'] as String?,
    id: json['id'] as String,
    inLibrary: json['inLibrary'] as bool,
    mbid: json['mbid'] as String?,
    name: json['name'] as String,
    ownedAlbumCount: SimilarArtist._read_ownedAlbumCount(
      json['ownedAlbumCount'],
    ),
    weight: json['weight'] as num,
    additionalProperties:
        SimilarArtist._extras(json, 'additionalProperties') == null
        ? const {}
        : SimilarArtist._readExtras(
            SimilarArtist._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SimilarArtistToJson(SimilarArtist instance) =>
    <String, dynamic>{
      'albumCount': ?SimilarArtist._write_albumCount(instance.albumCount),
      'coverArt': instance.coverArt,
      'id': instance.id,
      'inLibrary': instance.inLibrary,
      'mbid': instance.mbid,
      'name': instance.name,
      'ownedAlbumCount': ?SimilarArtist._write_ownedAlbumCount(
        instance.ownedAlbumCount,
      ),
      'weight': instance.weight,
    };
