// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_playback_state_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SavePlaybackStateRequest _$SavePlaybackStateRequestFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['playbackType'],
    disallowNullValues: const [
      'currentIndex',
      'currentTime',
      'isPlaying',
      'isShuffle',
      'playbackId',
      'playbackType',
      'podcastId',
      'queue',
    ],
  );
  return SavePlaybackStateRequest(
    currentIndex: SavePlaybackStateRequest._read_currentIndex(
      json['currentIndex'],
    ),
    currentTime: json['currentTime'] as num?,
    isPlaying: json['isPlaying'] as bool?,
    isShuffle: json['isShuffle'] as bool?,
    playbackId: json['playbackId'] as String?,
    playbackType: SavePlaybackStateRequest._read_playbackType(
      json['playbackType'],
    ),
    podcastId: json['podcastId'] as String?,
    queue: (json['queue'] as List<dynamic>?)
        ?.map(
          (e) => SavePlaybackStateRequestQueueItem.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList(),
    additionalProperties:
        SavePlaybackStateRequest._extras(json, 'additionalProperties') == null
        ? const {}
        : SavePlaybackStateRequest._readExtras(
            SavePlaybackStateRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SavePlaybackStateRequestToJson(
  SavePlaybackStateRequest instance,
) => <String, dynamic>{
  'currentIndex': ?SavePlaybackStateRequest._write_currentIndex(
    instance.currentIndex,
  ),
  'currentTime': ?instance.currentTime,
  'isPlaying': ?instance.isPlaying,
  'isShuffle': ?instance.isShuffle,
  'playbackId': ?instance.playbackId,
  'playbackType': ?SavePlaybackStateRequest._write_playbackType(
    instance.playbackType,
  ),
  'podcastId': ?instance.podcastId,
  'queue': ?instance.queue?.map((e) => e.toJson()).toList(),
};
