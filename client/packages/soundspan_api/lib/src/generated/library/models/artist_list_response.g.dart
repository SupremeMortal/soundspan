// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtistListResponse _$ArtistListResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['artists', 'limit', 'nextCursor', 'offset', 'total'],
    disallowNullValues: const ['artists', 'limit', 'offset', 'total'],
  );
  return ArtistListResponse(
    artists: (json['artists'] as List<dynamic>)
        .map((e) => ArtistSummary.fromJson(e as Map<String, dynamic>))
        .toList(),
    limit: ArtistListResponse._read_limit(json['limit']),
    nextCursor: json['nextCursor'] as String?,
    offset: ArtistListResponse._read_offset(json['offset']),
    total: ArtistListResponse._read_total(json['total']),
    additionalProperties:
        ArtistListResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : ArtistListResponse._readExtras(
            ArtistListResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ArtistListResponseToJson(ArtistListResponse instance) =>
    <String, dynamic>{
      'artists': instance.artists.map((e) => e.toJson()).toList(),
      'limit': ?ArtistListResponse._write_limit(instance.limit),
      'nextCursor': instance.nextCursor,
      'offset': ?ArtistListResponse._write_offset(instance.offset),
      'total': ?ArtistListResponse._write_total(instance.total),
    };
