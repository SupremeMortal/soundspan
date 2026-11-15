// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_cover_album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistCoverAlbum _$PlaylistCoverAlbumFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['coverArt']);
  return PlaylistCoverAlbum(
    coverArt: json['coverArt'] as String?,
    additionalProperties:
        PlaylistCoverAlbum._extras(json, 'additionalProperties') == null
        ? const {}
        : PlaylistCoverAlbum._readExtras(
            PlaylistCoverAlbum._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PlaylistCoverAlbumToJson(PlaylistCoverAlbum instance) =>
    <String, dynamic>{'coverArt': instance.coverArt};
