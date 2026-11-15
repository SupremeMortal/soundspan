// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listen_group_playback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListenGroupPlayback _$ListenGroupPlaybackFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'currentIndex',
      'isPlaying',
      'positionMs',
      'queue',
      'serverTime',
      'stateVersion',
      'trackId',
    ],
    disallowNullValues: const [
      'currentIndex',
      'isPlaying',
      'positionMs',
      'queue',
      'serverTime',
      'stateVersion',
    ],
  );
  return ListenGroupPlayback(
    currentIndex: ListenGroupPlayback._read_currentIndex(json['currentIndex']),
    isPlaying: json['isPlaying'] as bool,
    positionMs: json['positionMs'] as num,
    queue: (json['queue'] as List<dynamic>)
        .map((e) => ListenQueueItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    serverTime: ListenGroupPlayback._read_serverTime(json['serverTime']),
    stateVersion: ListenGroupPlayback._read_stateVersion(json['stateVersion']),
    trackId: json['trackId'] as String?,
    additionalProperties:
        ListenGroupPlayback._extras(json, 'additionalProperties') == null
        ? const {}
        : ListenGroupPlayback._readExtras(
            ListenGroupPlayback._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ListenGroupPlaybackToJson(
  ListenGroupPlayback instance,
) => <String, dynamic>{
  'currentIndex': ?ListenGroupPlayback._write_currentIndex(
    instance.currentIndex,
  ),
  'isPlaying': instance.isPlaying,
  'positionMs': instance.positionMs,
  'queue': instance.queue.map((e) => e.toJson()).toList(),
  'serverTime': ?ListenGroupPlayback._write_serverTime(instance.serverTime),
  'stateVersion': ?ListenGroupPlayback._write_stateVersion(
    instance.stateVersion,
  ),
  'trackId': instance.trackId,
};
