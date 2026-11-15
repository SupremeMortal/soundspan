// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radio_audio_features.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadioAudioFeatures _$RadioAudioFeaturesFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'analysisMode',
      'arousal',
      'bpm',
      'danceability',
      'energy',
      'instrumentalness',
      'keyScale',
      'moodAcoustic',
      'moodAggressive',
      'moodElectronic',
      'moodHappy',
      'moodParty',
      'moodRelaxed',
      'moodSad',
      'valence',
    ],
  );
  return RadioAudioFeatures(
    analysisMode: json['analysisMode'] as String?,
    arousal: json['arousal'] as num?,
    bpm: json['bpm'] as num?,
    danceability: json['danceability'] as num?,
    energy: json['energy'] as num?,
    instrumentalness: json['instrumentalness'] as num?,
    keyScale: json['keyScale'] as String?,
    moodAcoustic: json['moodAcoustic'] as num?,
    moodAggressive: json['moodAggressive'] as num?,
    moodElectronic: json['moodElectronic'] as num?,
    moodHappy: json['moodHappy'] as num?,
    moodParty: json['moodParty'] as num?,
    moodRelaxed: json['moodRelaxed'] as num?,
    moodSad: json['moodSad'] as num?,
    valence: json['valence'] as num?,
    additionalProperties:
        RadioAudioFeatures._extras(json, 'additionalProperties') == null
        ? const {}
        : RadioAudioFeatures._readExtras(
            RadioAudioFeatures._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$RadioAudioFeaturesToJson(RadioAudioFeatures instance) =>
    <String, dynamic>{
      'analysisMode': instance.analysisMode,
      'arousal': instance.arousal,
      'bpm': instance.bpm,
      'danceability': instance.danceability,
      'energy': instance.energy,
      'instrumentalness': instance.instrumentalness,
      'keyScale': instance.keyScale,
      'moodAcoustic': instance.moodAcoustic,
      'moodAggressive': instance.moodAggressive,
      'moodElectronic': instance.moodElectronic,
      'moodHappy': instance.moodHappy,
      'moodParty': instance.moodParty,
      'moodRelaxed': instance.moodRelaxed,
      'moodSad': instance.moodSad,
      'valence': instance.valence,
    };
