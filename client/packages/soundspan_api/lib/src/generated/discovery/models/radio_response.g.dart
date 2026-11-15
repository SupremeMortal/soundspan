// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radio_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadioResponse _$RadioResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['tracks'],
    disallowNullValues: const ['sourceFeatures', 'tracks'],
  );
  return RadioResponse(
    sourceFeatures: json['sourceFeatures'] == null
        ? null
        : RadioAudioFeatures.fromJson(
            json['sourceFeatures'] as Map<String, dynamic>,
          ),
    tracks: (json['tracks'] as List<dynamic>)
        .map((e) => RadioTrack.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        RadioResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : RadioResponse._readExtras(
            RadioResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$RadioResponseToJson(RadioResponse instance) =>
    <String, dynamic>{
      'sourceFeatures': ?instance.sourceFeatures?.toJson(),
      'tracks': instance.tracks.map((e) => e.toJson()).toList(),
    };
