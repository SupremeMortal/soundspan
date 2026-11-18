// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presence_heartbeat_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresenceHeartbeatResponse _$PresenceHeartbeatResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['success', 'ttlSeconds'],
    disallowNullValues: const ['success', 'ttlSeconds'],
  );
  return PresenceHeartbeatResponse(
    success: json['success'] as bool,
    ttlSeconds: PresenceHeartbeatResponse._read_ttlSeconds(json['ttlSeconds']),
    additionalProperties:
        PresenceHeartbeatResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : PresenceHeartbeatResponse._readExtras(
            PresenceHeartbeatResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PresenceHeartbeatResponseToJson(
  PresenceHeartbeatResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'ttlSeconds': ?PresenceHeartbeatResponse._write_ttlSeconds(
    instance.ttlSeconds,
  ),
};
