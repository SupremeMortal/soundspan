// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscribed_podcast_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscribedPodcastRef _$SubscribedPodcastRefFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'title'],
    disallowNullValues: const ['id', 'title'],
  );
  return SubscribedPodcastRef(
    id: json['id'] as String,
    title: json['title'] as String,
    additionalProperties:
        SubscribedPodcastRef._extras(json, 'additionalProperties') == null
        ? const {}
        : SubscribedPodcastRef._readExtras(
            SubscribedPodcastRef._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SubscribedPodcastRefToJson(
  SubscribedPodcastRef instance,
) => <String, dynamic>{'id': instance.id, 'title': instance.title};
