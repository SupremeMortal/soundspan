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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TrackHit value)?  track,TResult Function( AlbumHit value)?  album,TResult Function( ArtistHit value)?  artist,TResult Function( PodcastHit value)?  podcast,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TrackHit() when track != null:
return track(_that);case AlbumHit() when album != null:
return album(_that);case ArtistHit() when artist != null:
return artist(_that);case PodcastHit() when podcast != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TrackHit value)  track,required TResult Function( AlbumHit value)  album,required TResult Function( ArtistHit value)  artist,required TResult Function( PodcastHit value)  podcast,}){
final _that = this;
switch (_that) {
case TrackHit():
return track(_that);case AlbumHit():
return album(_that);case ArtistHit():
return artist(_that);case PodcastHit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TrackHit value)?  track,TResult? Function( AlbumHit value)?  album,TResult? Function( ArtistHit value)?  artist,TResult? Function( PodcastHit value)?  podcast,}){
final _that = this;
switch (_that) {
case TrackHit() when track != null:
return track(_that);case AlbumHit() when album != null:
return album(_that);case ArtistHit() when artist != null:
return artist(_that);case PodcastHit() when podcast != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Track track)?  track,TResult Function( Album album)?  album,TResult Function( Artist artist)?  artist,TResult Function( PodcastSummary podcast)?  podcast,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TrackHit() when track != null:
return track(_that.track);case AlbumHit() when album != null:
return album(_that.album);case ArtistHit() when artist != null:
return artist(_that.artist);case PodcastHit() when podcast != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Track track)  track,required TResult Function( Album album)  album,required TResult Function( Artist artist)  artist,required TResult Function( PodcastSummary podcast)  podcast,}) {final _that = this;
switch (_that) {
case TrackHit():
return track(_that.track);case AlbumHit():
return album(_that.album);case ArtistHit():
return artist(_that.artist);case PodcastHit():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Track track)?  track,TResult? Function( Album album)?  album,TResult? Function( Artist artist)?  artist,TResult? Function( PodcastSummary podcast)?  podcast,}) {final _that = this;
switch (_that) {
case TrackHit() when track != null:
return track(_that.track);case AlbumHit() when album != null:
return album(_that.album);case ArtistHit() when artist != null:
return artist(_that.artist);case PodcastHit() when podcast != null:
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
mixin _$LibrarySearchResults {

/// Matching artists.
 List<Artist> get artists;/// Matching albums.
 List<Album> get albums;/// Matching tracks.
 List<Track> get tracks;/// Matching podcasts.
 List<PodcastSummary> get podcasts;
/// Create a copy of LibrarySearchResults
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibrarySearchResultsCopyWith<LibrarySearchResults> get copyWith => _$LibrarySearchResultsCopyWithImpl<LibrarySearchResults>(this as LibrarySearchResults, _$identity);

  /// Serializes this LibrarySearchResults to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LibrarySearchResults;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibrarySearchResults&&const DeepCollectionEquality().equals(other.artists, _this.artists)&&const DeepCollectionEquality().equals(other.albums, _this.albums)&&const DeepCollectionEquality().equals(other.tracks, _this.tracks)&&const DeepCollectionEquality().equals(other.podcasts, _this.podcasts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LibrarySearchResults;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.artists),const DeepCollectionEquality().hash(_this.albums),const DeepCollectionEquality().hash(_this.tracks),const DeepCollectionEquality().hash(_this.podcasts));
}

@override
String toString() {
  final _this = this as LibrarySearchResults;
  return 'LibrarySearchResults(artists: ${_this.artists}, albums: ${_this.albums}, tracks: ${_this.tracks}, podcasts: ${_this.podcasts})';
}


}

/// @nodoc
abstract mixin class $LibrarySearchResultsCopyWith<$Res>  {
  factory $LibrarySearchResultsCopyWith(LibrarySearchResults value, $Res Function(LibrarySearchResults) _then) = _$LibrarySearchResultsCopyWithImpl;
@useResult
$Res call({
 List<Artist> artists, List<Album> albums, List<Track> tracks, List<PodcastSummary> podcasts
});




}
/// @nodoc
class _$LibrarySearchResultsCopyWithImpl<$Res>
    implements $LibrarySearchResultsCopyWith<$Res> {
  _$LibrarySearchResultsCopyWithImpl(this._self, this._then);

  final LibrarySearchResults _self;
  final $Res Function(LibrarySearchResults) _then;

/// Create a copy of LibrarySearchResults
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? artists = null,Object? albums = null,Object? tracks = null,Object? podcasts = null,}) {
  return _then(LibrarySearchResults(
artists: null == artists ? _self.artists : artists // ignore: cast_nullable_to_non_nullable
as List<Artist>,albums: null == albums ? _self.albums : albums // ignore: cast_nullable_to_non_nullable
as List<Album>,tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,podcasts: null == podcasts ? _self.podcasts : podcasts // ignore: cast_nullable_to_non_nullable
as List<PodcastSummary>,
  ));
}

}


