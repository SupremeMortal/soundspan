// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'popular_artists_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PopularArtistsResponse _$PopularArtistsResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['artists'],
    disallowNullValues: const ['artists'],
  );
  return PopularArtistsResponse(
    artists: (json['artists'] as List<dynamic>)
        .map((e) => PopularArtist.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        PopularArtistsResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : PopularArtistsResponse._readExtras(
            PopularArtistsResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PopularArtistsResponseToJson(
  PopularArtistsResponse instance,
) => <String, dynamic>{
  'artists': instance.artists.map((e) => e.toJson()).toList(),
};
