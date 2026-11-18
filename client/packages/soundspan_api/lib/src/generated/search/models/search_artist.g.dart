// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_artist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchArtist _$SearchArtistFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['heroUrl', 'id', 'mbid', 'name', 'rank'],
    disallowNullValues: const ['id', 'name', 'rank', 'source'],
  );
  return SearchArtist(
    heroUrl: json['heroUrl'] as String?,
    id: json['id'] as String,
    mbid: json['mbid'] as String?,
    name: json['name'] as String,
    peer: json['peer'] == null
        ? null
        : PeerRef.fromJson(json['peer'] as Map<String, dynamic>),
    rank: json['rank'] as num,
    source: SearchArtist._read_source(json['source']),
    summary: json['summary'] as String?,
    additionalProperties:
        SearchArtist._extras(json, 'additionalProperties') == null
        ? const {}
        : SearchArtist._readExtras(
            SearchArtist._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SearchArtistToJson(SearchArtist instance) =>
    <String, dynamic>{
      'heroUrl': instance.heroUrl,
      'id': instance.id,
      'mbid': instance.mbid,
      'name': instance.name,
      'peer': ?instance.peer?.toJson(),
      'rank': instance.rank,
      'source': ?SearchArtist._write_source(instance.source),
      'summary': ?instance.summary,
    };
