// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlaylistSummary _$PlaylistSummaryFromJson(Map<String, dynamic> json) =>
    _PlaylistSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      trackCount: (json['trackCount'] as num).toInt(),
      isOwner: json['isOwner'] as bool,
      isPublic: json['isPublic'] as bool,
      coverRefs:
          (json['coverRefs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$PlaylistSummaryToJson(_PlaylistSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'trackCount': instance.trackCount,
      'isOwner': instance.isOwner,
      'isPublic': instance.isPublic,
      'coverRefs': instance.coverRefs,
    };

_PlaylistItem _$PlaylistItemFromJson(Map<String, dynamic> json) =>
    _PlaylistItem(
      id: json['id'] as String,
      sort: (json['sort'] as num).toInt(),
      track: Track.fromJson(json['track'] as Map<String, dynamic>),
      isPlayable: json['isPlayable'] as bool,
      message: json['message'] as String?,
      pendingOpUuid: json['pendingOpUuid'] as String?,
    );

Map<String, dynamic> _$PlaylistItemToJson(_PlaylistItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sort': instance.sort,
      'track': instance.track,
      'isPlayable': instance.isPlayable,
      'message': instance.message,
      'pendingOpUuid': instance.pendingOpUuid,
    };

_PlaylistDetail _$PlaylistDetailFromJson(Map<String, dynamic> json) =>
    _PlaylistDetail(
      summary: PlaylistSummary.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      items: (json['items'] as List<dynamic>)
          .map((e) => PlaylistItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlaylistDetailToJson(_PlaylistDetail instance) =>
    <String, dynamic>{'summary': instance.summary, 'items': instance.items};
