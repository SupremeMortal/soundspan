// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_owner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaylistOwner _$PlaylistOwnerFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['username'],
    disallowNullValues: const ['username'],
  );
  return PlaylistOwner(
    username: json['username'] as String,
    additionalProperties:
        PlaylistOwner._extras(json, 'additionalProperties') == null
        ? const {}
        : PlaylistOwner._readExtras(
            PlaylistOwner._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PlaylistOwnerToJson(PlaylistOwner instance) =>
    <String, dynamic>{'username': instance.username};
