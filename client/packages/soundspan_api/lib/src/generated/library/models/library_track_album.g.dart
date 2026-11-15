// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_track_album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LibraryTrackAlbum _$LibraryTrackAlbumFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['coverArt', 'id', 'title'],
    disallowNullValues: const ['artist', 'matchedInLibrary', 'title'],
  );
  return LibraryTrackAlbum(
    albumLoudnessLufs: json['albumLoudnessLufs'] as num?,
    albumTruePeakDb: json['albumTruePeakDb'] as num?,
    artist: json['artist'] == null
        ? null
        : LibraryTrackArtist.fromJson(json['artist'] as Map<String, dynamic>),
    coverArt: json['coverArt'] as String?,
    coverUrl: json['coverUrl'] as String?,
    id: json['id'] as String?,
    matchedInLibrary: json['matchedInLibrary'] as bool?,
    matchedRgMbid: json['matchedRgMbid'] as String?,
    rgMbid: json['rgMbid'] as String?,
    title: json['title'] as String,
    additionalProperties:
        LibraryTrackAlbum._extras(json, 'additionalProperties') == null
        ? const {}
        : LibraryTrackAlbum._readExtras(
            LibraryTrackAlbum._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$LibraryTrackAlbumToJson(LibraryTrackAlbum instance) =>
    <String, dynamic>{
      'albumLoudnessLufs': ?instance.albumLoudnessLufs,
      'albumTruePeakDb': ?instance.albumTruePeakDb,
      'artist': ?instance.artist?.toJson(),
      'coverArt': instance.coverArt,
      'coverUrl': ?instance.coverUrl,
      'id': instance.id,
      'matchedInLibrary': ?instance.matchedInLibrary,
      'matchedRgMbid': ?instance.matchedRgMbid,
      'rgMbid': ?instance.rgMbid,
      'title': instance.title,
    };
