// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginUser _$LoginUserFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['displayName', 'id', 'role', 'username'],
    disallowNullValues: const ['id', 'role', 'username'],
  );
  return LoginUser(
    displayName: json['displayName'] as String?,
    id: json['id'] as String,
    role: LoginUser._read_role(json['role']),
    username: json['username'] as String,
    additionalProperties:
        LoginUser._extras(json, 'additionalProperties') == null
        ? const {}
        : LoginUser._readExtras(
            LoginUser._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$LoginUserToJson(LoginUser instance) => <String, dynamic>{
  'displayName': instance.displayName,
  'id': instance.id,
  'role': ?LoginUser._write_role(instance.role),
  'username': instance.username,
};
