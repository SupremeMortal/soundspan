// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaybackState _$PlaybackStateFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'audiobookId',
      'createdAt',
      'currentIndex',
      'currentTime',
      'deviceId',
      'isPlaying',
      'isShuffle',
      'playbackType',
      'podcastId',
      'queue',
      'trackId',
      'updatedAt',
      'userId',
    ],
    disallowNullValues: const [
      'createdAt',
      'currentIndex',
      'currentTime',
      'deviceId',
      'isPlaying',
      'isShuffle',
      'playbackType',
      'updatedAt',
      'userId',
    ],
  );
  return PlaybackState(
    audiobookId: json['audiobookId'] as String?,
    createdAt: PlaybackState._read_createdAt(json['createdAt']),
    currentIndex: PlaybackState._read_currentIndex(json['currentIndex']),
    currentTime: json['currentTime'] as num,
    deviceId: json['deviceId'] as String,
    isPlaying: json['isPlaying'] as bool,
    isShuffle: json['isShuffle'] as bool,
    playbackType: PlaybackState._read_playbackType(json['playbackType']),
    podcastId: json['podcastId'] as String?,
    queue: (json['queue'] as List<dynamic>?)
        ?.map((e) => PlaybackQueueItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    trackId: json['trackId'] as String?,
    updatedAt: PlaybackState._read_updatedAt(json['updatedAt']),
    userId: json['userId'] as String,
    additionalProperties:
        PlaybackState._extras(json, 'additionalProperties') == null
        ? const {}
        : PlaybackState._readExtras(
            PlaybackState._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PlaybackStateToJson(PlaybackState instance) =>
    <String, dynamic>{
      'audiobookId': instance.audiobookId,
      'createdAt': ?PlaybackState._write_createdAt(instance.createdAt),
      'currentIndex': ?PlaybackState._write_currentIndex(instance.currentIndex),
      'currentTime': instance.currentTime,
      'deviceId': instance.deviceId,
      'isPlaying': instance.isPlaying,
      'isShuffle': instance.isShuffle,
      'playbackType': ?PlaybackState._write_playbackType(instance.playbackType),
      'podcastId': instance.podcastId,
      'queue': instance.queue?.map((e) => e.toJson()).toList(),
      'trackId': instance.trackId,
      'updatedAt': ?PlaybackState._write_updatedAt(instance.updatedAt),
      'userId': instance.userId,
    };
