// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistSummary _$PlaylistSummaryFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'createdAt',
      'id',
      'isHidden',
      'isOwner',
      'isPublic',
      'items',
      'name',
      'trackCount',
      'updatedAt',
      'user',
      'userId',
    ],
    disallowNullValues: const [
      'createdAt',
      'id',
      'isHidden',
      'isOwner',
      'isPublic',
      'items',
      'name',
      'trackCount',
      'unplayableCount',
      'updatedAt',
      'user',
      'userId',
    ],
  );
  return PlaylistSummary(
    createdAt: PlaylistSummary._read_createdAt(json['createdAt']),
    id: json['id'] as String,
    isHidden: json['isHidden'] as bool,
    isOwner: json['isOwner'] as bool,
    isPublic: json['isPublic'] as bool,
    items: (json['items'] as List<dynamic>)
        .map((e) => PlaylistCoverItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    name: json['name'] as String,
    trackCount: PlaylistSummary._read_trackCount(json['trackCount']),
    unplayableCount: PlaylistSummary._read_unplayableCount(
      json['unplayableCount'],
    ),
    updatedAt: PlaylistSummary._read_updatedAt(json['updatedAt']),
    user: PlaylistOwner.fromJson(json['user'] as Map<String, dynamic>),
    userId: json['userId'] as String,
    additionalProperties:
        PlaylistSummary._extras(json, 'additionalProperties') == null
        ? const {}
        : PlaylistSummary._readExtras(
            PlaylistSummary._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PlaylistSummaryToJson(PlaylistSummary instance) =>
    <String, dynamic>{
      'createdAt': ?PlaylistSummary._write_createdAt(instance.createdAt),
      'id': instance.id,
      'isHidden': instance.isHidden,
      'isOwner': instance.isOwner,
      'isPublic': instance.isPublic,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'name': instance.name,
      'trackCount': ?PlaylistSummary._write_trackCount(instance.trackCount),
      'unplayableCount': ?PlaylistSummary._write_unplayableCount(
        instance.unplayableCount,
      ),
      'updatedAt': ?PlaylistSummary._write_updatedAt(instance.updatedAt),
      'user': instance.user.toJson(),
      'userId': instance.userId,
    };
