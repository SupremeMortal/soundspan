// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'similar_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimilarTrack _$SimilarTrackFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'audioFeatures',
      'distance',
      'duration',
      'id',
      'similarity',
      'title',
    ],
    disallowNullValues: const [
      'album',
      'albumId',
      'artist',
      'audioFeatures',
      'discNo',
      'distance',
      'duration',
      'id',
      'peer',
      'playbackId',
      'similarity',
      'title',
    ],
  );
  return SimilarTrack(
    album: json['album'] == null
        ? null
        : TrackAlbumRef.fromJson(json['album'] as Map<String, dynamic>),
    albumId: json['albumId'] as String?,
    artist: json['artist'] == null
        ? null
        : TrackArtistRef.fromJson(json['artist'] as Map<String, dynamic>),
    audioFeatures: VibeAudioFeatures.fromJson(
      json['audioFeatures'] as Map<String, dynamic>,
    ),
    discNo: SimilarTrack._read_discNo(json['discNo']),
    distance: json['distance'] as num,
    duration: SimilarTrack._read_duration(json['duration']),
    id: json['id'] as String,
    isrc: json['isrc'] as String?,
    loudnessLufs: json['loudnessLufs'] as num?,
    peer: json['peer'] == null
        ? null
        : PeerRef.fromJson(json['peer'] as Map<String, dynamic>),
    playbackId: json['playbackId'] as String?,
    similarity: json['similarity'] as num,
    title: json['title'] as String,
    trackNo: SimilarTrack._read_trackNo(json['trackNo']),
    truePeakDb: json['truePeakDb'] as num?,
    additionalProperties:
        SimilarTrack._extras(json, 'additionalProperties') == null
        ? const {}
        : SimilarTrack._readExtras(
            SimilarTrack._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SimilarTrackToJson(SimilarTrack instance) =>
    <String, dynamic>{
      'album': ?instance.album?.toJson(),
      'albumId': ?instance.albumId,
      'artist': ?instance.artist?.toJson(),
      'audioFeatures': instance.audioFeatures.toJson(),
      'discNo': ?SimilarTrack._write_discNo(instance.discNo),
      'distance': instance.distance,
      'duration': ?SimilarTrack._write_duration(instance.duration),
      'id': instance.id,
      'isrc': ?instance.isrc,
      'loudnessLufs': ?instance.loudnessLufs,
      'peer': ?instance.peer?.toJson(),
      'playbackId': ?instance.playbackId,
      'similarity': instance.similarity,
      'title': instance.title,
      'trackNo': ?SimilarTrack._write_trackNo(instance.trackNo),
      'truePeakDb': ?instance.truePeakDb,
    };
