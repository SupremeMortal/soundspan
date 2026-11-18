// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_features.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemFeatures _$SystemFeaturesFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'audioAnalysis',
      'autoPlaylists',
      'discovery',
      'federation',
      'loudnessTargetLufs',
      'vibeEmbeddings',
    ],
    disallowNullValues: const [
      'audioAnalysis',
      'autoPlaylists',
      'discovery',
      'federation',
      'loudnessTargetLufs',
      'vibeEmbeddings',
    ],
  );
  return SystemFeatures(
    audioAnalysis: json['audioAnalysis'] as bool,
    autoPlaylists: json['autoPlaylists'] as bool,
    discovery: json['discovery'] as bool,
    federation: json['federation'] as bool,
    loudnessTargetLufs: json['loudnessTargetLufs'] as num,
    vibeEmbeddings: json['vibeEmbeddings'] as bool,
    additionalProperties:
        SystemFeatures._extras(json, 'additionalProperties') == null
        ? const {}
        : SystemFeatures._readExtras(
            SystemFeatures._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SystemFeaturesToJson(SystemFeatures instance) =>
    <String, dynamic>{
      'audioAnalysis': instance.audioAnalysis,
      'autoPlaylists': instance.autoPlaylists,
      'discovery': instance.discovery,
      'federation': instance.federation,
      'loudnessTargetLufs': instance.loudnessTargetLufs,
      'vibeEmbeddings': instance.vibeEmbeddings,
    };
