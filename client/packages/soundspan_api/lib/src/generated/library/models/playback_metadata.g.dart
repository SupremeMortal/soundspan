// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaybackMetadata _$PlaybackMetadataFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['album', 'artist', 'durationSec', 'title'],
    disallowNullValues: const [
      'album',
      'artist',
      'artworkUrl',
      'durationSec',
      'isrc',
      'title',
    ],
  );
  return PlaybackMetadata(
    album: json['album'] as String,
    artist: json['artist'] as String,
    artworkUrl: json['artworkUrl'] as String?,
    durationSec: PlaybackMetadata._read_durationSec(json['durationSec']),
    isrc: json['isrc'] as String?,
    title: json['title'] as String,
    additionalProperties:
        PlaybackMetadata._extras(json, 'additionalProperties') == null
        ? const {}
        : PlaybackMetadata._readExtras(
            PlaybackMetadata._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$PlaybackMetadataToJson(PlaybackMetadata instance) =>
    <String, dynamic>{
      'album': instance.album,
      'artist': instance.artist,
      'artworkUrl': ?instance.artworkUrl,
      'durationSec': ?PlaybackMetadata._write_durationSec(instance.durationSec),
      'isrc': ?instance.isrc,
      'title': instance.title,
    };
