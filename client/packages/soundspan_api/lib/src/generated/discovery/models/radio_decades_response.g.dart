// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radio_decades_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RadioDecadesResponse _$RadioDecadesResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['decades'],
    disallowNullValues: const ['decades'],
  );
  return RadioDecadesResponse(
    decades: (json['decades'] as List<dynamic>)
        .map((e) => RadioDecade.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        RadioDecadesResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : RadioDecadesResponse._readExtras(
            RadioDecadesResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$RadioDecadesResponseToJson(
  RadioDecadesResponse instance,
) => <String, dynamic>{
  'decades': instance.decades.map((e) => e.toJson()).toList(),
};
