// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchAlbum _$SearchAlbumFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'artist',
      'artistId',
      'coverUrl',
      'id',
      'title',
      'year',
    ],
    disallowNullValues: const [
      'artist',
      'artistId',
      'id',
      'peer',
      'source',
      'title',
    ],
  );
  return SearchAlbum(
    artist: ArtistRef.fromJson(json['artist'] as Map<String, dynamic>),
    artistId: json['artistId'] as String,
    coverUrl: json['coverUrl'] as String?,
    id: json['id'] as String,
    peer: json['peer'] == null
        ? null
        : PeerRef.fromJson(json['peer'] as Map<String, dynamic>),
    source: SearchAlbum._read_source(json['source']),
    title: json['title'] as String,
    year: SearchAlbum._read_year(json['year']),
    additionalProperties:
        SearchAlbum._extras(json, 'additionalProperties') == null
        ? const {}
        : SearchAlbum._readExtras(
            SearchAlbum._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SearchAlbumToJson(SearchAlbum instance) =>
    <String, dynamic>{
      'artist': instance.artist.toJson(),
      'artistId': instance.artistId,
      'coverUrl': instance.coverUrl,
      'id': instance.id,
      'peer': ?instance.peer?.toJson(),
      'source': ?SearchAlbum._write_source(instance.source),
      'title': instance.title,
      'year': SearchAlbum._write_year(instance.year),
    };
