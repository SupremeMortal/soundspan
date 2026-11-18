// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radio_station.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RadioGenre _$RadioGenreFromJson(Map<String, dynamic> json) => _RadioGenre(
  name: json['name'] as String,
  trackCount: (json['trackCount'] as num).toInt(),
);

Map<String, dynamic> _$RadioGenreToJson(_RadioGenre instance) =>
    <String, dynamic>{'name': instance.name, 'trackCount': instance.trackCount};

_RadioDecade _$RadioDecadeFromJson(Map<String, dynamic> json) => _RadioDecade(
  decade: (json['decade'] as num).toInt(),
  trackCount: (json['trackCount'] as num).toInt(),
);

Map<String, dynamic> _$RadioDecadeToJson(_RadioDecade instance) =>
    <String, dynamic>{
      'decade': instance.decade,
      'trackCount': instance.trackCount,
    };
