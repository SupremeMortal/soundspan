// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vibe_search_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VibeSearchTrack _$VibeSearchTrackFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'distance',
      'duration',
      'id',
      'similarity',
      'title',
      'trackNo',
    ],
    disallowNullValues: const [
      'album',
      'albumId',
      'artist',
      'discNo',
      'distance',
      'duration',
      'id',
      'playbackId',
      'similarity',
      'title',
      'trackNo',
    ],
  );
  return VibeSearchTrack(
    album: json['album'] == null
        ? null
        : TrackAlbumRef.fromJson(json['album'] as Map<String, dynamic>),
    albumId: json['albumId'] as String?,
    artist: json['artist'] == null
        ? null
        : TrackArtistRef.fromJson(json['artist'] as Map<String, dynamic>),
    discNo: VibeSearchTrack._read_discNo(json['discNo']),
    distance: json['distance'] as num,
    duration: VibeSearchTrack._read_duration(json['duration']),
    id: json['id'] as String,
    isrc: json['isrc'] as String?,
    loudnessLufs: json['loudnessLufs'] as num?,
    peer: json['peer'] == null
        ? null
        : PeerRef.fromJson(json['peer'] as Map<String, dynamic>),
    playbackId: json['playbackId'] as String?,
    similarity: json['similarity'] as num,
    title: json['title'] as String,
    trackNo: VibeSearchTrack._read_trackNo(json['trackNo']),
    truePeakDb: json['truePeakDb'] as num?,
    additionalProperties:
        VibeSearchTrack._extras(json, 'additionalProperties') == null
        ? const {}
        : VibeSearchTrack._readExtras(
            VibeSearchTrack._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$VibeSearchTrackToJson(VibeSearchTrack instance) =>
    <String, dynamic>{
      'album': ?instance.album?.toJson(),
      'albumId': ?instance.albumId,
      'artist': ?instance.artist?.toJson(),
      'discNo': ?VibeSearchTrack._write_discNo(instance.discNo),
      'distance': instance.distance,
      'duration': ?VibeSearchTrack._write_duration(instance.duration),
      'id': instance.id,
      'isrc': ?instance.isrc,
      'loudnessLufs': ?instance.loudnessLufs,
      'peer': ?instance.peer?.toJson(),
      'playbackId': ?instance.playbackId,
      'similarity': instance.similarity,
      'title': instance.title,
      'trackNo': ?VibeSearchTrack._write_trackNo(instance.trackNo),
      'truePeakDb': ?instance.truePeakDb,
    };
