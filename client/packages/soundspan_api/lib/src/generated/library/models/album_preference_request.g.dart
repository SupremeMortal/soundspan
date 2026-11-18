// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album_preference_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlbumPreferenceRequest _$AlbumPreferenceRequestFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['signal'],
    disallowNullValues: const ['signal'],
  );
  return AlbumPreferenceRequest(
    signal: AlbumPreferenceRequest._read_signal(json['signal']),
    additionalProperties:
        AlbumPreferenceRequest._extras(json, 'additionalProperties') == null
        ? const {}
        : AlbumPreferenceRequest._readExtras(
            AlbumPreferenceRequest._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$AlbumPreferenceRequestToJson(
  AlbumPreferenceRequest instance,
) => <String, dynamic>{
  'signal': ?AlbumPreferenceRequest._write_signal(instance.signal),
};
