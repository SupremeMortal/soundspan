// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liked_tracks_pagination.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LikedTracksPagination _$LikedTracksPaginationFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['hasMore', 'limit', 'nextCursor'],
    disallowNullValues: const ['hasMore', 'limit', 'nextCursor'],
  );
  return LikedTracksPagination(
    hasMore: json['hasMore'] as bool,
    limit: LikedTracksPagination._read_limit(json['limit']),
    nextCursor: LikedTracksCursor.fromJson(
      json['nextCursor'] as Map<String, dynamic>,
    ),
    additionalProperties:
        LikedTracksPagination._extras(json, 'additionalProperties') == null
        ? const {}
        : LikedTracksPagination._readExtras(
            LikedTracksPagination._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$LikedTracksPaginationToJson(
  LikedTracksPagination instance,
) => <String, dynamic>{
  'hasMore': instance.hasMore,
  'limit': ?LikedTracksPagination._write_limit(instance.limit),
  'nextCursor': instance.nextCursor.toJson(),
};
