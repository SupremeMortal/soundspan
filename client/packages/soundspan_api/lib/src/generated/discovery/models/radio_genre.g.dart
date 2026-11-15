// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radio_genre.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadioGenre _$RadioGenreFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['count', 'genre'],
    disallowNullValues: const ['count', 'genre'],
  );
  return RadioGenre(
    count: RadioGenre._read_count(json['count']),
    genre: json['genre'] as String,
    additionalProperties:
        RadioGenre._extras(json, 'additionalProperties') == null
        ? const {}
        : RadioGenre._readExtras(
            RadioGenre._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$RadioGenreToJson(RadioGenre instance) =>
    <String, dynamic>{
      'count': ?RadioGenre._write_count(instance.count),
      'genre': instance.genre,
    };
