// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liked_tracks_cursor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LikedTracksCursor _$LikedTracksCursorFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['likedAt', 'trackId'],
    disallowNullValues: const ['likedAt', 'trackId'],
  );
  return LikedTracksCursor(
    likedAt: LikedTracksCursor._read_likedAt(json['likedAt']),
    trackId: json['trackId'] as String,
    additionalProperties:
        LikedTracksCursor._extras(json, 'additionalProperties') == null
        ? const {}
        : LikedTracksCursor._readExtras(
            LikedTracksCursor._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$LikedTracksCursorToJson(LikedTracksCursor instance) =>
    <String, dynamic>{
      'likedAt': ?LikedTracksCursor._write_likedAt(instance.likedAt),
      'trackId': instance.trackId,
    };
