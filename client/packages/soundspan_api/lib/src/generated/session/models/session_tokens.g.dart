// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_tokens.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionTokens _$SessionTokensFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['refreshToken', 'token'],
    disallowNullValues: const ['refreshToken', 'token'],
  );
  return SessionTokens(
    refreshToken: json['refreshToken'] as String,
    token: json['token'] as String,
    additionalProperties:
        SessionTokens._extras(json, 'additionalProperties') == null
        ? const {}
        : SessionTokens._readExtras(
            SessionTokens._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$SessionTokensToJson(SessionTokens instance) =>
    <String, dynamic>{
      'refreshToken': instance.refreshToken,
      'token': instance.token,
    };
