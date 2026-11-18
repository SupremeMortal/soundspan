// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtistDetail _$ArtistDetailFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'bio',
      'coverArt',
      'discographyComplete',
      'genres',
      'id',
      'mbid',
      'name',
      'source',
    ],
    disallowNullValues: const [
      'albums',
      'discographyComplete',
      'genres',
      'id',
      'name',
      'similarArtists',
      'source',
      'topTracks',
    ],
  );
  return ArtistDetail(
    albums: (json['albums'] as List<dynamic>?)
        ?.map((e) => ArtistAlbum.fromJson(e as Map<String, dynamic>))
        .toList(),
    bio: json['bio'] as String?,
    coverArt: json['coverArt'] as String?,
    discographyComplete: json['discographyComplete'] as bool,
    genres: (json['genres'] as List<dynamic>).map((e) => e as String).toList(),
    id: json['id'] as String,
    mbid: json['mbid'] as String?,
    name: json['name'] as String,
    peer: json['peer'] == null
        ? null
        : PeerRef.fromJson(json['peer'] as Map<String, dynamic>),
    similarArtists: (json['similarArtists'] as List<dynamic>?)
        ?.map((e) => SimilarArtist.fromJson(e as Map<String, dynamic>))
        .toList(),
    source: ArtistDetail._read_source(json['source']),
    topTracks: (json['topTracks'] as List<dynamic>?)
        ?.map((e) => ArtistTopTrack.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        ArtistDetail._extras(json, 'additionalProperties') == null
        ? const {}
        : ArtistDetail._readExtras(
            ArtistDetail._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ArtistDetailToJson(
  ArtistDetail instance,
) => <String, dynamic>{
  'albums': ?instance.albums?.map((e) => e.toJson()).toList(),
  'bio': instance.bio,
  'coverArt': instance.coverArt,
  'discographyComplete': instance.discographyComplete,
  'genres': instance.genres,
  'id': instance.id,
  'mbid': instance.mbid,
  'name': instance.name,
  'peer': ?instance.peer?.toJson(),
  'similarArtists': ?instance.similarArtists?.map((e) => e.toJson()).toList(),
  'source': ?ArtistDetail._write_source(instance.source),
  'topTracks': ?instance.topTracks?.map((e) => e.toJson()).toList(),
};
