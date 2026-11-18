// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shuffled_tracks_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShuffledTracksResponse _$ShuffledTracksResponseFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['total', 'tracks'],
    disallowNullValues: const ['total', 'tracks'],
  );
  return ShuffledTracksResponse(
    total: ShuffledTracksResponse._read_total(json['total']),
    tracks: (json['tracks'] as List<dynamic>)
        .map((e) => TrackSummary.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        ShuffledTracksResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : ShuffledTracksResponse._readExtras(
            ShuffledTracksResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ShuffledTracksResponseToJson(
  ShuffledTracksResponse instance,
) => <String, dynamic>{
  'total': ?ShuffledTracksResponse._write_total(instance.total),
  'tracks': instance.tracks.map((e) => e.toJson()).toList(),
};
