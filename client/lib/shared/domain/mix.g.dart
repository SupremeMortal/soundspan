// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mix.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MixSummary _$MixSummaryFromJson(Map<String, dynamic> json) => _MixSummary(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  coverRefs:
      (json['coverRefs'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$MixSummaryToJson(_MixSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'coverRefs': instance.coverRefs,
    };
