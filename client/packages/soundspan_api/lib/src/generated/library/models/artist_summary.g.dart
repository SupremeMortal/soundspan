// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtistSummary _$ArtistSummaryFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'albumCount',
      'coverArt',
      'id',
      'mbid',
      'name',
      'trackCount',
    ],
    disallowNullValues: const [
      'albumCount',
      'id',
      'name',
      'peer',
      'remoteSources',
      'source',
      'trackCount',
    ],
  );
  return ArtistSummary(
    albumCount: ArtistSummary._read_albumCount(json['albumCount']),
    coverArt: json['coverArt'] as String?,
    id: json['id'] as String,
    mbid: json['mbid'] as String?,
    name: json['name'] as String,
    peer: json['peer'] == null
        ? null
        : PeerRef.fromJson(json['peer'] as Map<String, dynamic>),
    remoteSources: ArtistSummary._read_remoteSources(json['remoteSources']),
    source: ArtistSummary._read_source(json['source']),
    trackCount: ArtistSummary._read_trackCount(json['trackCount']),
    additionalProperties:
        ArtistSummary._extras(json, 'additionalProperties') == null
        ? const {}
        : ArtistSummary._readExtras(
            ArtistSummary._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ArtistSummaryToJson(
  ArtistSummary instance,
) => <String, dynamic>{
  'albumCount': ?ArtistSummary._write_albumCount(instance.albumCount),
  'coverArt': instance.coverArt,
  'id': instance.id,
  'mbid': instance.mbid,
  'name': instance.name,
  'peer': ?instance.peer?.toJson(),
  'remoteSources': ?ArtistSummary._write_remoteSources(instance.remoteSources),
  'source': ?ArtistSummary._write_source(instance.source),
  'trackCount': ?ArtistSummary._write_trackCount(instance.trackCount),
};