/// Adds pattern-matching-related methods to [LibrarySearchResults].
extension LibrarySearchResultsPatterns on LibrarySearchResults {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibrarySearchResults value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibrarySearchResults() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibrarySearchResults value)  $default,){
final _that = this;
switch (_that) {
case _LibrarySearchResults():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibrarySearchResults value)?  $default,){
final _that = this;
switch (_that) {
case _LibrarySearchResults() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Artist> artists,  List<Album> albums,  List<Track> tracks,  List<PodcastSummary> podcasts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibrarySearchResults() when $default != null:
return $default(_that.artists,_that.albums,_that.tracks,_that.podcasts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Artist> artists,  List<Album> albums,  List<Track> tracks,  List<PodcastSummary> podcasts)  $default,) {final _that = this;
switch (_that) {
case _LibrarySearchResults():
return $default(_that.artists,_that.albums,_that.tracks,_that.podcasts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Artist> artists,  List<Album> albums,  List<Track> tracks,  List<PodcastSummary> podcasts)?  $default,) {final _that = this;
switch (_that) {
case _LibrarySearchResults() when $default != null:
return $default(_that.artists,_that.albums,_that.tracks,_that.podcasts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LibrarySearchResults implements LibrarySearchResults {
  const _LibrarySearchResults({ List<Artist> artists = const <Artist>[],  List<Album> albums = const <Album>[],  List<Track> tracks = const <Track>[],  List<PodcastSummary> podcasts = const <PodcastSummary>[]}): _artists = artists,_albums = albums,_tracks = tracks,_podcasts = podcasts;
  factory _LibrarySearchResults.fromJson(Map<String, dynamic> json) => _$LibrarySearchResultsFromJson(json);

/// Matching artists.
 final  List<Artist> _artists;
/// Matching artists.
@override@JsonKey() List<Artist> get artists {
  if (_artists is EqualUnmodifiableListView) return _artists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artists);
}

/// Matching albums.
 final  List<Album> _albums;
/// Matching albums.
@override@JsonKey() List<Album> get albums {
  if (_albums is EqualUnmodifiableListView) return _albums;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_albums);
}

/// Matching tracks.
 final  List<Track> _tracks;
/// Matching tracks.
@override@JsonKey() List<Track> get tracks {
  if (_tracks is EqualUnmodifiableListView) return _tracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tracks);
}

/// Matching podcasts.
 final  List<PodcastSummary> _podcasts;
/// Matching podcasts.
@override@JsonKey() List<PodcastSummary> get podcasts {
  if (_podcasts is EqualUnmodifiableListView) return _podcasts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_podcasts);
}


/// Create a copy of LibrarySearchResults
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibrarySearchResultsCopyWith<_LibrarySearchResults> get copyWith => __$LibrarySearchResultsCopyWithImpl<_LibrarySearchResults>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LibrarySearchResultsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibrarySearchResults&&const DeepCollectionEquality().equals(other.artists, _artists)&&const DeepCollectionEquality().equals(other.albums, _albums)&&const DeepCollectionEquality().equals(other.tracks, _tracks)&&const DeepCollectionEquality().equals(other.podcasts, _podcasts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_artists),const DeepCollectionEquality().hash(_albums),const DeepCollectionEquality().hash(_tracks),const DeepCollectionEquality().hash(_podcasts));
}

