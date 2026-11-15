// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlayRecord _$PlayRecordFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'listenedMs', 'playedAt', 'source'],
    disallowNullValues: const ['id', 'playedAt', 'source'],
  );
  return PlayRecord(
    id: json['id'] as String,
    listenedMs: PlayRecord._read_listenedMs(json['listenedMs']),
    playedAt: PlayRecord._read_playedAt(json['playedAt']),
    source: PlayRecord._read_source(json['source']),
    additionalProperties:
        PlayRecord._extras(json, 'additionalProperties') == null
        ? const {}
        : PlayRecord._readExtras(
            PlayRecord._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PlayRecordToJson(PlayRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'listenedMs': PlayRecord._write_listenedMs(instance.listenedMs),
      'playedAt': ?PlayRecord._write_playedAt(instance.playedAt),
      'source': ?PlayRecord._write_source(instance.source),
    };
