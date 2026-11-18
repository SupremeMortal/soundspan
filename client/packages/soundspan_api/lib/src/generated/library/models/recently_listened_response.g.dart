// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recently_listened_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecentlyListenedResponse _$RecentlyListenedResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['items'],
    disallowNullValues: const ['items'],
  );
  return RecentlyListenedResponse(
    items: (json['items'] as List<dynamic>)
        .map((e) => RecentlyListenedItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        RecentlyListenedResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : RecentlyListenedResponse._readExtras(
            RecentlyListenedResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$RecentlyListenedResponseToJson(
  RecentlyListenedResponse instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
