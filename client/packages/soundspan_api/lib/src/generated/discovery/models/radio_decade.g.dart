// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radio_decade.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadioDecade _$RadioDecadeFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['count', 'decade'],
    disallowNullValues: const ['count', 'decade'],
  );
  return RadioDecade(
    count: RadioDecade._read_count(json['count']),
    decade: RadioDecade._read_decade(json['decade']),
    additionalProperties:
        RadioDecade._extras(json, 'additionalProperties') == null
        ? const {}
        : RadioDecade._readExtras(
            RadioDecade._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$RadioDecadeToJson(RadioDecade instance) =>
    <String, dynamic>{
      'count': ?RadioDecade._write_count(instance.count),
      'decade': ?RadioDecade._write_decade(instance.decade),
    };
