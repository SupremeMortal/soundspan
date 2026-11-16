// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'album.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Album {

/// The server's album id.
 String get id;/// The album title.
 String get title;/// The album artist's name.
 String get artistName;/// The album artist's id.
 String get artistId;/// The release year, if known.
 int? get year;/// The value to pass to the cover-art endpoint, if any.
 String? get artworkRef;/// The number of tracks, when the server sent the tracks.
 int? get trackCount;/// The release type (album, EP, single), when the server sent one.
 String? get releaseType;/// The user's preference; the album payloads carry none, so it is
/// [Preference.neutral] until a like through this client is confirmed.
 Preference get preference;
/// Create a copy of Album
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlbumCopyWith<Album> get copyWith => _$AlbumCopyWithImpl<Album>(this as Album, _$identity);

  /// Serializes this Album to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Album;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Album&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.artistName, _this.artistName) || other.artistName == _this.artistName)&&(identical(other.artistId, _this.artistId) || other.artistId == _this.artistId)&&(identical(other.year, _this.year) || other.year == _this.year)&&(identical(other.artworkRef, _this.artworkRef) || other.artworkRef == _this.artworkRef)&&(identical(other.trackCount, _this.trackCount) || other.trackCount == _this.trackCount)&&(identical(other.releaseType, _this.releaseType) || other.releaseType == _this.releaseType)&&(identical(other.preference, _this.preference) || other.preference == _this.preference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Album;
  return Object.hash(runtimeType,_this.id,_this.title,_this.artistName,_this.artistId,_this.year,_this.artworkRef,_this.trackCount,_this.releaseType,_this.preference);
}

@override
String toString() {
  final _this = this as Album;
  return 'Album(id: ${_this.id}, title: ${_this.title}, artistName: ${_this.artistName}, artistId: ${_this.artistId}, year: ${_this.year}, artworkRef: ${_this.artworkRef}, trackCount: ${_this.trackCount}, releaseType: ${_this.releaseType}, preference: ${_this.preference})';
}


}

/// @nodoc
abstract mixin class $AlbumCopyWith<$Res>  {
  factory $AlbumCopyWith(Album value, $Res Function(Album) _then) = _$AlbumCopyWithImpl;
@useResult
$Res call({
 String id, String title, String artistName, String artistId, int? year, String? artworkRef, int? trackCount, String? releaseType, Preference preference
});




}
/// @nodoc
class _$AlbumCopyWithImpl<$Res>
    implements $AlbumCopyWith<$Res> {
  _$AlbumCopyWithImpl(this._self, this._then);

  final Album _self;
  final $Res Function(Album) _then;

/// Create a copy of Album
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? artistName = null,Object? artistId = null,Object? year = freezed,Object? artworkRef = freezed,Object? trackCount = freezed,Object? releaseType = freezed,Object? preference = null,}) {
  return _then(Album(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artistName: null == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String,artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,trackCount: freezed == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int?,releaseType: freezed == releaseType ? _self.releaseType : releaseType // ignore: cast_nullable_to_non_nullable
as String?,preference: null == preference ? _self.preference : preference // ignore: cast_nullable_to_non_nullable
as Preference,
  ));
}

}


