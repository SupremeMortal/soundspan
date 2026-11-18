// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recently_added_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecentlyAddedResponse _$RecentlyAddedResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['artists'],
    disallowNullValues: const ['artists'],
  );
  return RecentlyAddedResponse(
    artists: (json['artists'] as List<dynamic>)
        .map((e) => RecentlyAddedArtist.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        RecentlyAddedResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : RecentlyAddedResponse._readExtras(
            RecentlyAddedResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$RecentlyAddedResponseToJson(
  RecentlyAddedResponse instance,
) => <String, dynamic>{
  'artists': instance.artists.map((e) => e.toJson()).toList(),
};
