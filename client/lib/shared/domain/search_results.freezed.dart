// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_results.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
SearchHit _$SearchHitFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'track':
          return TrackHit.fromJson(
            json
          );
                case 'album':
          return AlbumHit.fromJson(
            json
          );
                case 'artist':
          return ArtistHit.fromJson(
            json
          );
                case 'playlist':
          return PlaylistHit.fromJson(
            json
          );
                case 'podcast':
          return PodcastHit.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'kind',
  'SearchHit',
  'Invalid union type "${json['kind']}"!'
);
        }
      
}

/// @nodoc
mixin _$SearchHit {



  /// Serializes this SearchHit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchHit);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SearchHit()';
}


}

/// @nodoc
class $SearchHitCopyWith<$Res>  {
$SearchHitCopyWith(SearchHit _, $Res Function(SearchHit) __);
}


/// Adds pattern-matching-related methods to [SearchHit].
extension SearchHitPatterns on SearchHit {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TrackHit value)?  track,TResult Function( AlbumHit value)?  album,TResult Function( ArtistHit value)?  artist,TResult Function( PlaylistHit value)?  playlist,TResult Function( PodcastHit value)?  podcast,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TrackHit() when track != null:
return track(_that);case AlbumHit() when album != null:
return album(_that);case ArtistHit() when artist != null:
return artist(_that);case PlaylistHit() when playlist != null:
return playlist(_that);case PodcastHit() when podcast != null:
return podcast(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TrackHit value)  track,required TResult Function( AlbumHit value)  album,required TResult Function( ArtistHit value)  artist,required TResult Function( PlaylistHit value)  playlist,required TResult Function( PodcastHit value)  podcast,}){
final _that = this;
switch (_that) {
case TrackHit():
return track(_that);case AlbumHit():
return album(_that);case ArtistHit():
return artist(_that);case PlaylistHit():
return playlist(_that);case PodcastHit():
return podcast(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TrackHit value)?  track,TResult? Function( AlbumHit value)?  album,TResult? Function( ArtistHit value)?  artist,TResult? Function( PlaylistHit value)?  playlist,TResult? Function( PodcastHit value)?  podcast,}){
final _that = this;
switch (_that) {
case TrackHit() when track != null:
return track(_that);case AlbumHit() when album != null:
return album(_that);case ArtistHit() when artist != null:
return artist(_that);case PlaylistHit() when playlist != null:
return playlist(_that);case PodcastHit() when podcast != null:
return podcast(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Track track)?  track,TResult Function( Album album)?  album,TResult Function( Artist artist)?  artist,TResult Function( PlaylistSummary playlist)?  playlist,TResult Function( PodcastSummary podcast)?  podcast,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TrackHit() when track != null:
return track(_that.track);case AlbumHit() when album != null:
return album(_that.album);case ArtistHit() when artist != null:
return artist(_that.artist);case PlaylistHit() when playlist != null:
return playlist(_that.playlist);case PodcastHit() when podcast != null:
return podcast(_that.podcast);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Track track)  track,required TResult Function( Album album)  album,required TResult Function( Artist artist)  artist,required TResult Function( PlaylistSummary playlist)  playlist,required TResult Function( PodcastSummary podcast)  podcast,}) {final _that = this;
switch (_that) {
case TrackHit():
return track(_that.track);case AlbumHit():
return album(_that.album);case ArtistHit():
return artist(_that.artist);case PlaylistHit():
return playlist(_that.playlist);case PodcastHit():
return podcast(_that.podcast);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Track track)?  track,TResult? Function( Album album)?  album,TResult? Function( Artist artist)?  artist,TResult? Function( PlaylistSummary playlist)?  playlist,TResult? Function( PodcastSummary podcast)?  podcast,}) {final _that = this;
switch (_that) {
case TrackHit() when track != null:
return track(_that.track);case AlbumHit() when album != null:
return album(_that.album);case ArtistHit() when artist != null:
return artist(_that.artist);case PlaylistHit() when playlist != null:
return playlist(_that.playlist);case PodcastHit() when podcast != null:
return podcast(_that.podcast);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class TrackHit implements SearchHit {
  const TrackHit({required this.track,  String? $type}): $type = $type ?? 'track';
  factory TrackHit.fromJson(Map<String, dynamic> json) => _$TrackHitFromJson(json);

/// The track.
 final  Track track;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackHitCopyWith<TrackHit> get copyWith => _$TrackHitCopyWithImpl<TrackHit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackHitToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackHit&&(identical(other.track, track) || other.track == track));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,track);
}

