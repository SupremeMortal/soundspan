// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discover_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscoverTrack _$DiscoverTrackFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'album',
      'albumId',
      'artist',
      'available',
      'coverUrl',
      'duration',
      'id',
      'isLiked',
      'likedAt',
      'similarity',
      'sourceType',
      'tier',
      'title',
    ],
    disallowNullValues: const [
      'album',
      'albumId',
      'artist',
      'available',
      'duration',
      'id',
      'isLiked',
      'playbackId',
      'similarity',
      'sourceType',
      'tier',
      'title',
    ],
  );
  return DiscoverTrack(
    album: json['album'] as String,
    albumId: json['albumId'] as String,
    albumLoudnessLufs: json['albumLoudnessLufs'] as num?,
    albumTruePeakDb: json['albumTruePeakDb'] as num?,
    artist: json['artist'] as String,
    available: json['available'] as bool,
    coverUrl: json['coverUrl'] as String?,
    duration: DiscoverTrack._read_duration(json['duration']),
    id: json['id'] as String,
    isLiked: json['isLiked'] as bool,
    likedAt: DiscoverTrack._read_likedAt(json['likedAt']),
    loudnessLufs: json['loudnessLufs'] as num?,
    playbackId: json['playbackId'] as String?,
    similarity: json['similarity'] as num,
    sourceType: DiscoverTrack._read_sourceType(json['sourceType']),
    tier: DiscoverTrack._read_tier(json['tier']),
    title: json['title'] as String,
    truePeakDb: json['truePeakDb'] as num?,
    additionalProperties:
        DiscoverTrack._extras(json, 'additionalProperties') == null
        ? const {}
        : DiscoverTrack._readExtras(
            DiscoverTrack._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$DiscoverTrackToJson(DiscoverTrack instance) =>
    <String, dynamic>{
      'album': instance.album,
      'albumId': instance.albumId,
      'albumLoudnessLufs': ?instance.albumLoudnessLufs,
      'albumTruePeakDb': ?instance.albumTruePeakDb,
      'artist': instance.artist,
      'available': instance.available,
      'coverUrl': instance.coverUrl,
      'duration': ?DiscoverTrack._write_duration(instance.duration),
      'id': instance.id,
      'isLiked': instance.isLiked,
      'likedAt': DiscoverTrack._write_likedAt(instance.likedAt),
      'loudnessLufs': ?instance.loudnessLufs,
      'playbackId': ?instance.playbackId,
      'similarity': instance.similarity,
      'sourceType': ?DiscoverTrack._write_sourceType(instance.sourceType),
      'tier': ?DiscoverTrack._write_tier(instance.tier),
      'title': instance.title,
      'truePeakDb': ?instance.truePeakDb,
    };
