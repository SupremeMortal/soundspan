// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_track_artist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LibraryTrackArtist _$LibraryTrackArtistFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'name'],
    disallowNullValues: const ['name'],
  );
  return LibraryTrackArtist(
    id: json['id'] as String?,
    name: json['name'] as String,
    additionalProperties:
        LibraryTrackArtist._extras(json, 'additionalProperties') == null
        ? const {}
        : LibraryTrackArtist._readExtras(
            LibraryTrackArtist._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$LibraryTrackArtistToJson(LibraryTrackArtist instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
