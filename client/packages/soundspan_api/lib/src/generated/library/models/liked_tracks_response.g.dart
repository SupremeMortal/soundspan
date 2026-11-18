// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liked_tracks_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LikedTracksResponse _$LikedTracksResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['pagination', 'playlist', 'total', 'tracks'],
    disallowNullValues: const ['pagination', 'playlist', 'total', 'tracks'],
  );
  return LikedTracksResponse(
    pagination: LikedTracksPagination.fromJson(
      json['pagination'] as Map<String, dynamic>,
    ),
    playlist: LikedPlaylistInfo.fromJson(
      json['playlist'] as Map<String, dynamic>,
    ),
    total: LikedTracksResponse._read_total(json['total']),
    tracks: (json['tracks'] as List<dynamic>)
        .map((e) => LikedTrack.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        LikedTracksResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : LikedTracksResponse._readExtras(
            LikedTracksResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$LikedTracksResponseToJson(
  LikedTracksResponse instance,
) => <String, dynamic>{
  'pagination': instance.pagination.toJson(),
  'playlist': instance.playlist.toJson(),
  'total': ?LikedTracksResponse._write_total(instance.total),
  'tracks': instance.tracks.map((e) => e.toJson()).toList(),
};
