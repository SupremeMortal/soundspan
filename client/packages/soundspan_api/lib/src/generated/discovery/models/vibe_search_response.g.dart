// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vibe_search_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VibeSearchResponse _$VibeSearchResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'minSimilarity',
      'query',
      'totalAboveThreshold',
      'tracks',
    ],
    disallowNullValues: const [
      'minSimilarity',
      'query',
      'totalAboveThreshold',
      'tracks',
    ],
  );
  return VibeSearchResponse(
    minSimilarity: json['minSimilarity'] as num,
    query: json['query'] as String,
    totalAboveThreshold: VibeSearchResponse._read_totalAboveThreshold(
      json['totalAboveThreshold'],
    ),
    tracks: (json['tracks'] as List<dynamic>)
        .map((e) => VibeSearchTrack.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        VibeSearchResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : VibeSearchResponse._readExtras(
            VibeSearchResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$VibeSearchResponseToJson(VibeSearchResponse instance) =>
    <String, dynamic>{
      'minSimilarity': instance.minSimilarity,
      'query': instance.query,
      'totalAboveThreshold': ?VibeSearchResponse._write_totalAboveThreshold(
        instance.totalAboveThreshold,
      ),
      'tracks': instance.tracks.map((e) => e.toJson()).toList(),
    };
