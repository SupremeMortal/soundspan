// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vibe_audio_features.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VibeAudioFeatures _$VibeAudioFeaturesFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['arousal', 'danceability', 'energy', 'valence'],
  );
  return VibeAudioFeatures(
    arousal: json['arousal'] as num?,
    danceability: json['danceability'] as num?,
    energy: json['energy'] as num?,
    valence: json['valence'] as num?,
    additionalProperties:
        VibeAudioFeatures._extras(json, 'additionalProperties') == null
        ? const {}
        : VibeAudioFeatures._readExtras(
            VibeAudioFeatures._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$VibeAudioFeaturesToJson(VibeAudioFeatures instance) =>
    <String, dynamic>{
      'arousal': instance.arousal,
      'danceability': instance.danceability,
      'energy': instance.energy,
      'valence': instance.valence,
    };