/// Adds pattern-matching-related methods to [Album].
extension AlbumPatterns on Album {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Album value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Album() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Album value)  $default,){
final _that = this;
switch (_that) {
case _Album():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Album value)?  $default,){
final _that = this;
switch (_that) {
case _Album() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String artistName,  String artistId,  int? year,  String? artworkRef,  int? trackCount,  String? releaseType,  Preference preference)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Album() when $default != null:
return $default(_that.id,_that.title,_that.artistName,_that.artistId,_that.year,_that.artworkRef,_that.trackCount,_that.releaseType,_that.preference);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String artistName,  String artistId,  int? year,  String? artworkRef,  int? trackCount,  String? releaseType,  Preference preference)  $default,) {final _that = this;
switch (_that) {
case _Album():
return $default(_that.id,_that.title,_that.artistName,_that.artistId,_that.year,_that.artworkRef,_that.trackCount,_that.releaseType,_that.preference);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String artistName,  String artistId,  int? year,  String? artworkRef,  int? trackCount,  String? releaseType,  Preference preference)?  $default,) {final _that = this;
switch (_that) {
case _Album() when $default != null:
return $default(_that.id,_that.title,_that.artistName,_that.artistId,_that.year,_that.artworkRef,_that.trackCount,_that.releaseType,_that.preference);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Album implements Album {
  const _Album({required this.id, required this.title, required this.artistName, required this.artistId, this.year, this.artworkRef, this.trackCount, this.releaseType, this.preference = Preference.neutral});
  factory _Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);

/// The server's album id.
@override final  String id;
/// The album title.
@override final  String title;
/// The album artist's name.
@override final  String artistName;
/// The album artist's id.
@override final  String artistId;
/// The release year, if known.
@override final  int? year;
/// The value to pass to the cover-art endpoint, if any.
@override final  String? artworkRef;
/// The number of tracks, when the server sent the tracks.
@override final  int? trackCount;
/// The release type (album, EP, single), when the server sent one.
@override final  String? releaseType;
/// The user's preference; the album payloads carry none, so it is
/// [Preference.neutral] until a like through this client is confirmed.
@override@JsonKey() final  Preference preference;

/// Create a copy of Album
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlbumCopyWith<_Album> get copyWith => __$AlbumCopyWithImpl<_Album>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AlbumToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Album&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.artistName, artistName) || other.artistName == artistName)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.year, year) || other.year == year)&&(identical(other.artworkRef, artworkRef) || other.artworkRef == artworkRef)&&(identical(other.trackCount, trackCount) || other.trackCount == trackCount)&&(identical(other.releaseType, releaseType) || other.releaseType == releaseType)&&(identical(other.preference, preference) || other.preference == preference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,artistName,artistId,year,artworkRef,trackCount,releaseType,preference);
}

@override
String toString() {
    return 'Album(id: $id, title: $title, artistName: $artistName, artistId: $artistId, year: $year, artworkRef: $artworkRef, trackCount: $trackCount, releaseType: $releaseType, preference: $preference)';
}


}

/// @nodoc
abstract mixin class _$AlbumCopyWith<$Res> implements $AlbumCopyWith<$Res> {
  factory _$AlbumCopyWith(_Album value, $Res Function(_Album) _then) = __$AlbumCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String artistName, String artistId, int? year, String? artworkRef, int? trackCount, String? releaseType, Preference preference
});




}
/// @nodoc
class __$AlbumCopyWithImpl<$Res>
    implements _$AlbumCopyWith<$Res> {
  __$AlbumCopyWithImpl(this._self, this._then);

  final _Album _self;
  final $Res Function(_Album) _then;

/// Create a copy of Album
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? artistName = null,Object? artistId = null,Object? year = freezed,Object? artworkRef = freezed,Object? trackCount = freezed,Object? releaseType = freezed,Object? preference = null,}) {
  return _then(_Album(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artistName: null == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String,artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,trackCount: freezed == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int?,releaseType: freezed == releaseType ? _self.releaseType : releaseType // ignore: cast_nullable_to_non_nullable
as String?,preference: null == preference ? _self.preference : preference // ignore: cast_nullable_to_non_nullable
as Preference,
  ));
}


}


/// @nodoc
mixin _$AlbumDetail {

/// The album.
 Album get album;/// The album's tracks in disc and track order.
 List<Track> get tracks;/// Whether the user's library holds the album.
 bool get owned;
/// Create a copy of AlbumDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlbumDetailCopyWith<AlbumDetail> get copyWith => _$AlbumDetailCopyWithImpl<AlbumDetail>(this as AlbumDetail, _$identity);

  /// Serializes this AlbumDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AlbumDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlbumDetail&&(identical(other.album, _this.album) || other.album == _this.album)&&const DeepCollectionEquality().equals(other.tracks, _this.tracks)&&(identical(other.owned, _this.owned) || other.owned == _this.owned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AlbumDetail;
  return Object.hash(runtimeType,_this.album,const DeepCollectionEquality().hash(_this.tracks),_this.owned);
}

@override
String toString() {
  final _this = this as AlbumDetail;
  return 'AlbumDetail(album: ${_this.album}, tracks: ${_this.tracks}, owned: ${_this.owned})';
}


}

