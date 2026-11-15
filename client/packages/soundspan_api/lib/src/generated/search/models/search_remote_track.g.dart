// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_remote_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchRemoteTrack _$SearchRemoteTrackFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'album',
      'albumId',
      'artistId',
      'duration',
      'id',
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
      'title',
    ],
  );
  return SearchRemoteTrack(
    album: LibraryTrackAlbum.fromJson(json['album'] as Map<String, dynamic>),
    albumId: json['albumId'] as String?,
    artist: json['artist'] == null
        ? null
        : LibraryTrackArtist.fromJson(json['artist'] as Map<String, dynamic>),
    artistId: json['artistId'] as String?,
    discNo: SearchRemoteTrack._read_discNo(json['discNo']),
    duration: SearchRemoteTrack._read_duration(json['duration']),
    id: json['id'] as String,
    isrc: json['isrc'] as String?,
    loudnessLufs: json['loudnessLufs'] as num?,
    peer: json['peer'] == null
        ? null
        : PeerRef.fromJson(json['peer'] as Map<String, dynamic>),
    playbackId: json['playbackId'] as String?,
    title: json['title'] as String,
    trackNo: SearchRemoteTrack._read_trackNo(json['trackNo']),
    truePeakDb: json['truePeakDb'] as num?,
    additionalProperties:
        SearchRemoteTrack._extras(json, 'additionalProperties') == null
        ? const {}
        : SearchRemoteTrack._readExtras(
            SearchRemoteTrack._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SearchRemoteTrackToJson(SearchRemoteTrack instance) =>
    <String, dynamic>{
      'album': instance.album.toJson(),
      'albumId': instance.albumId,
      'artist': ?instance.artist?.toJson(),
      'artistId': instance.artistId,
      'discNo': ?SearchRemoteTrack._write_discNo(instance.discNo),
      'duration': ?SearchRemoteTrack._write_duration(instance.duration),
      'id': instance.id,
      'isrc': ?instance.isrc,
      'loudnessLufs': ?instance.loudnessLufs,
      'peer': ?instance.peer?.toJson(),
      'playbackId': ?instance.playbackId,
      'title': instance.title,
      'trackNo': SearchRemoteTrack._write_trackNo(instance.trackNo),
      'truePeakDb': ?instance.truePeakDb,
    };