@override
String toString() {
    return 'LibrarySearchResults(artists: $artists, albums: $albums, tracks: $tracks, podcasts: $podcasts)';
}


}

/// @nodoc
abstract mixin class _$LibrarySearchResultsCopyWith<$Res> implements $LibrarySearchResultsCopyWith<$Res> {
  factory _$LibrarySearchResultsCopyWith(_LibrarySearchResults value, $Res Function(_LibrarySearchResults) _then) = __$LibrarySearchResultsCopyWithImpl;
@override @useResult
$Res call({
 List<Artist> artists, List<Album> albums, List<Track> tracks, List<PodcastSummary> podcasts
});




}
/// @nodoc
class __$LibrarySearchResultsCopyWithImpl<$Res>
    implements _$LibrarySearchResultsCopyWith<$Res> {
  __$LibrarySearchResultsCopyWithImpl(this._self, this._then);

  final _LibrarySearchResults _self;
  final $Res Function(_LibrarySearchResults) _then;

/// Create a copy of LibrarySearchResults
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? artists = null,Object? albums = null,Object? tracks = null,Object? podcasts = null,}) {
  return _then(_LibrarySearchResults(
artists: null == artists ? _self._artists : artists // ignore: cast_nullable_to_non_nullable
as List<Artist>,albums: null == albums ? _self._albums : albums // ignore: cast_nullable_to_non_nullable
as List<Album>,tracks: null == tracks ? _self._tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,podcasts: null == podcasts ? _self._podcasts : podcasts // ignore: cast_nullable_to_non_nullable
as List<PodcastSummary>,
  ));
}


}


/// @nodoc
mixin _$AliasInfo {

/// The query as typed.
 String get original;/// The name the search used instead.
 String get canonical;
/// Create a copy of AliasInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AliasInfoCopyWith<AliasInfo> get copyWith => _$AliasInfoCopyWithImpl<AliasInfo>(this as AliasInfo, _$identity);

  /// Serializes this AliasInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AliasInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AliasInfo&&(identical(other.original, _this.original) || other.original == _this.original)&&(identical(other.canonical, _this.canonical) || other.canonical == _this.canonical));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AliasInfo;
  return Object.hash(runtimeType,_this.original,_this.canonical);
}

@override
String toString() {
  final _this = this as AliasInfo;
  return 'AliasInfo(original: ${_this.original}, canonical: ${_this.canonical})';
}


}

