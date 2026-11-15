// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discover_alias_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscoverAliasInfo _$DiscoverAliasInfoFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['canonical', 'original'],
    disallowNullValues: const ['canonical', 'mbid', 'original'],
  );
  return DiscoverAliasInfo(
    canonical: json['canonical'] as String,
    mbid: json['mbid'] as String?,
    original: json['original'] as String,
    additionalProperties:
        DiscoverAliasInfo._extras(json, 'additionalProperties') == null
        ? const {}
        : DiscoverAliasInfo._readExtras(
            DiscoverAliasInfo._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$DiscoverAliasInfoToJson(DiscoverAliasInfo instance) =>
    <String, dynamic>{
      'canonical': instance.canonical,
      'mbid': ?instance.mbid,
      'original': instance.original,
    };
