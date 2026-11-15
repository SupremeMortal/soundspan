// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'peer_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeerRef _$PeerRefFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'name', 'online'],
    disallowNullValues: const ['id', 'name', 'online'],
  );
  return PeerRef(
    id: json['id'] as String,
    name: json['name'] as String,
    online: json['online'] as bool,
    additionalProperties: PeerRef._extras(json, 'additionalProperties') == null
        ? const {}
        : PeerRef._readExtras(PeerRef._extras(json, 'additionalProperties')),
  );
}

Map<String, dynamic> _$PeerRefToJson(PeerRef instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'online': instance.online,
};