/// @nodoc
abstract mixin class $AliasInfoCopyWith<$Res>  {
  factory $AliasInfoCopyWith(AliasInfo value, $Res Function(AliasInfo) _then) = _$AliasInfoCopyWithImpl;
@useResult
$Res call({
 String original, String canonical
});




}
/// @nodoc
class _$AliasInfoCopyWithImpl<$Res>
    implements $AliasInfoCopyWith<$Res> {
  _$AliasInfoCopyWithImpl(this._self, this._then);

  final AliasInfo _self;
  final $Res Function(AliasInfo) _then;

/// Create a copy of AliasInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? original = null,Object? canonical = null,}) {
  return _then(AliasInfo(
original: null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as String,canonical: null == canonical ? _self.canonical : canonical // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AliasInfo].
extension AliasInfoPatterns on AliasInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AliasInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AliasInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AliasInfo value)  $default,){
final _that = this;
switch (_that) {
case _AliasInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AliasInfo value)?  $default,){
final _that = this;
switch (_that) {
case _AliasInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String original,  String canonical)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AliasInfo() when $default != null:
return $default(_that.original,_that.canonical);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String original,  String canonical)  $default,) {final _that = this;
switch (_that) {
case _AliasInfo():
return $default(_that.original,_that.canonical);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String original,  String canonical)?  $default,) {final _that = this;
switch (_that) {
case _AliasInfo() when $default != null:
return $default(_that.original,_that.canonical);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AliasInfo implements AliasInfo {
  const _AliasInfo({required this.original, required this.canonical});
  factory _AliasInfo.fromJson(Map<String, dynamic> json) => _$AliasInfoFromJson(json);

/// The query as typed.
@override final  String original;
/// The name the search used instead.
@override final  String canonical;

/// Create a copy of AliasInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AliasInfoCopyWith<_AliasInfo> get copyWith => __$AliasInfoCopyWithImpl<_AliasInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AliasInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AliasInfo&&(identical(other.original, original) || other.original == original)&&(identical(other.canonical, canonical) || other.canonical == canonical));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,original,canonical);
}

@override
String toString() {
    return 'AliasInfo(original: $original, canonical: $canonical)';
}


}

/// @nodoc
abstract mixin class _$AliasInfoCopyWith<$Res> implements $AliasInfoCopyWith<$Res> {
  factory _$AliasInfoCopyWith(_AliasInfo value, $Res Function(_AliasInfo) _then) = __$AliasInfoCopyWithImpl;
@override @useResult
$Res call({
 String original, String canonical
});




}
/// @nodoc
class __$AliasInfoCopyWithImpl<$Res>
    implements _$AliasInfoCopyWith<$Res> {
  __$AliasInfoCopyWithImpl(this._self, this._then);

  final _AliasInfo _self;
  final $Res Function(_AliasInfo) _then;

/// Create a copy of AliasInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? original = null,Object? canonical = null,}) {
  return _then(_AliasInfo(
original: null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as String,canonical: null == canonical ? _self.canonical : canonical // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DiscoverResults {

/// The results in server order, across kinds.
 List<SearchHit> get hits;/// The correction applied to the query, if any.
 AliasInfo? get aliasInfo;
/// Create a copy of DiscoverResults
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscoverResultsCopyWith<DiscoverResults> get copyWith => _$DiscoverResultsCopyWithImpl<DiscoverResults>(this as DiscoverResults, _$identity);

  /// Serializes this DiscoverResults to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DiscoverResults;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscoverResults&&const DeepCollectionEquality().equals(other.hits, _this.hits)&&(identical(other.aliasInfo, _this.aliasInfo) || other.aliasInfo == _this.aliasInfo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DiscoverResults;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.hits),_this.aliasInfo);
}

@override
String toString() {
  final _this = this as DiscoverResults;
  return 'DiscoverResults(hits: ${_this.hits}, aliasInfo: ${_this.aliasInfo})';
}


}

/// @nodoc
abstract mixin class $DiscoverResultsCopyWith<$Res>  {
  factory $DiscoverResultsCopyWith(DiscoverResults value, $Res Function(DiscoverResults) _then) = _$DiscoverResultsCopyWithImpl;
@useResult
$Res call({
 List<SearchHit> hits, AliasInfo? aliasInfo
});


$AliasInfoCopyWith<$Res>? get aliasInfo;

}
/// @nodoc
class _$DiscoverResultsCopyWithImpl<$Res>
    implements $DiscoverResultsCopyWith<$Res> {
  _$DiscoverResultsCopyWithImpl(this._self, this._then);

  final DiscoverResults _self;
  final $Res Function(DiscoverResults) _then;

/// Create a copy of DiscoverResults
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hits = null,Object? aliasInfo = freezed,}) {
  return _then(DiscoverResults(
hits: null == hits ? _self.hits : hits // ignore: cast_nullable_to_non_nullable
as List<SearchHit>,aliasInfo: freezed == aliasInfo ? _self.aliasInfo : aliasInfo // ignore: cast_nullable_to_non_nullable
as AliasInfo?,
  ));
}
/// Create a copy of DiscoverResults
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AliasInfoCopyWith<$Res>? get aliasInfo {
    if (_self.aliasInfo == null) {
    return null;
  }

  return $AliasInfoCopyWith<$Res>(_self.aliasInfo!, (value) {
    return _then(_self.copyWith(aliasInfo: value));
  });
}
}


