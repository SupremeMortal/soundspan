// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_playlist_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePlaylistRequest _$CreatePlaylistRequestFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['name'],
    disallowNullValues: const ['isPublic', 'name'],
  );
  return CreatePlaylistRequest(
    isPublic: CreatePlaylistRequest._presentValue(json, 'isPublic') == null
        ? false
        : CreatePlaylistRequest._read_isPublic(
            CreatePlaylistRequest._presentValue(json, 'isPublic') as Object,
          ),
    name: json['name'] as String,
    additionalProperties:
        CreatePlaylistRequest._extras(json, 'additionalProperties') == null
        ? const {}
        : CreatePlaylistRequest._readExtras(
            CreatePlaylistRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$CreatePlaylistRequestToJson(
  CreatePlaylistRequest instance,
) => <String, dynamic>{
  'isPublic': ?CreatePlaylistRequest._write_isPublic(instance.isPublic),
  'name': instance.name,
};
