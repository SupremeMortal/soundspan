// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistDetail _$PlaylistDetailFromJson(Map<String, dynamic> json) {
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
      'pendingCount',
      'totalItemCount',
      'trackCount',
      'truncated',
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
      'pendingCount',
      'totalItemCount',
      'trackCount',
      'truncated',
      'unplayableCount',
      'updatedAt',
      'user',
      'userId',
    ],
  );
  return PlaylistDetail(
    createdAt: PlaylistDetail._read_createdAt(json['createdAt']),
    id: json['id'] as String,
    isHidden: json['isHidden'] as bool,
    isOwner: json['isOwner'] as bool,
    isPublic: json['isPublic'] as bool,
    items: (json['items'] as List<dynamic>)
        .map((e) => PlaylistItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    name: json['name'] as String,
    pendingCount: PlaylistDetail._read_pendingCount(json['pendingCount']),
    totalItemCount: PlaylistDetail._read_totalItemCount(json['totalItemCount']),
    trackCount: PlaylistDetail._read_trackCount(json['trackCount']),
    truncated: json['truncated'] as bool,
    unplayableCount: PlaylistDetail._read_unplayableCount(
      json['unplayableCount'],
    ),
    updatedAt: PlaylistDetail._read_updatedAt(json['updatedAt']),
    user: PlaylistOwner.fromJson(json['user'] as Map<String, dynamic>),
    userId: json['userId'] as String,
    additionalProperties:
        PlaylistDetail._extras(json, 'additionalProperties') == null
        ? const {}
        : PlaylistDetail._readExtras(
            PlaylistDetail._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PlaylistDetailToJson(
  PlaylistDetail instance,
) => <String, dynamic>{
  'createdAt': ?PlaylistDetail._write_createdAt(instance.createdAt),
  'id': instance.id,
  'isHidden': instance.isHidden,
  'isOwner': instance.isOwner,
  'isPublic': instance.isPublic,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'name': instance.name,
  'pendingCount': ?PlaylistDetail._write_pendingCount(instance.pendingCount),
  'totalItemCount': ?PlaylistDetail._write_totalItemCount(
    instance.totalItemCount,
  ),
  'trackCount': ?PlaylistDetail._write_trackCount(instance.trackCount),
  'truncated': instance.truncated,
  'unplayableCount': ?PlaylistDetail._write_unplayableCount(
    instance.unplayableCount,
  ),
  'updatedAt': ?PlaylistDetail._write_updatedAt(instance.updatedAt),
  'user': instance.user.toJson(),
  'userId': instance.userId,
};
