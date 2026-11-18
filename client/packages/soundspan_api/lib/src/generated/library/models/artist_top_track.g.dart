// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_top_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtistTopTrack _$ArtistTopTrackFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['duration', 'id', 'title'],
    disallowNullValues: const [
      'album',
      'albumId',
      'artist',
      'discNo',
      'duration',
      'id',
      'listeners',
      'playCount',
      'playbackId',
      'title',
      'userPlayCount',
    ],
  );
  return ArtistTopTrack(
    album: json['album'] == null
        ? null
        : TrackAlbumRef.fromJson(json['album'] as Map<String, dynamic>),
    albumId: json['albumId'] as String?,
    artist: json['artist'] == null
        ? null
        : TrackArtistRef.fromJson(json['artist'] as Map<String, dynamic>),
    discNo: ArtistTopTrack._read_discNo(json['discNo']),
    duration: ArtistTopTrack._read_duration(json['duration']),
    id: json['id'] as String,
    isrc: json['isrc'] as String?,
    listeners: ArtistTopTrack._read_listeners(json['listeners']),
    loudnessLufs: json['loudnessLufs'] as num?,
    peer: json['peer'] == null
        ? null
        : PeerRef.fromJson(json['peer'] as Map<String, dynamic>),
    playCount: ArtistTopTrack._read_playCount(json['playCount']),
    playbackId: json['playbackId'] as String?,
    title: json['title'] as String,
    trackNo: ArtistTopTrack._read_trackNo(json['trackNo']),
    truePeakDb: json['truePeakDb'] as num?,
    userPlayCount: ArtistTopTrack._read_userPlayCount(json['userPlayCount']),
    additionalProperties:
        ArtistTopTrack._extras(json, 'additionalProperties') == null
        ? const {}
        : ArtistTopTrack._readExtras(
            ArtistTopTrack._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ArtistTopTrackToJson(
  ArtistTopTrack instance,
) => <String, dynamic>{
  'album': ?instance.album?.toJson(),
  'albumId': ?instance.albumId,
  'artist': ?instance.artist?.toJson(),
  'discNo': ?ArtistTopTrack._write_discNo(instance.discNo),
  'duration': ?ArtistTopTrack._write_duration(instance.duration),
  'id': instance.id,
  'isrc': ?instance.isrc,
  'listeners': ?ArtistTopTrack._write_listeners(instance.listeners),
  'loudnessLufs': ?instance.loudnessLufs,
  'peer': ?instance.peer?.toJson(),
  'playCount': ?ArtistTopTrack._write_playCount(instance.playCount),
  'playbackId': ?instance.playbackId,
  'title': instance.title,
  'trackNo': ?ArtistTopTrack._write_trackNo(instance.trackNo),
  'truePeakDb': ?instance.truePeakDb,
  'userPlayCount': ?ArtistTopTrack._write_userPlayCount(instance.userPlayCount),
};
