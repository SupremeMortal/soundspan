// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_results.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackHit _$TrackHitFromJson(Map<String, dynamic> json) => TrackHit(
  track: Track.fromJson(json['track'] as Map<String, dynamic>),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$TrackHitToJson(TrackHit instance) => <String, dynamic>{
  'track': instance.track,
  'kind': instance.$type,
};

AlbumHit _$AlbumHitFromJson(Map<String, dynamic> json) => AlbumHit(
  album: Album.fromJson(json['album'] as Map<String, dynamic>),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$AlbumHitToJson(AlbumHit instance) => <String, dynamic>{
  'album': instance.album,
  'kind': instance.$type,
};

ArtistHit _$ArtistHitFromJson(Map<String, dynamic> json) => ArtistHit(
  artist: Artist.fromJson(json['artist'] as Map<String, dynamic>),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$ArtistHitToJson(ArtistHit instance) => <String, dynamic>{
  'artist': instance.artist,
  'kind': instance.$type,
};

PlaylistHit _$PlaylistHitFromJson(Map<String, dynamic> json) => PlaylistHit(
  playlist: PlaylistSummary.fromJson(json['playlist'] as Map<String, dynamic>),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PlaylistHitToJson(PlaylistHit instance) =>
    <String, dynamic>{'playlist': instance.playlist, 'kind': instance.$type};

PodcastHit _$PodcastHitFromJson(Map<String, dynamic> json) => PodcastHit(
  podcast: PodcastSummary.fromJson(json['podcast'] as Map<String, dynamic>),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PodcastHitToJson(PodcastHit instance) =>
    <String, dynamic>{'podcast': instance.podcast, 'kind': instance.$type};

_SearchResult _$SearchResultFromJson(Map<String, dynamic> json) =>
    _SearchResult(
      hit: SearchHit.fromJson(json['hit'] as Map<String, dynamic>),
      score: (json['score'] as num?)?.toDouble() ?? 0,
      source:
          $enumDecodeNullable(_$SearchResultSourceEnumMap, json['source']) ??
          SearchResultSource.library,
    );

Map<String, dynamic> _$SearchResultToJson(_SearchResult instance) =>
    <String, dynamic>{
      'hit': instance.hit,
      'score': instance.score,
      'source': _$SearchResultSourceEnumMap[instance.source]!,
    };

const _$SearchResultSourceEnumMap = {
  SearchResultSource.library: 'library',
  SearchResultSource.catalogue: 'catalogue',
};

_SearchPage _$SearchPageFromJson(Map<String, dynamic> json) => _SearchPage(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SearchResult>[],
  hasMore: json['hasMore'] as bool? ?? false,
);

Map<String, dynamic> _$SearchPageToJson(_SearchPage instance) =>
    <String, dynamic>{'items': instance.items, 'hasMore': instance.hasMore};
