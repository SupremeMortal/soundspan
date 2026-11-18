// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Artist {

/// The server's artist id.
 String get id;/// The artist name.
 String get name;/// The value to pass to the cover-art endpoint, if any.
 String? get artworkRef;
/// Create a copy of Artist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistCopyWith<Artist> get copyWith => _$ArtistCopyWithImpl<Artist>(this as Artist, _$identity);

  /// Serializes this Artist to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Artist;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Artist&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.artworkRef, _this.artworkRef) || other.artworkRef == _this.artworkRef));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Artist;
  return Object.hash(runtimeType,_this.id,_this.name,_this.artworkRef);
}

@override
String toString() {
  final _this = this as Artist;
  return 'Artist(id: ${_this.id}, name: ${_this.name}, artworkRef: ${_this.artworkRef})';
}


}

/// @nodoc
abstract mixin class $ArtistCopyWith<$Res>  {
  factory $ArtistCopyWith(Artist value, $Res Function(Artist) _then) = _$ArtistCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? artworkRef
});




}
/// @nodoc
class _$ArtistCopyWithImpl<$Res>
    implements $ArtistCopyWith<$Res> {
  _$ArtistCopyWithImpl(this._self, this._then);

  final Artist _self;
  final $Res Function(Artist) _then;

/// Create a copy of Artist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? artworkRef = freezed,}) {
  return _then(Artist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Artist].
extension ArtistPatterns on Artist {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Artist value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Artist() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Artist value)  $default,){
final _that = this;
switch (_that) {
case _Artist():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Artist value)?  $default,){
final _that = this;
switch (_that) {
case _Artist() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? artworkRef)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Artist() when $default != null:
return $default(_that.id,_that.name,_that.artworkRef);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? artworkRef)  $default,) {final _that = this;
switch (_that) {
case _Artist():
return $default(_that.id,_that.name,_that.artworkRef);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? artworkRef)?  $default,) {final _that = this;
switch (_that) {
case _Artist() when $default != null:
return $default(_that.id,_that.name,_that.artworkRef);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Artist implements Artist {
  const _Artist({required this.id, required this.name, this.artworkRef});
  factory _Artist.fromJson(Map<String, dynamic> json) => _$ArtistFromJson(json);

/// The server's artist id.
@override final  String id;
/// The artist name.
@override final  String name;
/// The value to pass to the cover-art endpoint, if any.
@override final  String? artworkRef;

/// Create a copy of Artist
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistCopyWith<_Artist> get copyWith => __$ArtistCopyWithImpl<_Artist>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Artist&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.artworkRef, artworkRef) || other.artworkRef == artworkRef));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,artworkRef);
}

@override
String toString() {
    return 'Artist(id: $id, name: $name, artworkRef: $artworkRef)';
}


}

