// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LibraryTrack _$LibraryTrackFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'album',
      'duration',
      'id',
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
      'peer',
      'playbackId',
      'source',
      'title',
    ],
  );
  return LibraryTrack(
    album: LibraryTrackAlbum.fromJson(json['album'] as Map<String, dynamic>),
    albumId: json['albumId'] as String?,
    artist: json['artist'] == null
        ? null
        : LibraryTrackArtist.fromJson(json['artist'] as Map<String, dynamic>),
    discNo: LibraryTrack._read_discNo(json['discNo']),
    duration: LibraryTrack._read_duration(json['duration']),
    id: json['id'] as String,
    isrc: json['isrc'] as String?,
    loudnessLufs: json['loudnessLufs'] as num?,
    peer: json['peer'] == null
        ? null
        : PeerRef.fromJson(json['peer'] as Map<String, dynamic>),
    playbackId: json['playbackId'] as String?,
    source: LibraryTrack._read_source(json['source']),
    title: json['title'] as String,
    trackNo: LibraryTrack._read_trackNo(json['trackNo']),
    truePeakDb: json['truePeakDb'] as num?,
    additionalProperties:
        LibraryTrack._extras(json, 'additionalProperties') == null
        ? const {}
        : LibraryTrack._readExtras(
            LibraryTrack._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$LibraryTrackToJson(LibraryTrack instance) =>
    <String, dynamic>{
      'album': instance.album.toJson(),
      'albumId': ?instance.albumId,
      'artist': ?instance.artist?.toJson(),
      'discNo': ?LibraryTrack._write_discNo(instance.discNo),
      'duration': ?LibraryTrack._write_duration(instance.duration),
      'id': instance.id,
      'isrc': ?instance.isrc,
      'loudnessLufs': ?instance.loudnessLufs,
      'peer': ?instance.peer?.toJson(),
      'playbackId': ?instance.playbackId,
      'source': ?LibraryTrack._write_source(instance.source),
      'title': instance.title,
      'trackNo': LibraryTrack._write_trackNo(instance.trackNo),
      'truePeakDb': ?instance.truePeakDb,
    };
