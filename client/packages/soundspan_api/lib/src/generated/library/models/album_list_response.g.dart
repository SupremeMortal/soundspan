// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlbumListResponse _$AlbumListResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['albums', 'limit', 'offset', 'total'],
    disallowNullValues: const ['albums', 'limit', 'offset', 'total'],
  );
  return AlbumListResponse(
    albums: (json['albums'] as List<dynamic>)
        .map((e) => AlbumSummary.fromJson(e as Map<String, dynamic>))
        .toList(),
    limit: AlbumListResponse._read_limit(json['limit']),
    offset: AlbumListResponse._read_offset(json['offset']),
    total: AlbumListResponse._read_total(json['total']),
    additionalProperties:
        AlbumListResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : AlbumListResponse._readExtras(
            AlbumListResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$AlbumListResponseToJson(AlbumListResponse instance) =>
    <String, dynamic>{
      'albums': instance.albums.map((e) => e.toJson()).toList(),
      'limit': ?AlbumListResponse._write_limit(instance.limit),
      'offset': ?AlbumListResponse._write_offset(instance.offset),
      'total': ?AlbumListResponse._write_total(instance.total),
    };