/// @nodoc
abstract mixin class _$ArtistCopyWith<$Res> implements $ArtistCopyWith<$Res> {
  factory _$ArtistCopyWith(_Artist value, $Res Function(_Artist) _then) = __$ArtistCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? artworkRef
});




}
/// @nodoc
class __$ArtistCopyWithImpl<$Res>
    implements _$ArtistCopyWith<$Res> {
  __$ArtistCopyWithImpl(this._self, this._then);

  final _Artist _self;
  final $Res Function(_Artist) _then;

/// Create a copy of Artist
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? artworkRef = freezed,}) {
  return _then(_Artist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SimilarArtist {

/// The artist name.
 String get name;/// The value to pass to the cover-art endpoint, if any.
 String? get artworkRef;/// The library artist id, when the library holds the artist.
 String? get libraryId;
/// Create a copy of SimilarArtist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimilarArtistCopyWith<SimilarArtist> get copyWith => _$SimilarArtistCopyWithImpl<SimilarArtist>(this as SimilarArtist, _$identity);

  /// Serializes this SimilarArtist to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SimilarArtist;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimilarArtist&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.artworkRef, _this.artworkRef) || other.artworkRef == _this.artworkRef)&&(identical(other.libraryId, _this.libraryId) || other.libraryId == _this.libraryId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SimilarArtist;
  return Object.hash(runtimeType,_this.name,_this.artworkRef,_this.libraryId);
}

@override
String toString() {
  final _this = this as SimilarArtist;
  return 'SimilarArtist(name: ${_this.name}, artworkRef: ${_this.artworkRef}, libraryId: ${_this.libraryId})';
}


}

/// @nodoc
abstract mixin class $SimilarArtistCopyWith<$Res>  {
  factory $SimilarArtistCopyWith(SimilarArtist value, $Res Function(SimilarArtist) _then) = _$SimilarArtistCopyWithImpl;
@useResult
$Res call({
 String name, String? artworkRef, String? libraryId
});




}
/// @nodoc
class _$SimilarArtistCopyWithImpl<$Res>
    implements $SimilarArtistCopyWith<$Res> {
  _$SimilarArtistCopyWithImpl(this._self, this._then);

  final SimilarArtist _self;
  final $Res Function(SimilarArtist) _then;

/// Create a copy of SimilarArtist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? artworkRef = freezed,Object? libraryId = freezed,}) {
  return _then(SimilarArtist(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,libraryId: freezed == libraryId ? _self.libraryId : libraryId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SimilarArtist].
extension SimilarArtistPatterns on SimilarArtist {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SimilarArtist value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SimilarArtist() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SimilarArtist value)  $default,){
final _that = this;
switch (_that) {
case _SimilarArtist():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SimilarArtist value)?  $default,){
final _that = this;
switch (_that) {
case _SimilarArtist() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? artworkRef,  String? libraryId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SimilarArtist() when $default != null:
return $default(_that.name,_that.artworkRef,_that.libraryId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? artworkRef,  String? libraryId)  $default,) {final _that = this;
switch (_that) {
case _SimilarArtist():
return $default(_that.name,_that.artworkRef,_that.libraryId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? artworkRef,  String? libraryId)?  $default,) {final _that = this;
switch (_that) {
case _SimilarArtist() when $default != null:
return $default(_that.name,_that.artworkRef,_that.libraryId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SimilarArtist implements SimilarArtist {
  const _SimilarArtist({required this.name, this.artworkRef, this.libraryId});
  factory _SimilarArtist.fromJson(Map<String, dynamic> json) => _$SimilarArtistFromJson(json);

/// The artist name.
@override final  String name;
/// The value to pass to the cover-art endpoint, if any.
@override final  String? artworkRef;
/// The library artist id, when the library holds the artist.
@override final  String? libraryId;

/// Create a copy of SimilarArtist
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SimilarArtistCopyWith<_SimilarArtist> get copyWith => __$SimilarArtistCopyWithImpl<_SimilarArtist>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SimilarArtistToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SimilarArtist&&(identical(other.name, name) || other.name == name)&&(identical(other.artworkRef, artworkRef) || other.artworkRef == artworkRef)&&(identical(other.libraryId, libraryId) || other.libraryId == libraryId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,artworkRef,libraryId);
}

@override
String toString() {
    return 'SimilarArtist(name: $name, artworkRef: $artworkRef, libraryId: $libraryId)';
}


}

/// @nodoc
abstract mixin class _$SimilarArtistCopyWith<$Res> implements $SimilarArtistCopyWith<$Res> {
  factory _$SimilarArtistCopyWith(_SimilarArtist value, $Res Function(_SimilarArtist) _then) = __$SimilarArtistCopyWithImpl;
@override @useResult
$Res call({
 String name, String? artworkRef, String? libraryId
});




}
/// @nodoc
class __$SimilarArtistCopyWithImpl<$Res>
    implements _$SimilarArtistCopyWith<$Res> {
  __$SimilarArtistCopyWithImpl(this._self, this._then);

  final _SimilarArtist _self;
  final $Res Function(_SimilarArtist) _then;

/// Create a copy of SimilarArtist
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? artworkRef = freezed,Object? libraryId = freezed,}) {
  return _then(_SimilarArtist(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,libraryId: freezed == libraryId ? _self.libraryId : libraryId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ArtistDetail {

/// The artist.
 Artist get artist;/// The artist's albums.
 List<Album> get albums;/// The artist's most played tracks.
 List<Track> get topTracks;/// Artists similar to this one.
 List<SimilarArtist> get similarArtists;/// The artist's biography, if the server has one.
 String? get biography;/// The artist's genres.
 List<String> get genres;
/// Create a copy of ArtistDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistDetailCopyWith<ArtistDetail> get copyWith => _$ArtistDetailCopyWithImpl<ArtistDetail>(this as ArtistDetail, _$identity);

  /// Serializes this ArtistDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ArtistDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistDetail&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&const DeepCollectionEquality().equals(other.albums, _this.albums)&&const DeepCollectionEquality().equals(other.topTracks, _this.topTracks)&&const DeepCollectionEquality().equals(other.similarArtists, _this.similarArtists)&&(identical(other.biography, _this.biography) || other.biography == _this.biography)&&const DeepCollectionEquality().equals(other.genres, _this.genres));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ArtistDetail;
  return Object.hash(runtimeType,_this.artist,const DeepCollectionEquality().hash(_this.albums),const DeepCollectionEquality().hash(_this.topTracks),const DeepCollectionEquality().hash(_this.similarArtists),_this.biography,const DeepCollectionEquality().hash(_this.genres));
}

@override
String toString() {
  final _this = this as ArtistDetail;
  return 'ArtistDetail(artist: ${_this.artist}, albums: ${_this.albums}, topTracks: ${_this.topTracks}, similarArtists: ${_this.similarArtists}, biography: ${_this.biography}, genres: ${_this.genres})';
}


}

/// @nodoc
abstract mixin class $ArtistDetailCopyWith<$Res>  {
  factory $ArtistDetailCopyWith(ArtistDetail value, $Res Function(ArtistDetail) _then) = _$ArtistDetailCopyWithImpl;
@useResult
$Res call({
 Artist artist, List<Album> albums, List<Track> topTracks, List<SimilarArtist> similarArtists, String? biography, List<String> genres
});


$ArtistCopyWith<$Res> get artist;

}
/// @nodoc
class _$ArtistDetailCopyWithImpl<$Res>
    implements $ArtistDetailCopyWith<$Res> {
  _$ArtistDetailCopyWithImpl(this._self, this._then);

  final ArtistDetail _self;
  final $Res Function(ArtistDetail) _then;

/// Create a copy of ArtistDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? artist = null,Object? albums = null,Object? topTracks = null,Object? similarArtists = null,Object? biography = freezed,Object? genres = null,}) {
  return _then(ArtistDetail(
artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as Artist,albums: null == albums ? _self.albums : albums // ignore: cast_nullable_to_non_nullable
as List<Album>,topTracks: null == topTracks ? _self.topTracks : topTracks // ignore: cast_nullable_to_non_nullable
as List<Track>,similarArtists: null == similarArtists ? _self.similarArtists : similarArtists // ignore: cast_nullable_to_non_nullable
as List<SimilarArtist>,biography: freezed == biography ? _self.biography : biography // ignore: cast_nullable_to_non_nullable
as String?,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of ArtistDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistCopyWith<$Res> get artist {
  
  return $ArtistCopyWith<$Res>(_self.artist, (value) {
    return _then(_self.copyWith(artist: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArtistDetail].
extension ArtistDetailPatterns on ArtistDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistDetail value)  $default,){
final _that = this;
switch (_that) {
case _ArtistDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistDetail value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Artist artist,  List<Album> albums,  List<Track> topTracks,  List<SimilarArtist> similarArtists,  String? biography,  List<String> genres)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistDetail() when $default != null:
return $default(_that.artist,_that.albums,_that.topTracks,_that.similarArtists,_that.biography,_that.genres);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Artist artist,  List<Album> albums,  List<Track> topTracks,  List<SimilarArtist> similarArtists,  String? biography,  List<String> genres)  $default,) {final _that = this;
switch (_that) {
case _ArtistDetail():
return $default(_that.artist,_that.albums,_that.topTracks,_that.similarArtists,_that.biography,_that.genres);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Artist artist,  List<Album> albums,  List<Track> topTracks,  List<SimilarArtist> similarArtists,  String? biography,  List<String> genres)?  $default,) {final _that = this;
switch (_that) {
case _ArtistDetail() when $default != null:
return $default(_that.artist,_that.albums,_that.topTracks,_that.similarArtists,_that.biography,_that.genres);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtistDetail implements ArtistDetail {
  const _ArtistDetail({required this.artist,  List<Album> albums = const <Album>[],  List<Track> topTracks = const <Track>[],  List<SimilarArtist> similarArtists = const <SimilarArtist>[], this.biography,  List<String> genres = const <String>[]}): _albums = albums,_topTracks = topTracks,_similarArtists = similarArtists,_genres = genres;
  factory _ArtistDetail.fromJson(Map<String, dynamic> json) => _$ArtistDetailFromJson(json);

/// The artist.
@override final  Artist artist;
/// The artist's albums.
 final  List<Album> _albums;
/// The artist's albums.
@override@JsonKey() List<Album> get albums {
  if (_albums is EqualUnmodifiableListView) return _albums;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_albums);
}

/// The artist's most played tracks.
 final  List<Track> _topTracks;
/// The artist's most played tracks.
@override@JsonKey() List<Track> get topTracks {
  if (_topTracks is EqualUnmodifiableListView) return _topTracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topTracks);
}

/// Artists similar to this one.
 final  List<SimilarArtist> _similarArtists;
/// Artists similar to this one.
@override@JsonKey() List<SimilarArtist> get similarArtists {
  if (_similarArtists is EqualUnmodifiableListView) return _similarArtists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_similarArtists);
}

/// The artist's biography, if the server has one.
@override final  String? biography;
/// The artist's genres.
 final  List<String> _genres;
/// The artist's genres.
@override@JsonKey() List<String> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}


/// Create a copy of ArtistDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistDetailCopyWith<_ArtistDetail> get copyWith => __$ArtistDetailCopyWithImpl<_ArtistDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistDetailToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistDetail&&(identical(other.artist, artist) || other.artist == artist)&&const DeepCollectionEquality().equals(other.albums, _albums)&&const DeepCollectionEquality().equals(other.topTracks, _topTracks)&&const DeepCollectionEquality().equals(other.similarArtists, _similarArtists)&&(identical(other.biography, biography) || other.biography == biography)&&const DeepCollectionEquality().equals(other.genres, _genres));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,artist,const DeepCollectionEquality().hash(_albums),const DeepCollectionEquality().hash(_topTracks),const DeepCollectionEquality().hash(_similarArtists),biography,const DeepCollectionEquality().hash(_genres));
}

@override
String toString() {
    return 'ArtistDetail(artist: $artist, albums: $albums, topTracks: $topTracks, similarArtists: $similarArtists, biography: $biography, genres: $genres)';
}


}

/// @nodoc
abstract mixin class _$ArtistDetailCopyWith<$Res> implements $ArtistDetailCopyWith<$Res> {
  factory _$ArtistDetailCopyWith(_ArtistDetail value, $Res Function(_ArtistDetail) _then) = __$ArtistDetailCopyWithImpl;
@override @useResult
$Res call({
 Artist artist, List<Album> albums, List<Track> topTracks, List<SimilarArtist> similarArtists, String? biography, List<String> genres
});


@override $ArtistCopyWith<$Res> get artist;

}
/// @nodoc
class __$ArtistDetailCopyWithImpl<$Res>
    implements _$ArtistDetailCopyWith<$Res> {
  __$ArtistDetailCopyWithImpl(this._self, this._then);

  final _ArtistDetail _self;
  final $Res Function(_ArtistDetail) _then;

/// Create a copy of ArtistDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? artist = null,Object? albums = null,Object? topTracks = null,Object? similarArtists = null,Object? biography = freezed,Object? genres = null,}) {
  return _then(_ArtistDetail(
artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as Artist,albums: null == albums ? _self._albums : albums // ignore: cast_nullable_to_non_nullable
as List<Album>,topTracks: null == topTracks ? _self._topTracks : topTracks // ignore: cast_nullable_to_non_nullable
as List<Track>,similarArtists: null == similarArtists ? _self._similarArtists : similarArtists // ignore: cast_nullable_to_non_nullable
as List<SimilarArtist>,biography: freezed == biography ? _self.biography : biography // ignore: cast_nullable_to_non_nullable
as String?,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of ArtistDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistCopyWith<$Res> get artist {
  
  return $ArtistCopyWith<$Res>(_self.artist, (value) {
    return _then(_self.copyWith(artist: value));
  });
}
}

// dart format on
