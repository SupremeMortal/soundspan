// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageResponse _$MessageResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['message'],
    disallowNullValues: const ['message'],
  );
  return MessageResponse(
    message: json['message'] as String,
    additionalProperties:
        MessageResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : MessageResponse._readExtras(
            MessageResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$MessageResponseToJson(MessageResponse instance) =>
    <String, dynamic>{'message': instance.message};
