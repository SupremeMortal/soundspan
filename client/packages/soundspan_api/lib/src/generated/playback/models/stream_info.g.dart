// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stream_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StreamInfo _$StreamInfoFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'bitDepth',
      'bitrate',
      'codec',
      'contentLength',
      'contentType',
      'durationMs',
      'playbackId',
      'quality',
      'sampleRate',
    ],
    disallowNullValues: const ['playbackId', 'quality'],
  );
  return StreamInfo(
    bitDepth: json['bitDepth'] as num?,
    bitrate: json['bitrate'] as num?,
    codec: json['codec'] as String?,
    contentLength: StreamInfo._read_contentLength(json['contentLength']),
    contentType: json['contentType'] as String?,
    durationMs: StreamInfo._read_durationMs(json['durationMs']),
    playbackId: json['playbackId'] as String,
    quality: StreamInfo._read_quality(json['quality']),
    sampleRate: json['sampleRate'] as num?,
    additionalProperties:
        StreamInfo._extras(json, 'additionalProperties') == null
        ? const {}
        : StreamInfo._readExtras(
            StreamInfo._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$StreamInfoToJson(StreamInfo instance) =>
    <String, dynamic>{
      'bitDepth': instance.bitDepth,
      'bitrate': instance.bitrate,
      'codec': instance.codec,
      'contentLength': StreamInfo._write_contentLength(instance.contentLength),
      'contentType': instance.contentType,
      'durationMs': StreamInfo._write_durationMs(instance.durationMs),
      'playbackId': instance.playbackId,
      'quality': ?StreamInfo._write_quality(instance.quality),
      'sampleRate': instance.sampleRate,
    };
