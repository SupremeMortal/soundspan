// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refresh_session_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefreshSessionRequest _$RefreshSessionRequestFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['refreshToken'],
    disallowNullValues: const ['refreshToken'],
  );
  return RefreshSessionRequest(
    refreshToken: json['refreshToken'] as String,
    additionalProperties:
        RefreshSessionRequest._extras(json, 'additionalProperties') == null
        ? const {}
        : RefreshSessionRequest._readExtras(
            RefreshSessionRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$RefreshSessionRequestToJson(
  RefreshSessionRequest instance,
) => <String, dynamic>{'refreshToken': instance.refreshToken};
