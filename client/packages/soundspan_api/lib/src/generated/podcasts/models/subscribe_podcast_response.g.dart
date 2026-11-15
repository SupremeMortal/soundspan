// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscribe_podcast_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscribePodcastResponse _$SubscribePodcastResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['message', 'podcast', 'success'],
    disallowNullValues: const ['message', 'podcast', 'success'],
  );
  return SubscribePodcastResponse(
    message: json['message'] as String,
    podcast: SubscribedPodcastRef.fromJson(
      json['podcast'] as Map<String, dynamic>,
    ),
    success: json['success'] as bool,
    additionalProperties:
        SubscribePodcastResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : SubscribePodcastResponse._readExtras(
            SubscribePodcastResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SubscribePodcastResponseToJson(
  SubscribePodcastResponse instance,
) => <String, dynamic>{
  'message': instance.message,
  'podcast': instance.podcast.toJson(),
  'success': instance.success,
};
