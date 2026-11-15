// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['password', 'username'],
    disallowNullValues: const ['password', 'token', 'username'],
  );
  return LoginRequest(
    password: json['password'] as String,
    token: json['token'] as String?,
    username: json['username'] as String,
    additionalProperties:
        LoginRequest._extras(json, 'additionalProperties') == null
        ? const {}
        : LoginRequest._readExtras(
            LoginRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'password': instance.password,
      'token': ?instance.token,
      'username': instance.username,
    };