/// Adds pattern-matching-related methods to [DiscoverResults].
extension DiscoverResultsPatterns on DiscoverResults {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiscoverResults value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiscoverResults() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiscoverResults value)  $default,){
final _that = this;
switch (_that) {
case _DiscoverResults():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiscoverResults value)?  $default,){
final _that = this;
switch (_that) {
case _DiscoverResults() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SearchHit> hits,  AliasInfo? aliasInfo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiscoverResults() when $default != null:
return $default(_that.hits,_that.aliasInfo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SearchHit> hits,  AliasInfo? aliasInfo)  $default,) {final _that = this;
switch (_that) {
case _DiscoverResults():
return $default(_that.hits,_that.aliasInfo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SearchHit> hits,  AliasInfo? aliasInfo)?  $default,) {final _that = this;
switch (_that) {
case _DiscoverResults() when $default != null:
return $default(_that.hits,_that.aliasInfo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DiscoverResults implements DiscoverResults {
  const _DiscoverResults({ List<SearchHit> hits = const <SearchHit>[], this.aliasInfo}): _hits = hits;
  factory _DiscoverResults.fromJson(Map<String, dynamic> json) => _$DiscoverResultsFromJson(json);

/// The results in server order, across kinds.
 final  List<SearchHit> _hits;
/// The results in server order, across kinds.
@override@JsonKey() List<SearchHit> get hits {
  if (_hits is EqualUnmodifiableListView) return _hits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hits);
}

/// The correction applied to the query, if any.
@override final  AliasInfo? aliasInfo;

/// Create a copy of DiscoverResults
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiscoverResultsCopyWith<_DiscoverResults> get copyWith => __$DiscoverResultsCopyWithImpl<_DiscoverResults>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DiscoverResultsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiscoverResults&&const DeepCollectionEquality().equals(other.hits, _hits)&&(identical(other.aliasInfo, aliasInfo) || other.aliasInfo == aliasInfo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_hits),aliasInfo);
}

@override
String toString() {
    return 'DiscoverResults(hits: $hits, aliasInfo: $aliasInfo)';
}


}

/// @nodoc
abstract mixin class _$DiscoverResultsCopyWith<$Res> implements $DiscoverResultsCopyWith<$Res> {
  factory _$DiscoverResultsCopyWith(_DiscoverResults value, $Res Function(_DiscoverResults) _then) = __$DiscoverResultsCopyWithImpl;
@override @useResult
$Res call({
 List<SearchHit> hits, AliasInfo? aliasInfo
});


@override $AliasInfoCopyWith<$Res>? get aliasInfo;

}
/// @nodoc
class __$DiscoverResultsCopyWithImpl<$Res>
    implements _$DiscoverResultsCopyWith<$Res> {
  __$DiscoverResultsCopyWithImpl(this._self, this._then);

  final _DiscoverResults _self;
  final $Res Function(_DiscoverResults) _then;

/// Create a copy of DiscoverResults
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hits = null,Object? aliasInfo = freezed,}) {
  return _then(_DiscoverResults(
hits: null == hits ? _self._hits : hits // ignore: cast_nullable_to_non_nullable
as List<SearchHit>,aliasInfo: freezed == aliasInfo ? _self.aliasInfo : aliasInfo // ignore: cast_nullable_to_non_nullable
as AliasInfo?,
  ));
}

/// Create a copy of DiscoverResults
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AliasInfoCopyWith<$Res>? get aliasInfo {
    if (_self.aliasInfo == null) {
    return null;
  }

  return $AliasInfoCopyWith<$Res>(_self.aliasInfo!, (value) {
    return _then(_self.copyWith(aliasInfo: value));
  });
}
}

// dart format on
