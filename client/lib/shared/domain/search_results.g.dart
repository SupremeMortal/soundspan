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

PodcastHit _$PodcastHitFromJson(Map<String, dynamic> json) => PodcastHit(
  podcast: PodcastSummary.fromJson(json['podcast'] as Map<String, dynamic>),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PodcastHitToJson(PodcastHit instance) =>
    <String, dynamic>{'podcast': instance.podcast, 'kind': instance.$type};

_LibrarySearchResults _$LibrarySearchResultsFromJson(
  Map<String, dynamic> json,
) => _LibrarySearchResults(
  artists:
      (json['artists'] as List<dynamic>?)
          ?.map((e) => Artist.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Artist>[],
  albums:
      (json['albums'] as List<dynamic>?)
          ?.map((e) => Album.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Album>[],
  tracks:
      (json['tracks'] as List<dynamic>?)
          ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Track>[],
  podcasts:
      (json['podcasts'] as List<dynamic>?)
          ?.map((e) => PodcastSummary.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PodcastSummary>[],
);

Map<String, dynamic> _$LibrarySearchResultsToJson(
  _LibrarySearchResults instance,
) => <String, dynamic>{
  'artists': instance.artists,
  'albums': instance.albums,
  'tracks': instance.tracks,
  'podcasts': instance.podcasts,
};

_AliasInfo _$AliasInfoFromJson(Map<String, dynamic> json) => _AliasInfo(
  original: json['original'] as String,
  canonical: json['canonical'] as String,
);

Map<String, dynamic> _$AliasInfoToJson(_AliasInfo instance) =>
    <String, dynamic>{
      'original': instance.original,
      'canonical': instance.canonical,
    };

_DiscoverResults _$DiscoverResultsFromJson(Map<String, dynamic> json) =>
    _DiscoverResults(
      hits:
          (json['hits'] as List<dynamic>?)
              ?.map((e) => SearchHit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <SearchHit>[],
      aliasInfo: json['aliasInfo'] == null
          ? null
          : AliasInfo.fromJson(json['aliasInfo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DiscoverResultsToJson(_DiscoverResults instance) =>
    <String, dynamic>{'hits': instance.hits, 'aliasInfo': instance.aliasInfo};

_SearchResults _$SearchResultsFromJson(Map<String, dynamic> json) =>
    _SearchResults(
      library: json['library'] == null
          ? null
          : LibrarySearchResults.fromJson(
              json['library'] as Map<String, dynamic>,
            ),
      discover: json['discover'] == null
          ? null
          : DiscoverResults.fromJson(json['discover'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SearchResultsToJson(_SearchResults instance) =>
    <String, dynamic>{
      'library': instance.library,
      'discover': instance.discover,
    };
