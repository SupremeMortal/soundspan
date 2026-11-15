// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album_preference_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlbumPreferenceResponse _$AlbumPreferenceResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const [
      'albumId',
      'dislikedAt',
      'likedAt',
      'score',
      'signal',
      'state',
      'trackCount',
      'updatedAt',
    ],
    disallowNullValues: const [
      'albumId',
      'score',
      'signal',
      'state',
      'trackCount',
    ],
  );
  return AlbumPreferenceResponse(
    albumId: json['albumId'] as String,
    dislikedAt: AlbumPreferenceResponse._read_dislikedAt(json['dislikedAt']),
    likedAt: AlbumPreferenceResponse._read_likedAt(json['likedAt']),
    score: AlbumPreferenceResponse._read_score(json['score']),
    signal: AlbumPreferenceResponse._read_signal(json['signal']),
    state: AlbumPreferenceResponse._read_state(json['state']),
    trackCount: AlbumPreferenceResponse._read_trackCount(json['trackCount']),
    updatedAt: AlbumPreferenceResponse._read_updatedAt(json['updatedAt']),
    additionalProperties:
        AlbumPreferenceResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : AlbumPreferenceResponse._readExtras(
            AlbumPreferenceResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$AlbumPreferenceResponseToJson(
  AlbumPreferenceResponse instance,
) => <String, dynamic>{
  'albumId': instance.albumId,
  'dislikedAt': AlbumPreferenceResponse._write_dislikedAt(instance.dislikedAt),
  'likedAt': AlbumPreferenceResponse._write_likedAt(instance.likedAt),
  'score': ?AlbumPreferenceResponse._write_score(instance.score),
  'signal': ?AlbumPreferenceResponse._write_signal(instance.signal),
  'state': ?AlbumPreferenceResponse._write_state(instance.state),
  'trackCount': ?AlbumPreferenceResponse._write_trackCount(instance.trackCount),
  'updatedAt': AlbumPreferenceResponse._write_updatedAt(instance.updatedAt),
};
