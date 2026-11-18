// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchTrack _$SearchTrackFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['albumId', 'duration', 'id', 'title', 'trackNo'],
    disallowNullValues: const [
      'album',
      'albumId',
      'artist',
      'discNo',
      'duration',
      'id',
      'playbackId',
      'source',
      'title',
      'trackNo',
    ],
  );
  return SearchTrack(
    album: json['album'] == null
        ? null
        : TrackAlbumRef.fromJson(json['album'] as Map<String, dynamic>),
    albumId: json['albumId'] as String,
    artist: json['artist'] == null
        ? null
        : TrackArtistRef.fromJson(json['artist'] as Map<String, dynamic>),
    discNo: SearchTrack._read_discNo(json['discNo']),
    duration: SearchTrack._read_duration(json['duration']),
    id: json['id'] as String,
    isrc: json['isrc'] as String?,
    loudnessLufs: json['loudnessLufs'] as num?,
    peer: json['peer'] == null
        ? null
        : PeerRef.fromJson(json['peer'] as Map<String, dynamic>),
    playbackId: json['playbackId'] as String?,
    source: SearchTrack._read_source(json['source']),
    title: json['title'] as String,
    trackNo: SearchTrack._read_trackNo(json['trackNo']),
    truePeakDb: json['truePeakDb'] as num?,
    additionalProperties:
        SearchTrack._extras(json, 'additionalProperties') == null
        ? const {}
        : SearchTrack._readExtras(
            SearchTrack._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SearchTrackToJson(SearchTrack instance) =>
    <String, dynamic>{
      'album': ?instance.album?.toJson(),
      'albumId': instance.albumId,
      'artist': ?instance.artist?.toJson(),
      'discNo': ?SearchTrack._write_discNo(instance.discNo),
      'duration': ?SearchTrack._write_duration(instance.duration),
      'id': instance.id,
      'isrc': ?instance.isrc,
      'loudnessLufs': ?instance.loudnessLufs,
      'peer': ?instance.peer?.toJson(),
      'playbackId': ?instance.playbackId,
      'source': ?SearchTrack._write_source(instance.source),
      'title': instance.title,
      'trackNo': ?SearchTrack._write_trackNo(instance.trackNo),
      'truePeakDb': ?instance.truePeakDb,
    };
