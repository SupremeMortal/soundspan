// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthStatus _$HealthStatusFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'draining',
      'role',
      'startupComplete',
      'status',
      'uptimeSeconds',
      'version',
    ],
    disallowNullValues: const [
      'draining',
      'role',
      'startupComplete',
      'status',
      'uptimeSeconds',
      'version',
    ],
  );
  return HealthStatus(
    draining: json['draining'] as bool,
    role: HealthStatus._read_role(json['role']),
    startupComplete: json['startupComplete'] as bool,
    status: json['status'] as String,
    uptimeSeconds: HealthStatus._read_uptimeSeconds(json['uptimeSeconds']),
    version: json['version'] as String,
    additionalProperties:
        HealthStatus._extras(json, 'additionalProperties') == null
        ? const {}
        : HealthStatus._readExtras(
            HealthStatus._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$HealthStatusToJson(
  HealthStatus instance,
) => <String, dynamic>{
  'draining': instance.draining,
  'role': ?HealthStatus._write_role(instance.role),
  'startupComplete': instance.startupComplete,
  'status': instance.status,
  'uptimeSeconds': ?HealthStatus._write_uptimeSeconds(instance.uptimeSeconds),
  'version': instance.version,
};
