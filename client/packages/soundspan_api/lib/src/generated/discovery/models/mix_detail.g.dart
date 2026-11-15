// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mix_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MixDetail _$MixDetailFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'color',
      'coverUrls',
      'description',
      'id',
      'name',
      'trackCount',
      'trackIds',
      'tracks',
      'type',
    ],
    disallowNullValues: const [
      'color',
      'coverUrls',
      'description',
      'id',
      'name',
      'trackCount',
      'trackIds',
      'tracks',
      'type',
    ],
  );
  return MixDetail(
    color: json['color'] as String,
    coverUrls: (json['coverUrls'] as List<dynamic>)
        .map((e) => e as String)
        .toList(),
    description: json['description'] as String,
    id: json['id'] as String,
    name: json['name'] as String,
    trackCount: MixDetail._read_trackCount(json['trackCount']),
    trackIds: (json['trackIds'] as List<dynamic>)
        .map((e) => e as String)
        .toList(),
    tracks: (json['tracks'] as List<dynamic>)
        .map((e) => TrackSummary.fromJson(e as Map<String, dynamic>))
        .toList(),
    type: json['type'] as String,
    additionalProperties:
        MixDetail._extras(json, 'additionalProperties') == null
        ? const {}
        : MixDetail._readExtras(
            MixDetail._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$MixDetailToJson(MixDetail instance) => <String, dynamic>{
  'color': instance.color,
  'coverUrls': instance.coverUrls,
  'description': instance.description,
  'id': instance.id,
  'name': instance.name,
  'trackCount': ?MixDetail._write_trackCount(instance.trackCount),
  'trackIds': instance.trackIds,
  'tracks': instance.tracks.map((e) => e.toJson()).toList(),
  'type': instance.type,
};
