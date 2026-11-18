// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'online_users_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OnlineUsersResponse _$OnlineUsersResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['users'],
    disallowNullValues: const ['users'],
  );
  return OnlineUsersResponse(
    users: (json['users'] as List<dynamic>)
        .map((e) => OnlineUser.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        OnlineUsersResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : OnlineUsersResponse._readExtras(
            OnlineUsersResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$OnlineUsersResponseToJson(
  OnlineUsersResponse instance,
) => <String, dynamic>{'users': instance.users.map((e) => e.toJson()).toList()};
