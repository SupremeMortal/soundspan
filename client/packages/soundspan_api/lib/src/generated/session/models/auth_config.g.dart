// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthConfig _$AuthConfigFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'localLoginEnabled',
      'oidcEnabled',
      'oidcProviderName',
    ],
    disallowNullValues: const [
      'localLoginEnabled',
      'oidcEnabled',
      'oidcProviderName',
    ],
  );
  return AuthConfig(
    localLoginEnabled: json['localLoginEnabled'] as bool,
    oidcEnabled: json['oidcEnabled'] as bool,
    oidcProviderName: json['oidcProviderName'] as String,
    additionalProperties:
        AuthConfig._extras(json, 'additionalProperties') == null
        ? const {}
        : AuthConfig._readExtras(
            AuthConfig._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$AuthConfigToJson(AuthConfig instance) =>
    <String, dynamic>{
      'localLoginEnabled': instance.localLoginEnabled,
      'oidcEnabled': instance.oidcEnabled,
      'oidcProviderName': instance.oidcProviderName,
    };
