// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_remote_album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchRemoteAlbum _$SearchRemoteAlbumFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'artist',
      'artistId',
      'coverUrl',
      'id',
      'remoteSources',
      'source',
      'title',
      'year',
    ],
    disallowNullValues: const [
      'artist',
      'artistId',
      'id',
      'remoteSources',
      'source',
      'title',
    ],
  );
  return SearchRemoteAlbum(
    artist: ArtistRef.fromJson(json['artist'] as Map<String, dynamic>),
    artistId: json['artistId'] as String,
    coverUrl: json['coverUrl'] as String?,
    id: json['id'] as String,
    remoteSources: SearchRemoteAlbum._read_remoteSources(json['remoteSources']),
    source: SearchRemoteAlbum._read_source(json['source']),
    title: json['title'] as String,
    year: SearchRemoteAlbum._read_year(json['year']),
    additionalProperties:
        SearchRemoteAlbum._extras(json, 'additionalProperties') == null
        ? const {}
        : SearchRemoteAlbum._readExtras(
            SearchRemoteAlbum._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SearchRemoteAlbumToJson(SearchRemoteAlbum instance) =>
    <String, dynamic>{
      'artist': instance.artist.toJson(),
      'artistId': instance.artistId,
      'coverUrl': instance.coverUrl,
      'id': instance.id,
      'remoteSources': ?SearchRemoteAlbum._write_remoteSources(
        instance.remoteSources,
      ),
      'source': ?SearchRemoteAlbum._write_source(instance.source),
      'title': instance.title,
      'year': SearchRemoteAlbum._write_year(instance.year),
    };
