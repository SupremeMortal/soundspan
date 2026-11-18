// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Artist _$ArtistFromJson(Map<String, dynamic> json) => _Artist(
  id: json['id'] as String,
  name: json['name'] as String,
  artworkRef: json['artworkRef'] as String?,
);

Map<String, dynamic> _$ArtistToJson(_Artist instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'artworkRef': instance.artworkRef,
};

_SimilarArtist _$SimilarArtistFromJson(Map<String, dynamic> json) =>
    _SimilarArtist(
      name: json['name'] as String,
      artworkRef: json['artworkRef'] as String?,
      libraryId: json['libraryId'] as String?,
    );

Map<String, dynamic> _$SimilarArtistToJson(_SimilarArtist instance) =>
    <String, dynamic>{
      'name': instance.name,
      'artworkRef': instance.artworkRef,
      'libraryId': instance.libraryId,
    };

_ArtistDetail _$ArtistDetailFromJson(Map<String, dynamic> json) =>
    _ArtistDetail(
      artist: Artist.fromJson(json['artist'] as Map<String, dynamic>),
      albums:
          (json['albums'] as List<dynamic>?)
              ?.map((e) => Album.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Album>[],
      topTracks:
          (json['topTracks'] as List<dynamic>?)
              ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Track>[],
      similarArtists:
          (json['similarArtists'] as List<dynamic>?)
              ?.map((e) => SimilarArtist.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <SimilarArtist>[],
      biography: json['biography'] as String?,
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$ArtistDetailToJson(_ArtistDetail instance) =>
    <String, dynamic>{
      'artist': instance.artist,
      'albums': instance.albums,
      'topTracks': instance.topTracks,
      'similarArtists': instance.similarArtists,
      'biography': instance.biography,
      'genres': instance.genres,
    };