@override
String toString() {
    return 'SearchHit.track(track: $track)';
}


}

/// @nodoc
abstract mixin class $TrackHitCopyWith<$Res> implements $SearchHitCopyWith<$Res> {
  factory $TrackHitCopyWith(TrackHit value, $Res Function(TrackHit) _then) = _$TrackHitCopyWithImpl;
@useResult
$Res call({
 Track track
});


$TrackCopyWith<$Res> get track;

}
/// @nodoc
class _$TrackHitCopyWithImpl<$Res>
    implements $TrackHitCopyWith<$Res> {
  _$TrackHitCopyWithImpl(this._self, this._then);

  final TrackHit _self;
  final $Res Function(TrackHit) _then;

/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? track = null,}) {
  return _then(TrackHit(
track: null == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as Track,
  ));
}

/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackCopyWith<$Res> get track {
  
  return $TrackCopyWith<$Res>(_self.track, (value) {
    return _then(_self.copyWith(track: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class AlbumHit implements SearchHit {
  const AlbumHit({required this.album,  String? $type}): $type = $type ?? 'album';
  factory AlbumHit.fromJson(Map<String, dynamic> json) => _$AlbumHitFromJson(json);

/// The album.
 final  Album album;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlbumHitCopyWith<AlbumHit> get copyWith => _$AlbumHitCopyWithImpl<AlbumHit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AlbumHitToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AlbumHit&&(identical(other.album, album) || other.album == album));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,album);
}

@override
String toString() {
    return 'SearchHit.album(album: $album)';
}


}

/// @nodoc
abstract mixin class $AlbumHitCopyWith<$Res> implements $SearchHitCopyWith<$Res> {
  factory $AlbumHitCopyWith(AlbumHit value, $Res Function(AlbumHit) _then) = _$AlbumHitCopyWithImpl;
@useResult
$Res call({
 Album album
});


$AlbumCopyWith<$Res> get album;

}
/// @nodoc
class _$AlbumHitCopyWithImpl<$Res>
    implements $AlbumHitCopyWith<$Res> {
  _$AlbumHitCopyWithImpl(this._self, this._then);

  final AlbumHit _self;
  final $Res Function(AlbumHit) _then;

/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? album = null,}) {
  return _then(AlbumHit(
album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as Album,
  ));
}

/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AlbumCopyWith<$Res> get album {
  
  return $AlbumCopyWith<$Res>(_self.album, (value) {
    return _then(_self.copyWith(album: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class ArtistHit implements SearchHit {
  const ArtistHit({required this.artist,  String? $type}): $type = $type ?? 'artist';
  factory ArtistHit.fromJson(Map<String, dynamic> json) => _$ArtistHitFromJson(json);

/// The artist.
 final  Artist artist;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistHitCopyWith<ArtistHit> get copyWith => _$ArtistHitCopyWithImpl<ArtistHit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistHitToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistHit&&(identical(other.artist, artist) || other.artist == artist));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,artist);
}

@override
String toString() {
    return 'SearchHit.artist(artist: $artist)';
}


}

/// @nodoc
abstract mixin class $ArtistHitCopyWith<$Res> implements $SearchHitCopyWith<$Res> {
  factory $ArtistHitCopyWith(ArtistHit value, $Res Function(ArtistHit) _then) = _$ArtistHitCopyWithImpl;
@useResult
$Res call({
 Artist artist
});


$ArtistCopyWith<$Res> get artist;

}
/// @nodoc
class _$ArtistHitCopyWithImpl<$Res>
    implements $ArtistHitCopyWith<$Res> {
  _$ArtistHitCopyWithImpl(this._self, this._then);

  final ArtistHit _self;
  final $Res Function(ArtistHit) _then;

/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? artist = null,}) {
  return _then(ArtistHit(
artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as Artist,
  ));
}

/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistCopyWith<$Res> get artist {
  
  return $ArtistCopyWith<$Res>(_self.artist, (value) {
    return _then(_self.copyWith(artist: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class PlaylistHit implements SearchHit {
  const PlaylistHit({required this.playlist,  String? $type}): $type = $type ?? 'playlist';
  factory PlaylistHit.fromJson(Map<String, dynamic> json) => _$PlaylistHitFromJson(json);

/// The playlist.
 final  PlaylistSummary playlist;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistHitCopyWith<PlaylistHit> get copyWith => _$PlaylistHitCopyWithImpl<PlaylistHit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaylistHitToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistHit&&(identical(other.playlist, playlist) || other.playlist == playlist));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,playlist);
}

@override
String toString() {
    return 'SearchHit.playlist(playlist: $playlist)';
}


}

/// @nodoc
abstract mixin class $PlaylistHitCopyWith<$Res> implements $SearchHitCopyWith<$Res> {
  factory $PlaylistHitCopyWith(PlaylistHit value, $Res Function(PlaylistHit) _then) = _$PlaylistHitCopyWithImpl;
@useResult
$Res call({
 PlaylistSummary playlist
});


$PlaylistSummaryCopyWith<$Res> get playlist;

}
/// @nodoc
class _$PlaylistHitCopyWithImpl<$Res>
    implements $PlaylistHitCopyWith<$Res> {
  _$PlaylistHitCopyWithImpl(this._self, this._then);

  final PlaylistHit _self;
  final $Res Function(PlaylistHit) _then;

/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlist = null,}) {
  return _then(PlaylistHit(
playlist: null == playlist ? _self.playlist : playlist // ignore: cast_nullable_to_non_nullable
as PlaylistSummary,
  ));
}

/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaylistSummaryCopyWith<$Res> get playlist {
  
  return $PlaylistSummaryCopyWith<$Res>(_self.playlist, (value) {
    return _then(_self.copyWith(playlist: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class PodcastHit implements SearchHit {
  const PodcastHit({required this.podcast,  String? $type}): $type = $type ?? 'podcast';
  factory PodcastHit.fromJson(Map<String, dynamic> json) => _$PodcastHitFromJson(json);

/// The podcast.
 final  PodcastSummary podcast;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PodcastHitCopyWith<PodcastHit> get copyWith => _$PodcastHitCopyWithImpl<PodcastHit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PodcastHitToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PodcastHit&&(identical(other.podcast, podcast) || other.podcast == podcast));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,podcast);
}

@override
String toString() {
    return 'SearchHit.podcast(podcast: $podcast)';
}


}

/// @nodoc
abstract mixin class $PodcastHitCopyWith<$Res> implements $SearchHitCopyWith<$Res> {
  factory $PodcastHitCopyWith(PodcastHit value, $Res Function(PodcastHit) _then) = _$PodcastHitCopyWithImpl;
@useResult
$Res call({
 PodcastSummary podcast
});


$PodcastSummaryCopyWith<$Res> get podcast;

}
/// @nodoc
class _$PodcastHitCopyWithImpl<$Res>
    implements $PodcastHitCopyWith<$Res> {
  _$PodcastHitCopyWithImpl(this._self, this._then);

  final PodcastHit _self;
  final $Res Function(PodcastHit) _then;

/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? podcast = null,}) {
  return _then(PodcastHit(
podcast: null == podcast ? _self.podcast : podcast // ignore: cast_nullable_to_non_nullable
as PodcastSummary,
  ));
}

/// Create a copy of SearchHit
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PodcastSummaryCopyWith<$Res> get podcast {
  
  return $PodcastSummaryCopyWith<$Res>(_self.podcast, (value) {
    return _then(_self.copyWith(podcast: value));
  });
}
}


/// @nodoc
mixin _$SearchResult {

/// What was found.
 SearchHit get hit;/// The relevance score; results are listed highest first.
 double get score;/// Where the result is held.
 SearchResultSource get source;
/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultCopyWith<SearchResult> get copyWith => _$SearchResultCopyWithImpl<SearchResult>(this as SearchResult, _$identity);

  /// Serializes this SearchResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SearchResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResult&&(identical(other.hit, _this.hit) || other.hit == _this.hit)&&(identical(other.score, _this.score) || other.score == _this.score)&&(identical(other.source, _this.source) || other.source == _this.source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SearchResult;
  return Object.hash(runtimeType,_this.hit,_this.score,_this.source);
}

@override
String toString() {
  final _this = this as SearchResult;
  return 'SearchResult(hit: ${_this.hit}, score: ${_this.score}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $SearchResultCopyWith<$Res>  {
  factory $SearchResultCopyWith(SearchResult value, $Res Function(SearchResult) _then) = _$SearchResultCopyWithImpl;
@useResult
$Res call({
 SearchHit hit, double score, SearchResultSource source
});


$SearchHitCopyWith<$Res> get hit;

}
/// @nodoc
class _$SearchResultCopyWithImpl<$Res>
    implements $SearchResultCopyWith<$Res> {
  _$SearchResultCopyWithImpl(this._self, this._then);

  final SearchResult _self;
  final $Res Function(SearchResult) _then;

/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hit = null,Object? score = null,Object? source = null,}) {
  return _then(SearchResult(
hit: null == hit ? _self.hit : hit // ignore: cast_nullable_to_non_nullable
as SearchHit,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SearchResultSource,
  ));
}
/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchHitCopyWith<$Res> get hit {
  
  return $SearchHitCopyWith<$Res>(_self.hit, (value) {
    return _then(_self.copyWith(hit: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchResult].
extension SearchResultPatterns on SearchResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResult value)  $default,){
final _that = this;
switch (_that) {
case _SearchResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResult value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchHit hit,  double score,  SearchResultSource source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
return $default(_that.hit,_that.score,_that.source);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchHit hit,  double score,  SearchResultSource source)  $default,) {final _that = this;
switch (_that) {
case _SearchResult():
return $default(_that.hit,_that.score,_that.source);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchHit hit,  double score,  SearchResultSource source)?  $default,) {final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
return $default(_that.hit,_that.score,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchResult implements SearchResult {
  const _SearchResult({required this.hit, this.score = 0, this.source = SearchResultSource.library});
  factory _SearchResult.fromJson(Map<String, dynamic> json) => _$SearchResultFromJson(json);

/// What was found.
@override final  SearchHit hit;
/// The relevance score; results are listed highest first.
@override@JsonKey() final  double score;
/// Where the result is held.
@override@JsonKey() final  SearchResultSource source;

/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResultCopyWith<_SearchResult> get copyWith => __$SearchResultCopyWithImpl<_SearchResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResult&&(identical(other.hit, hit) || other.hit == hit)&&(identical(other.score, score) || other.score == score)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,hit,score,source);
}

@override
String toString() {
    return 'SearchResult(hit: $hit, score: $score, source: $source)';
}


}

/// @nodoc
abstract mixin class _$SearchResultCopyWith<$Res> implements $SearchResultCopyWith<$Res> {
  factory _$SearchResultCopyWith(_SearchResult value, $Res Function(_SearchResult) _then) = __$SearchResultCopyWithImpl;
@override @useResult
$Res call({
 SearchHit hit, double score, SearchResultSource source
});


@override $SearchHitCopyWith<$Res> get hit;

}
/// @nodoc
class __$SearchResultCopyWithImpl<$Res>
    implements _$SearchResultCopyWith<$Res> {
  __$SearchResultCopyWithImpl(this._self, this._then);

  final _SearchResult _self;
  final $Res Function(_SearchResult) _then;

/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hit = null,Object? score = null,Object? source = null,}) {
  return _then(_SearchResult(
hit: null == hit ? _self.hit : hit // ignore: cast_nullable_to_non_nullable
as SearchHit,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SearchResultSource,
  ));
}

/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchHitCopyWith<$Res> get hit {
  
  return $SearchHitCopyWith<$Res>(_self.hit, (value) {
    return _then(_self.copyWith(hit: value));
  });
}
}


/// @nodoc
mixin _$SearchPage {

/// The results, in server order.
 List<SearchResult> get items;/// Whether a later page holds more results.
 bool get hasMore;
/// Create a copy of SearchPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchPageCopyWith<SearchPage> get copyWith => _$SearchPageCopyWithImpl<SearchPage>(this as SearchPage, _$identity);

  /// Serializes this SearchPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SearchPage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchPage&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.hasMore, _this.hasMore) || other.hasMore == _this.hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SearchPage;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.hasMore);
}

@override
String toString() {
  final _this = this as SearchPage;
  return 'SearchPage(items: ${_this.items}, hasMore: ${_this.hasMore})';
}


}

/// @nodoc
abstract mixin class $SearchPageCopyWith<$Res>  {
  factory $SearchPageCopyWith(SearchPage value, $Res Function(SearchPage) _then) = _$SearchPageCopyWithImpl;
@useResult
$Res call({
 List<SearchResult> items, bool hasMore
});




}
/// @nodoc
class _$SearchPageCopyWithImpl<$Res>
    implements $SearchPageCopyWith<$Res> {
  _$SearchPageCopyWithImpl(this._self, this._then);

  final SearchPage _self;
  final $Res Function(SearchPage) _then;

/// Create a copy of SearchPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? hasMore = null,}) {
  return _then(SearchPage(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<SearchResult>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchPage].
extension SearchPagePatterns on SearchPage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchPage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchPage value)  $default,){
final _that = this;
switch (_that) {
case _SearchPage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchPage value)?  $default,){
final _that = this;
switch (_that) {
case _SearchPage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SearchResult> items,  bool hasMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchPage() when $default != null:
return $default(_that.items,_that.hasMore);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SearchResult> items,  bool hasMore)  $default,) {final _that = this;
switch (_that) {
case _SearchPage():
return $default(_that.items,_that.hasMore);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SearchResult> items,  bool hasMore)?  $default,) {final _that = this;
switch (_that) {
case _SearchPage() when $default != null:
return $default(_that.items,_that.hasMore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchPage implements SearchPage {
  const _SearchPage({ List<SearchResult> items = const <SearchResult>[], this.hasMore = false}): _items = items;
  factory _SearchPage.fromJson(Map<String, dynamic> json) => _$SearchPageFromJson(json);

/// The results, in server order.
 final  List<SearchResult> _items;
/// The results, in server order.
@override@JsonKey() List<SearchResult> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Whether a later page holds more results.
@override@JsonKey() final  bool hasMore;

/// Create a copy of SearchPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchPageCopyWith<_SearchPage> get copyWith => __$SearchPageCopyWithImpl<_SearchPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchPageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchPage&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),hasMore);
}

@override
String toString() {
    return 'SearchPage(items: $items, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class _$SearchPageCopyWith<$Res> implements $SearchPageCopyWith<$Res> {
  factory _$SearchPageCopyWith(_SearchPage value, $Res Function(_SearchPage) _then) = __$SearchPageCopyWithImpl;
@override @useResult
$Res call({
 List<SearchResult> items, bool hasMore
});




}
/// @nodoc
class __$SearchPageCopyWithImpl<$Res>
    implements _$SearchPageCopyWith<$Res> {
  __$SearchPageCopyWithImpl(this._self, this._then);

  final _SearchPage _self;
  final $Res Function(_SearchPage) _then;

/// Create a copy of SearchPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? hasMore = null,}) {
  return _then(_SearchPage(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<SearchResult>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
