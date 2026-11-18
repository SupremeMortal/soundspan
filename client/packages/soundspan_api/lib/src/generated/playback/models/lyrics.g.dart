// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Lyrics _$LyricsFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['plainLyrics', 'source', 'synced', 'syncedLyrics'],
    disallowNullValues: const ['source', 'synced'],
  );
  return Lyrics(
    plainLyrics: json['plainLyrics'] as String?,
    source: Lyrics._read_source(json['source']),
    synced: json['synced'] as bool,
    syncedLyrics: json['syncedLyrics'] as String?,
    additionalProperties: Lyrics._extras(json, 'additionalProperties') == null
        ? const {}
        : Lyrics._readExtras(Lyrics._extras(json, 'additionalProperties')),
  );
}

Map<String, dynamic> _$LyricsToJson(Lyrics instance) => <String, dynamic>{
  'plainLyrics': instance.plainLyrics,
  'source': ?Lyrics._write_source(instance.source),
  'synced': instance.synced,
  'syncedLyrics': instance.syncedLyrics,
};
