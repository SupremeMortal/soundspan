// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'online_user_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OnlineUserTrack _$OnlineUserTrackFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'albumId',
      'albumTitle',
      'artistId',
      'artistName',
      'coverArt',
      'duration',
      'id',
      'title',
    ],
    disallowNullValues: const [
      'albumTitle',
      'artistName',
      'duration',
      'id',
      'playbackId',
      'title',
    ],
  );
  return OnlineUserTrack(
    albumId: json['albumId'] as String?,
    albumTitle: json['albumTitle'] as String,
    artistId: json['artistId'] as String?,
    artistName: json['artistName'] as String,
    coverArt: json['coverArt'] as String?,
    duration: json['duration'] as num,
    id: json['id'] as String,
    playbackId: json['playbackId'] as String?,
    title: json['title'] as String,
    additionalProperties:
        OnlineUserTrack._extras(json, 'additionalProperties') == null
        ? const {}
        : OnlineUserTrack._readExtras(
            OnlineUserTrack._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$OnlineUserTrackToJson(OnlineUserTrack instance) =>
    <String, dynamic>{
      'albumId': instance.albumId,
      'albumTitle': instance.albumTitle,
      'artistId': instance.artistId,
      'artistName': instance.artistName,
      'coverArt': instance.coverArt,
      'duration': instance.duration,
      'id': instance.id,
      'playbackId': ?instance.playbackId,
      'title': instance.title,
    };
