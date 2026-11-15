// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unsubscribe_podcast_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnsubscribePodcastResponse _$UnsubscribePodcastResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['message', 'success'],
    disallowNullValues: const ['message', 'success'],
  );
  return UnsubscribePodcastResponse(
    message: json['message'] as String,
    success: json['success'] as bool,
    additionalProperties:
        UnsubscribePodcastResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : UnsubscribePodcastResponse._readExtras(
            UnsubscribePodcastResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$UnsubscribePodcastResponseToJson(
  UnsubscribePodcastResponse instance,
) => <String, dynamic>{
  'message': instance.message,
  'success': instance.success,
};
