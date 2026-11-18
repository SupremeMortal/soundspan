// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liked_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LikedTrack _$LikedTrackFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'album',
      'duration',
      'id',
      'likedAt',
      'source',
      'title',
      'trackNo',
    ],
    disallowNullValues: const [
      'album',
      'artist',
      'discNo',
      'duration',
      'id',
      'likedAt',
      'playbackId',
      'source',
      'title',
    ],
  );
  return LikedTrack(
    album: LibraryTrackAlbum.fromJson(json['album'] as Map<String, dynamic>),
    albumId: json['albumId'] as String?,
    artist: json['artist'] == null
        ? null
        : LibraryTrackArtist.fromJson(json['artist'] as Map<String, dynamic>),
    discNo: LikedTrack._read_discNo(json['discNo']),
    duration: LikedTrack._read_duration(json['duration']),
    id: json['id'] as String,
    isrc: json['isrc'] as String?,
    likedAt: LikedTrack._read_likedAt(json['likedAt']),
    loudnessLufs: json['loudnessLufs'] as num?,
    peer: json['peer'] == null
        ? null
        : PeerRef.fromJson(json['peer'] as Map<String, dynamic>),
    playbackId: json['playbackId'] as String?,
    source: LikedTrack._read_source(json['source']),
    title: json['title'] as String,
    trackNo: LikedTrack._read_trackNo(json['trackNo']),
    truePeakDb: json['truePeakDb'] as num?,
    additionalProperties:
        LikedTrack._extras(json, 'additionalProperties') == null
        ? const {}
        : LikedTrack._readExtras(
            LikedTrack._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$LikedTrackToJson(LikedTrack instance) =>
    <String, dynamic>{
      'album': instance.album.toJson(),
      'albumId': ?instance.albumId,
      'artist': ?instance.artist?.toJson(),
      'discNo': ?LikedTrack._write_discNo(instance.discNo),
      'duration': ?LikedTrack._write_duration(instance.duration),
      'id': instance.id,
      'isrc': ?instance.isrc,
      'likedAt': ?LikedTrack._write_likedAt(instance.likedAt),
      'loudnessLufs': ?instance.loudnessLufs,
      'peer': ?instance.peer?.toJson(),
      'playbackId': ?instance.playbackId,
      'source': ?LikedTrack._write_source(instance.source),
      'title': instance.title,
      'trackNo': LikedTrack._write_trackNo(instance.trackNo),
      'truePeakDb': ?instance.truePeakDb,
    };
