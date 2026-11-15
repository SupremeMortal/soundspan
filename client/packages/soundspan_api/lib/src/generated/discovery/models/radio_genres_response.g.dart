// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radio_genres_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadioGenresResponse _$RadioGenresResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['genres'],
    disallowNullValues: const ['genres'],
  );
  return RadioGenresResponse(
    genres: (json['genres'] as List<dynamic>)
        .map((e) => RadioGenre.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        RadioGenresResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : RadioGenresResponse._readExtras(
            RadioGenresResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$RadioGenresResponseToJson(
  RadioGenresResponse instance,
) => <String, dynamic>{
  'genres': instance.genres.map((e) => e.toJson()).toList(),
};