/// @nodoc
abstract mixin class $AlbumDetailCopyWith<$Res>  {
  factory $AlbumDetailCopyWith(AlbumDetail value, $Res Function(AlbumDetail) _then) = _$AlbumDetailCopyWithImpl;
@useResult
$Res call({
 Album album, List<Track> tracks, bool owned
});


$AlbumCopyWith<$Res> get album;

}
/// @nodoc
class _$AlbumDetailCopyWithImpl<$Res>
    implements $AlbumDetailCopyWith<$Res> {
  _$AlbumDetailCopyWithImpl(this._self, this._then);

  final AlbumDetail _self;
  final $Res Function(AlbumDetail) _then;

/// Create a copy of AlbumDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? album = null,Object? tracks = null,Object? owned = null,}) {
  return _then(AlbumDetail(
album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as Album,tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,owned: null == owned ? _self.owned : owned // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of AlbumDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AlbumCopyWith<$Res> get album {
  
  return $AlbumCopyWith<$Res>(_self.album, (value) {
    return _then(_self.copyWith(album: value));
  });
}
}


/// Adds pattern-matching-related methods to [AlbumDetail].
extension AlbumDetailPatterns on AlbumDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AlbumDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AlbumDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AlbumDetail value)  $default,){
final _that = this;
switch (_that) {
case _AlbumDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AlbumDetail value)?  $default,){
final _that = this;
switch (_that) {
case _AlbumDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Album album,  List<Track> tracks,  bool owned)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AlbumDetail() when $default != null:
return $default(_that.album,_that.tracks,_that.owned);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Album album,  List<Track> tracks,  bool owned)  $default,) {final _that = this;
switch (_that) {
case _AlbumDetail():
return $default(_that.album,_that.tracks,_that.owned);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Album album,  List<Track> tracks,  bool owned)?  $default,) {final _that = this;
switch (_that) {
case _AlbumDetail() when $default != null:
return $default(_that.album,_that.tracks,_that.owned);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AlbumDetail implements AlbumDetail {
  const _AlbumDetail({required this.album, required  List<Track> tracks, required this.owned}): _tracks = tracks;
  factory _AlbumDetail.fromJson(Map<String, dynamic> json) => _$AlbumDetailFromJson(json);

/// The album.
@override final  Album album;
/// The album's tracks in disc and track order.
 final  List<Track> _tracks;
/// The album's tracks in disc and track order.
@override List<Track> get tracks {
  if (_tracks is EqualUnmodifiableListView) return _tracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tracks);
}

/// Whether the user's library holds the album.
@override final  bool owned;

/// Create a copy of AlbumDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlbumDetailCopyWith<_AlbumDetail> get copyWith => __$AlbumDetailCopyWithImpl<_AlbumDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AlbumDetailToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AlbumDetail&&(identical(other.album, album) || other.album == album)&&const DeepCollectionEquality().equals(other.tracks, _tracks)&&(identical(other.owned, owned) || other.owned == owned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,album,const DeepCollectionEquality().hash(_tracks),owned);
}

@override
String toString() {
    return 'AlbumDetail(album: $album, tracks: $tracks, owned: $owned)';
}


}

/// @nodoc
abstract mixin class _$AlbumDetailCopyWith<$Res> implements $AlbumDetailCopyWith<$Res> {
  factory _$AlbumDetailCopyWith(_AlbumDetail value, $Res Function(_AlbumDetail) _then) = __$AlbumDetailCopyWithImpl;
@override @useResult
$Res call({
 Album album, List<Track> tracks, bool owned
});


@override $AlbumCopyWith<$Res> get album;

}
/// @nodoc
class __$AlbumDetailCopyWithImpl<$Res>
    implements _$AlbumDetailCopyWith<$Res> {
  __$AlbumDetailCopyWithImpl(this._self, this._then);

  final _AlbumDetail _self;
  final $Res Function(_AlbumDetail) _then;

/// Create a copy of AlbumDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? album = null,Object? tracks = null,Object? owned = null,}) {
  return _then(_AlbumDetail(
album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as Album,tracks: null == tracks ? _self._tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,owned: null == owned ? _self.owned : owned // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of AlbumDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AlbumCopyWith<$Res> get album {
  
  return $AlbumCopyWith<$Res>(_self.album, (value) {
    return _then(_self.copyWith(album: value));
  });
}
}

// dart format on
