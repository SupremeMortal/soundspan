// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radio_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadioTrack _$RadioTrackFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['duration', 'id', 'playbackId', 'title', 'trackNo'],
    disallowNullValues: const [
      'album',
      'albumId',
      'artist',
      'audioFeatures',
      'discNo',
      'duration',
      'id',
      'peer',
      'playbackId',
      'title',
      'trackNo',
    ],
  );
  return RadioTrack(
    album: json['album'] == null
        ? null
        : TrackAlbumRef.fromJson(json['album'] as Map<String, dynamic>),
    albumId: json['albumId'] as String?,
    artist: json['artist'] == null
        ? null
        : TrackArtistRef.fromJson(json['artist'] as Map<String, dynamic>),
    audioFeatures: json['audioFeatures'] == null
        ? null
        : RadioAudioFeatures.fromJson(
            json['audioFeatures'] as Map<String, dynamic>,
          ),
    discNo: RadioTrack._read_discNo(json['discNo']),
    duration: RadioTrack._read_duration(json['duration']),
    id: json['id'] as String,
    isrc: json['isrc'] as String?,
    loudnessLufs: json['loudnessLufs'] as num?,
    peer: json['peer'] == null
        ? null
        : PeerRef.fromJson(json['peer'] as Map<String, dynamic>),
    playbackId: json['playbackId'] as String,
    title: json['title'] as String,
    trackNo: RadioTrack._read_trackNo(json['trackNo']),
    truePeakDb: json['truePeakDb'] as num?,
    additionalProperties:
        RadioTrack._extras(json, 'additionalProperties') == null
        ? const {}
        : RadioTrack._readExtras(
            RadioTrack._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$RadioTrackToJson(RadioTrack instance) =>
    <String, dynamic>{
      'album': ?instance.album?.toJson(),
      'albumId': ?instance.albumId,
      'artist': ?instance.artist?.toJson(),
      'audioFeatures': ?instance.audioFeatures?.toJson(),
      'discNo': ?RadioTrack._write_discNo(instance.discNo),
      'duration': ?RadioTrack._write_duration(instance.duration),
      'id': instance.id,
      'isrc': ?instance.isrc,
      'loudnessLufs': ?instance.loudnessLufs,
      'peer': ?instance.peer?.toJson(),
      'playbackId': instance.playbackId,
      'title': instance.title,
      'trackNo': ?RadioTrack._write_trackNo(instance.trackNo),
      'truePeakDb': ?instance.truePeakDb,
    };
