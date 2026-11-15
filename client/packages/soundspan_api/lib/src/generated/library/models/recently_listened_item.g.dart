// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recently_listened_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecentlyListenedItem _$RecentlyListenedItemFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['coverArt', 'id', 'lastPlayedAt', 'name', 'type'],
    disallowNullValues: const [
      'albumCount',
      'episodeId',
      'id',
      'lastPlayedAt',
      'name',
      'progress',
      'type',
    ],
  );
  return RecentlyListenedItem(
    albumCount: RecentlyListenedItem._read_albumCount(json['albumCount']),
    author: json['author'] as String?,
    coverArt: json['coverArt'] as String?,
    episodeId: json['episodeId'] as String?,
    id: json['id'] as String,
    lastPlayedAt: RecentlyListenedItem._read_lastPlayedAt(json['lastPlayedAt']),
    mbid: json['mbid'] as String?,
    name: json['name'] as String,
    progress: RecentlyListenedItem._read_progress(json['progress']),
    type: RecentlyListenedItem._read_type(json['type']),
    additionalProperties:
        RecentlyListenedItem._extras(json, 'additionalProperties') == null
        ? const {}
        : RecentlyListenedItem._readExtras(
            RecentlyListenedItem._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$RecentlyListenedItemToJson(
  RecentlyListenedItem instance,
) => <String, dynamic>{
  'albumCount': ?RecentlyListenedItem._write_albumCount(instance.albumCount),
  'author': ?instance.author,
  'coverArt': instance.coverArt,
  'episodeId': ?instance.episodeId,
  'id': instance.id,
  'lastPlayedAt': ?RecentlyListenedItem._write_lastPlayedAt(
    instance.lastPlayedAt,
  ),
  'mbid': ?instance.mbid,
  'name': instance.name,
  'progress': ?RecentlyListenedItem._write_progress(instance.progress),
  'type': ?RecentlyListenedItem._write_type(instance.type),
};
