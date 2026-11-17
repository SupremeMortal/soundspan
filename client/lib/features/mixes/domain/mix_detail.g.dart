// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mix_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MixDetail _$MixDetailFromJson(Map<String, dynamic> json) => _MixDetail(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  artworkRefs:
      (json['artworkRefs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  tracks:
      (json['tracks'] as List<dynamic>?)
          ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Track>[],
);

Map<String, dynamic> _$MixDetailToJson(_MixDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'artworkRefs': instance.artworkRefs,
      'tracks': instance.tracks,
    };
