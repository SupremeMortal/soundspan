// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackSummary _$TrackSummaryFromJson(Map<String, dynamic> json) {
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
      'playbackId',
      'title',
    ],
  );
  return TrackSummary(
    album: json['album'] == null
        ? null
        : TrackAlbumRef.fromJson(json['album'] as Map<String, dynamic>),
    albumId: json['albumId'] as String?,
    artist: json['artist'] == null
        ? null
        : TrackArtistRef.fromJson(json['artist'] as Map<String, dynamic>),
    discNo: TrackSummary._read_discNo(json['discNo']),
    duration: TrackSummary._read_duration(json['duration']),
    id: json['id'] as String,
    isrc: json['isrc'] as String?,
    loudnessLufs: json['loudnessLufs'] as num?,
    peer: json['peer'] == null
        ? null
        : PeerRef.fromJson(json['peer'] as Map<String, dynamic>),
    playbackId: json['playbackId'] as String?,
    title: json['title'] as String,
    trackNo: TrackSummary._read_trackNo(json['trackNo']),
    truePeakDb: json['truePeakDb'] as num?,
    additionalProperties:
        TrackSummary._extras(json, 'additionalProperties') == null
        ? const {}
        : TrackSummary._readExtras(
            TrackSummary._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$TrackSummaryToJson(TrackSummary instance) =>
    <String, dynamic>{
      'album': ?instance.album?.toJson(),
      'albumId': ?instance.albumId,
      'artist': ?instance.artist?.toJson(),
      'discNo': ?TrackSummary._write_discNo(instance.discNo),
      'duration': ?TrackSummary._write_duration(instance.duration),
      'id': instance.id,
      'isrc': ?instance.isrc,
      'loudnessLufs': ?instance.loudnessLufs,
      'peer': ?instance.peer?.toJson(),
      'playbackId': ?instance.playbackId,
      'title': instance.title,
      'trackNo': ?TrackSummary._write_trackNo(instance.trackNo),
      'truePeakDb': ?instance.truePeakDb,
    };
