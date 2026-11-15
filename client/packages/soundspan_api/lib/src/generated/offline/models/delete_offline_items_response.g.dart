// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_offline_items_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteOfflineItemsResponse _$DeleteOfflineItemsResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['deletedCount'],
    disallowNullValues: const ['deletedCount'],
  );
  return DeleteOfflineItemsResponse(
    deletedCount: DeleteOfflineItemsResponse._read_deletedCount(
      json['deletedCount'],
    ),
    additionalProperties:
        DeleteOfflineItemsResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : DeleteOfflineItemsResponse._readExtras(
            DeleteOfflineItemsResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$DeleteOfflineItemsResponseToJson(
  DeleteOfflineItemsResponse instance,
) => <String, dynamic>{
  'deletedCount': ?DeleteOfflineItemsResponse._write_deletedCount(
    instance.deletedCount,
  ),
};
