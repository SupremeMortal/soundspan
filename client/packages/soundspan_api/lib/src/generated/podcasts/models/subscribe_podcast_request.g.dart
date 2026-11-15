// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscribe_podcast_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscribePodcastRequest _$SubscribePodcastRequestFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(json, disallowNullValues: const ['feedUrl', 'itunesId']);
  return SubscribePodcastRequest(
    feedUrl: json['feedUrl'] as String?,
    itunesId: json['itunesId'] as String?,
    additionalProperties:
        SubscribePodcastRequest._extras(json, 'additionalProperties') == null
        ? const {}
        : SubscribePodcastRequest._readExtras(
            SubscribePodcastRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SubscribePodcastRequestToJson(
  SubscribePodcastRequest instance,
) => <String, dynamic>{
  'feedUrl': ?instance.feedUrl,
  'itunesId': ?instance.itunesId,
};
