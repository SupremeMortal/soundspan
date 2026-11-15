// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_track_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LibraryTrackListResponse _$LibraryTrackListResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['limit', 'offset', 'total', 'tracks'],
    disallowNullValues: const ['limit', 'offset', 'total', 'tracks'],
  );
  return LibraryTrackListResponse(
    limit: LibraryTrackListResponse._read_limit(json['limit']),
    offset: LibraryTrackListResponse._read_offset(json['offset']),
    total: LibraryTrackListResponse._read_total(json['total']),
    tracks: (json['tracks'] as List<dynamic>)
        .map((e) => LibraryTrack.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        LibraryTrackListResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : LibraryTrackListResponse._readExtras(
            LibraryTrackListResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$LibraryTrackListResponseToJson(
  LibraryTrackListResponse instance,
) => <String, dynamic>{
  'limit': ?LibraryTrackListResponse._write_limit(instance.limit),
  'offset': ?LibraryTrackListResponse._write_offset(instance.offset),
  'total': ?LibraryTrackListResponse._write_total(instance.total),
  'tracks': instance.tracks.map((e) => e.toJson()).toList(),
};
