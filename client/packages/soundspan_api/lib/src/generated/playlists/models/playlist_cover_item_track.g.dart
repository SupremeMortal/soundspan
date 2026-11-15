// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_cover_item_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistCoverItemTrack _$PlaylistCoverItemTrackFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['album'],
    disallowNullValues: const ['album'],
  );
  return PlaylistCoverItemTrack(
    album: PlaylistCoverAlbum.fromJson(json['album'] as Map<String, dynamic>),
    additionalProperties:
        PlaylistCoverItemTrack._extras(json, 'additionalProperties') == null
        ? const {}
        : PlaylistCoverItemTrack._readExtras(
            PlaylistCoverItemTrack._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PlaylistCoverItemTrackToJson(
  PlaylistCoverItemTrack instance,
) => <String, dynamic>{'album': instance.album.toJson()};
