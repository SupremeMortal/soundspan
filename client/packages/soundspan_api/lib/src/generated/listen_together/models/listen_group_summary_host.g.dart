// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listen_group_summary_host.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListenGroupSummaryHost _$ListenGroupSummaryHostFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'username'],
    disallowNullValues: const ['id', 'username'],
  );
  return ListenGroupSummaryHost(
    id: json['id'] as String,
    username: json['username'] as String,
    additionalProperties:
        ListenGroupSummaryHost._extras(json, 'additionalProperties') == null
        ? const {}
        : ListenGroupSummaryHost._readExtras(
            ListenGroupSummaryHost._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ListenGroupSummaryHostToJson(
  ListenGroupSummaryHost instance,
) => <String, dynamic>{'id': instance.id, 'username': instance.username};
