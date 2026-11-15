// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_not_recorded.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlayNotRecorded _$PlayNotRecordedFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['recorded'],
    disallowNullValues: const ['recorded'],
  );
  return PlayNotRecorded(
    recorded: PlayNotRecorded._read_recorded(json['recorded']),
    additionalProperties:
        PlayNotRecorded._extras(json, 'additionalProperties') == null
        ? const {}
        : PlayNotRecorded._readExtras(
            PlayNotRecorded._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PlayNotRecordedToJson(PlayNotRecorded instance) =>
    <String, dynamic>{
      'recorded': ?PlayNotRecorded._write_recorded(instance.recorded),
    };
