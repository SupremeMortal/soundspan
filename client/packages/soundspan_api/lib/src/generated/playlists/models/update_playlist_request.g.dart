// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_playlist_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdatePlaylistRequest _$UpdatePlaylistRequestFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(json, disallowNullValues: const ['isPublic', 'name']);
  return UpdatePlaylistRequest(
    isPublic: json['isPublic'] as bool?,
    name: json['name'] as String?,
    additionalProperties:
        UpdatePlaylistRequest._extras(json, 'additionalProperties') == null
        ? const {}
        : UpdatePlaylistRequest._readExtras(
            UpdatePlaylistRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$UpdatePlaylistRequestToJson(
  UpdatePlaylistRequest instance,
) => <String, dynamic>{'isPublic': ?instance.isPublic, 'name': ?instance.name};
