// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_limit_exceeded_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CacheLimitExceededError _$CacheLimitExceededErrorFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const [
      'cacheLimitBytes',
      'cacheUsedBytes',
      'error',
      'estimatedTotalBytes',
    ],
    disallowNullValues: const [
      'cacheLimitBytes',
      'cacheUsedBytes',
      'code',
      'error',
      'estimatedTotalBytes',
    ],
  );
  return CacheLimitExceededError(
    cacheLimitBytes: CacheLimitExceededError._read_cacheLimitBytes(
      json['cacheLimitBytes'],
    ),
    cacheUsedBytes: CacheLimitExceededError._read_cacheUsedBytes(
      json['cacheUsedBytes'],
    ),
    code: json['code'] as String?,
    error: json['error'] as String,
    estimatedTotalBytes: CacheLimitExceededError._read_estimatedTotalBytes(
      json['estimatedTotalBytes'],
    ),
    additionalProperties:
        CacheLimitExceededError._extras(json, 'additionalProperties') == null
        ? const {}
        : CacheLimitExceededError._readExtras(
            CacheLimitExceededError._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$CacheLimitExceededErrorToJson(
  CacheLimitExceededError instance,
) => <String, dynamic>{
  'cacheLimitBytes': ?CacheLimitExceededError._write_cacheLimitBytes(
    instance.cacheLimitBytes,
  ),
  'cacheUsedBytes': ?CacheLimitExceededError._write_cacheUsedBytes(
    instance.cacheUsedBytes,
  ),
  'code': ?instance.code,
  'error': instance.error,
  'estimatedTotalBytes': ?CacheLimitExceededError._write_estimatedTotalBytes(
    instance.estimatedTotalBytes,
  ),
};
