// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'socket_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SocketQueueArtist {

/// The server's artist id.
 String get id;/// The artist name.
 String get name;
/// Create a copy of SocketQueueArtist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SocketQueueArtistCopyWith<SocketQueueArtist> get copyWith => _$SocketQueueArtistCopyWithImpl<SocketQueueArtist>(this as SocketQueueArtist, _$identity);

  /// Serializes this SocketQueueArtist to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SocketQueueArtist;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocketQueueArtist&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SocketQueueArtist;
  return Object.hash(runtimeType,_this.id,_this.name);
}

@override
String toString() {
  final _this = this as SocketQueueArtist;
  return 'SocketQueueArtist(id: ${_this.id}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $SocketQueueArtistCopyWith<$Res>  {
  factory $SocketQueueArtistCopyWith(SocketQueueArtist value, $Res Function(SocketQueueArtist) _then) = _$SocketQueueArtistCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$SocketQueueArtistCopyWithImpl<$Res>
    implements $SocketQueueArtistCopyWith<$Res> {
  _$SocketQueueArtistCopyWithImpl(this._self, this._then);

  final SocketQueueArtist _self;
  final $Res Function(SocketQueueArtist) _then;

/// Create a copy of SocketQueueArtist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(SocketQueueArtist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SocketQueueArtist].
extension SocketQueueArtistPatterns on SocketQueueArtist {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SocketQueueArtist value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SocketQueueArtist() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SocketQueueArtist value)  $default,){
final _that = this;
switch (_that) {
case _SocketQueueArtist():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SocketQueueArtist value)?  $default,){
final _that = this;
switch (_that) {
case _SocketQueueArtist() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SocketQueueArtist() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name)  $default,) {final _that = this;
switch (_that) {
case _SocketQueueArtist():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _SocketQueueArtist() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SocketQueueArtist implements SocketQueueArtist {
  const _SocketQueueArtist({required this.id, required this.name});
  factory _SocketQueueArtist.fromJson(Map<String, dynamic> json) => _$SocketQueueArtistFromJson(json);

/// The server's artist id.
@override final  String id;
/// The artist name.
@override final  String name;

/// Create a copy of SocketQueueArtist
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SocketQueueArtistCopyWith<_SocketQueueArtist> get copyWith => __$SocketQueueArtistCopyWithImpl<_SocketQueueArtist>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SocketQueueArtistToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SocketQueueArtist&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name);
}

@override
String toString() {
    return 'SocketQueueArtist(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$SocketQueueArtistCopyWith<$Res> implements $SocketQueueArtistCopyWith<$Res> {
  factory _$SocketQueueArtistCopyWith(_SocketQueueArtist value, $Res Function(_SocketQueueArtist) _then) = __$SocketQueueArtistCopyWithImpl;
@override @useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$SocketQueueArtistCopyWithImpl<$Res>
    implements _$SocketQueueArtistCopyWith<$Res> {
  __$SocketQueueArtistCopyWithImpl(this._self, this._then);

  final _SocketQueueArtist _self;
  final $Res Function(_SocketQueueArtist) _then;

/// Create a copy of SocketQueueArtist
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_SocketQueueArtist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SocketQueueAlbum {

/// The server's album id.
 String get id;/// The album title.
 String get title;/// The value to pass to the cover-art endpoint, if there is art.
 String? get coverArt;/// The album's integrated loudness, in LUFS.
 double? get albumLoudnessLufs;/// The album's true peak, in dBTP.
 double? get albumTruePeakDb;
/// Create a copy of SocketQueueAlbum
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SocketQueueAlbumCopyWith<SocketQueueAlbum> get copyWith => _$SocketQueueAlbumCopyWithImpl<SocketQueueAlbum>(this as SocketQueueAlbum, _$identity);

  /// Serializes this SocketQueueAlbum to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SocketQueueAlbum;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocketQueueAlbum&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.coverArt, _this.coverArt) || other.coverArt == _this.coverArt)&&(identical(other.albumLoudnessLufs, _this.albumLoudnessLufs) || other.albumLoudnessLufs == _this.albumLoudnessLufs)&&(identical(other.albumTruePeakDb, _this.albumTruePeakDb) || other.albumTruePeakDb == _this.albumTruePeakDb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SocketQueueAlbum;
  return Object.hash(runtimeType,_this.id,_this.title,_this.coverArt,_this.albumLoudnessLufs,_this.albumTruePeakDb);
}

@override
String toString() {
  final _this = this as SocketQueueAlbum;
  return 'SocketQueueAlbum(id: ${_this.id}, title: ${_this.title}, coverArt: ${_this.coverArt}, albumLoudnessLufs: ${_this.albumLoudnessLufs}, albumTruePeakDb: ${_this.albumTruePeakDb})';
}


}

/// @nodoc
abstract mixin class $SocketQueueAlbumCopyWith<$Res>  {
  factory $SocketQueueAlbumCopyWith(SocketQueueAlbum value, $Res Function(SocketQueueAlbum) _then) = _$SocketQueueAlbumCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? coverArt, double? albumLoudnessLufs, double? albumTruePeakDb
});




}
/// @nodoc
class _$SocketQueueAlbumCopyWithImpl<$Res>
    implements $SocketQueueAlbumCopyWith<$Res> {
  _$SocketQueueAlbumCopyWithImpl(this._self, this._then);

  final SocketQueueAlbum _self;
  final $Res Function(SocketQueueAlbum) _then;

/// Create a copy of SocketQueueAlbum
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? coverArt = freezed,Object? albumLoudnessLufs = freezed,Object? albumTruePeakDb = freezed,}) {
  return _then(SocketQueueAlbum(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,albumLoudnessLufs: freezed == albumLoudnessLufs ? _self.albumLoudnessLufs : albumLoudnessLufs // ignore: cast_nullable_to_non_nullable
as double?,albumTruePeakDb: freezed == albumTruePeakDb ? _self.albumTruePeakDb : albumTruePeakDb // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [SocketQueueAlbum].
extension SocketQueueAlbumPatterns on SocketQueueAlbum {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SocketQueueAlbum value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SocketQueueAlbum() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SocketQueueAlbum value)  $default,){
final _that = this;
switch (_that) {
case _SocketQueueAlbum():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SocketQueueAlbum value)?  $default,){
final _that = this;
switch (_that) {
case _SocketQueueAlbum() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? coverArt,  double? albumLoudnessLufs,  double? albumTruePeakDb)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SocketQueueAlbum() when $default != null:
return $default(_that.id,_that.title,_that.coverArt,_that.albumLoudnessLufs,_that.albumTruePeakDb);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? coverArt,  double? albumLoudnessLufs,  double? albumTruePeakDb)  $default,) {final _that = this;
switch (_that) {
case _SocketQueueAlbum():
return $default(_that.id,_that.title,_that.coverArt,_that.albumLoudnessLufs,_that.albumTruePeakDb);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? coverArt,  double? albumLoudnessLufs,  double? albumTruePeakDb)?  $default,) {final _that = this;
switch (_that) {
case _SocketQueueAlbum() when $default != null:
return $default(_that.id,_that.title,_that.coverArt,_that.albumLoudnessLufs,_that.albumTruePeakDb);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SocketQueueAlbum implements SocketQueueAlbum {
  const _SocketQueueAlbum({required this.id, required this.title, this.coverArt, this.albumLoudnessLufs, this.albumTruePeakDb});
  factory _SocketQueueAlbum.fromJson(Map<String, dynamic> json) => _$SocketQueueAlbumFromJson(json);

/// The server's album id.
@override final  String id;
/// The album title.
@override final  String title;
/// The value to pass to the cover-art endpoint, if there is art.
@override final  String? coverArt;
/// The album's integrated loudness, in LUFS.
@override final  double? albumLoudnessLufs;
/// The album's true peak, in dBTP.
@override final  double? albumTruePeakDb;

/// Create a copy of SocketQueueAlbum
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SocketQueueAlbumCopyWith<_SocketQueueAlbum> get copyWith => __$SocketQueueAlbumCopyWithImpl<_SocketQueueAlbum>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SocketQueueAlbumToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SocketQueueAlbum&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.coverArt, coverArt) || other.coverArt == coverArt)&&(identical(other.albumLoudnessLufs, albumLoudnessLufs) || other.albumLoudnessLufs == albumLoudnessLufs)&&(identical(other.albumTruePeakDb, albumTruePeakDb) || other.albumTruePeakDb == albumTruePeakDb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,coverArt,albumLoudnessLufs,albumTruePeakDb);
}

@override
String toString() {
    return 'SocketQueueAlbum(id: $id, title: $title, coverArt: $coverArt, albumLoudnessLufs: $albumLoudnessLufs, albumTruePeakDb: $albumTruePeakDb)';
}


}

/// @nodoc
abstract mixin class _$SocketQueueAlbumCopyWith<$Res> implements $SocketQueueAlbumCopyWith<$Res> {
  factory _$SocketQueueAlbumCopyWith(_SocketQueueAlbum value, $Res Function(_SocketQueueAlbum) _then) = __$SocketQueueAlbumCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? coverArt, double? albumLoudnessLufs, double? albumTruePeakDb
});




}
/// @nodoc
class __$SocketQueueAlbumCopyWithImpl<$Res>
    implements _$SocketQueueAlbumCopyWith<$Res> {
  __$SocketQueueAlbumCopyWithImpl(this._self, this._then);

  final _SocketQueueAlbum _self;
  final $Res Function(_SocketQueueAlbum) _then;

/// Create a copy of SocketQueueAlbum
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? coverArt = freezed,Object? albumLoudnessLufs = freezed,Object? albumTruePeakDb = freezed,}) {
  return _then(_SocketQueueAlbum(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,albumLoudnessLufs: freezed == albumLoudnessLufs ? _self.albumLoudnessLufs : albumLoudnessLufs // ignore: cast_nullable_to_non_nullable
as double?,albumTruePeakDb: freezed == albumTruePeakDb ? _self.albumTruePeakDb : albumTruePeakDb // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$SocketQueueEntry {

/// The track title.
 String get title;/// The duration, in seconds.
 double get duration;/// The artist.
 SocketQueueArtist get artist;/// The album.
 SocketQueueAlbum get album;/// The opaque id to stream the track with; null when the server cannot
/// play it.
 String? get playbackId;/// The track's integrated loudness, in LUFS.
 double? get loudnessLufs;/// The track's true peak, in dBTP.
 double? get truePeakDb;
/// Create a copy of SocketQueueEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SocketQueueEntryCopyWith<SocketQueueEntry> get copyWith => _$SocketQueueEntryCopyWithImpl<SocketQueueEntry>(this as SocketQueueEntry, _$identity);

  /// Serializes this SocketQueueEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SocketQueueEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocketQueueEntry&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&(identical(other.album, _this.album) || other.album == _this.album)&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&(identical(other.loudnessLufs, _this.loudnessLufs) || other.loudnessLufs == _this.loudnessLufs)&&(identical(other.truePeakDb, _this.truePeakDb) || other.truePeakDb == _this.truePeakDb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SocketQueueEntry;
  return Object.hash(runtimeType,_this.title,_this.duration,_this.artist,_this.album,_this.playbackId,_this.loudnessLufs,_this.truePeakDb);
}

@override
String toString() {
  final _this = this as SocketQueueEntry;
  return 'SocketQueueEntry(title: ${_this.title}, duration: ${_this.duration}, artist: ${_this.artist}, album: ${_this.album}, playbackId: ${_this.playbackId}, loudnessLufs: ${_this.loudnessLufs}, truePeakDb: ${_this.truePeakDb})';
}


}

/// @nodoc
abstract mixin class $SocketQueueEntryCopyWith<$Res>  {
  factory $SocketQueueEntryCopyWith(SocketQueueEntry value, $Res Function(SocketQueueEntry) _then) = _$SocketQueueEntryCopyWithImpl;
@useResult
$Res call({
 String title, double duration, SocketQueueArtist artist, SocketQueueAlbum album, String? playbackId, double? loudnessLufs, double? truePeakDb
});


$SocketQueueArtistCopyWith<$Res> get artist;$SocketQueueAlbumCopyWith<$Res> get album;

}
/// @nodoc
class _$SocketQueueEntryCopyWithImpl<$Res>
    implements $SocketQueueEntryCopyWith<$Res> {
  _$SocketQueueEntryCopyWithImpl(this._self, this._then);

  final SocketQueueEntry _self;
  final $Res Function(SocketQueueEntry) _then;

/// Create a copy of SocketQueueEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? duration = null,Object? artist = null,Object? album = null,Object? playbackId = freezed,Object? loudnessLufs = freezed,Object? truePeakDb = freezed,}) {
  return _then(SocketQueueEntry(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as SocketQueueArtist,album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as SocketQueueAlbum,playbackId: freezed == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as String?,loudnessLufs: freezed == loudnessLufs ? _self.loudnessLufs : loudnessLufs // ignore: cast_nullable_to_non_nullable
as double?,truePeakDb: freezed == truePeakDb ? _self.truePeakDb : truePeakDb // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}
/// Create a copy of SocketQueueEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SocketQueueArtistCopyWith<$Res> get artist {
  
  return $SocketQueueArtistCopyWith<$Res>(_self.artist, (value) {
    return _then(_self.copyWith(artist: value));
  });
}/// Create a copy of SocketQueueEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SocketQueueAlbumCopyWith<$Res> get album {
  
  return $SocketQueueAlbumCopyWith<$Res>(_self.album, (value) {
    return _then(_self.copyWith(album: value));
  });
}
}


/// Adds pattern-matching-related methods to [SocketQueueEntry].
extension SocketQueueEntryPatterns on SocketQueueEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SocketQueueEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SocketQueueEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SocketQueueEntry value)  $default,){
final _that = this;
switch (_that) {
case _SocketQueueEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SocketQueueEntry value)?  $default,){
final _that = this;
switch (_that) {
case _SocketQueueEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  double duration,  SocketQueueArtist artist,  SocketQueueAlbum album,  String? playbackId,  double? loudnessLufs,  double? truePeakDb)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SocketQueueEntry() when $default != null:
return $default(_that.title,_that.duration,_that.artist,_that.album,_that.playbackId,_that.loudnessLufs,_that.truePeakDb);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  double duration,  SocketQueueArtist artist,  SocketQueueAlbum album,  String? playbackId,  double? loudnessLufs,  double? truePeakDb)  $default,) {final _that = this;
switch (_that) {
case _SocketQueueEntry():
return $default(_that.title,_that.duration,_that.artist,_that.album,_that.playbackId,_that.loudnessLufs,_that.truePeakDb);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  double duration,  SocketQueueArtist artist,  SocketQueueAlbum album,  String? playbackId,  double? loudnessLufs,  double? truePeakDb)?  $default,) {final _that = this;
switch (_that) {
case _SocketQueueEntry() when $default != null:
return $default(_that.title,_that.duration,_that.artist,_that.album,_that.playbackId,_that.loudnessLufs,_that.truePeakDb);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SocketQueueEntry extends SocketQueueEntry {
  const _SocketQueueEntry({required this.title, required this.duration, required this.artist, required this.album, this.playbackId, this.loudnessLufs, this.truePeakDb}): super._();
  factory _SocketQueueEntry.fromJson(Map<String, dynamic> json) => _$SocketQueueEntryFromJson(json);

/// The track title.
@override final  String title;
/// The duration, in seconds.
@override final  double duration;
/// The artist.
@override final  SocketQueueArtist artist;
/// The album.
@override final  SocketQueueAlbum album;
/// The opaque id to stream the track with; null when the server cannot
/// play it.
@override final  String? playbackId;
/// The track's integrated loudness, in LUFS.
@override final  double? loudnessLufs;
/// The track's true peak, in dBTP.
@override final  double? truePeakDb;

/// Create a copy of SocketQueueEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SocketQueueEntryCopyWith<_SocketQueueEntry> get copyWith => __$SocketQueueEntryCopyWithImpl<_SocketQueueEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SocketQueueEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SocketQueueEntry&&(identical(other.title, title) || other.title == title)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.album, album) || other.album == album)&&(identical(other.playbackId, playbackId) || other.playbackId == playbackId)&&(identical(other.loudnessLufs, loudnessLufs) || other.loudnessLufs == loudnessLufs)&&(identical(other.truePeakDb, truePeakDb) || other.truePeakDb == truePeakDb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,duration,artist,album,playbackId,loudnessLufs,truePeakDb);
}

@override
String toString() {
    return 'SocketQueueEntry(title: $title, duration: $duration, artist: $artist, album: $album, playbackId: $playbackId, loudnessLufs: $loudnessLufs, truePeakDb: $truePeakDb)';
}


}

/// @nodoc
abstract mixin class _$SocketQueueEntryCopyWith<$Res> implements $SocketQueueEntryCopyWith<$Res> {
  factory _$SocketQueueEntryCopyWith(_SocketQueueEntry value, $Res Function(_SocketQueueEntry) _then) = __$SocketQueueEntryCopyWithImpl;
@override @useResult
$Res call({
 String title, double duration, SocketQueueArtist artist, SocketQueueAlbum album, String? playbackId, double? loudnessLufs, double? truePeakDb
});


@override $SocketQueueArtistCopyWith<$Res> get artist;@override $SocketQueueAlbumCopyWith<$Res> get album;

}
/// @nodoc
class __$SocketQueueEntryCopyWithImpl<$Res>
    implements _$SocketQueueEntryCopyWith<$Res> {
  __$SocketQueueEntryCopyWithImpl(this._self, this._then);

  final _SocketQueueEntry _self;
  final $Res Function(_SocketQueueEntry) _then;

/// Create a copy of SocketQueueEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? duration = null,Object? artist = null,Object? album = null,Object? playbackId = freezed,Object? loudnessLufs = freezed,Object? truePeakDb = freezed,}) {
  return _then(_SocketQueueEntry(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as double,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as SocketQueueArtist,album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as SocketQueueAlbum,playbackId: freezed == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as String?,loudnessLufs: freezed == loudnessLufs ? _self.loudnessLufs : loudnessLufs // ignore: cast_nullable_to_non_nullable
as double?,truePeakDb: freezed == truePeakDb ? _self.truePeakDb : truePeakDb // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

/// Create a copy of SocketQueueEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SocketQueueArtistCopyWith<$Res> get artist {
  
  return $SocketQueueArtistCopyWith<$Res>(_self.artist, (value) {
    return _then(_self.copyWith(artist: value));
  });
}/// Create a copy of SocketQueueEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SocketQueueAlbumCopyWith<$Res> get album {
  
  return $SocketQueueAlbumCopyWith<$Res>(_self.album, (value) {
    return _then(_self.copyWith(album: value));
  });
}
}


/// @nodoc
mixin _$GroupPlayback {

/// The group's queue.
 List<SocketQueueEntry> get queue;/// The index of the current item.
 int get currentIndex;/// Whether the group is playing.
 bool get isPlaying;/// The position at [serverTime], in milliseconds.
 int get positionMs;/// The server's clock when the state was taken, in milliseconds.
 int get serverTime;/// Grows with every change of the playback state.
 int get stateVersion;
/// Create a copy of GroupPlayback
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupPlaybackCopyWith<GroupPlayback> get copyWith => _$GroupPlaybackCopyWithImpl<GroupPlayback>(this as GroupPlayback, _$identity);

  /// Serializes this GroupPlayback to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GroupPlayback;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupPlayback&&const DeepCollectionEquality().equals(other.queue, _this.queue)&&(identical(other.currentIndex, _this.currentIndex) || other.currentIndex == _this.currentIndex)&&(identical(other.isPlaying, _this.isPlaying) || other.isPlaying == _this.isPlaying)&&(identical(other.positionMs, _this.positionMs) || other.positionMs == _this.positionMs)&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime)&&(identical(other.stateVersion, _this.stateVersion) || other.stateVersion == _this.stateVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GroupPlayback;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.queue),_this.currentIndex,_this.isPlaying,_this.positionMs,_this.serverTime,_this.stateVersion);
}

@override
String toString() {
  final _this = this as GroupPlayback;
  return 'GroupPlayback(queue: ${_this.queue}, currentIndex: ${_this.currentIndex}, isPlaying: ${_this.isPlaying}, positionMs: ${_this.positionMs}, serverTime: ${_this.serverTime}, stateVersion: ${_this.stateVersion})';
}


}

/// @nodoc
abstract mixin class $GroupPlaybackCopyWith<$Res>  {
  factory $GroupPlaybackCopyWith(GroupPlayback value, $Res Function(GroupPlayback) _then) = _$GroupPlaybackCopyWithImpl;
@useResult
$Res call({
 List<SocketQueueEntry> queue, int currentIndex, bool isPlaying, int positionMs, int serverTime, int stateVersion
});




}
/// @nodoc
class _$GroupPlaybackCopyWithImpl<$Res>
    implements $GroupPlaybackCopyWith<$Res> {
  _$GroupPlaybackCopyWithImpl(this._self, this._then);

  final GroupPlayback _self;
  final $Res Function(GroupPlayback) _then;

/// Create a copy of GroupPlayback
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? queue = null,Object? currentIndex = null,Object? isPlaying = null,Object? positionMs = null,Object? serverTime = null,Object? stateVersion = null,}) {
  return _then(GroupPlayback(
queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as List<SocketQueueEntry>,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,positionMs: null == positionMs ? _self.positionMs : positionMs // ignore: cast_nullable_to_non_nullable
as int,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as int,stateVersion: null == stateVersion ? _self.stateVersion : stateVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupPlayback].
extension GroupPlaybackPatterns on GroupPlayback {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupPlayback value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupPlayback() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupPlayback value)  $default,){
final _that = this;
switch (_that) {
case _GroupPlayback():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupPlayback value)?  $default,){
final _that = this;
switch (_that) {
case _GroupPlayback() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SocketQueueEntry> queue,  int currentIndex,  bool isPlaying,  int positionMs,  int serverTime,  int stateVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupPlayback() when $default != null:
return $default(_that.queue,_that.currentIndex,_that.isPlaying,_that.positionMs,_that.serverTime,_that.stateVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SocketQueueEntry> queue,  int currentIndex,  bool isPlaying,  int positionMs,  int serverTime,  int stateVersion)  $default,) {final _that = this;
switch (_that) {
case _GroupPlayback():
return $default(_that.queue,_that.currentIndex,_that.isPlaying,_that.positionMs,_that.serverTime,_that.stateVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SocketQueueEntry> queue,  int currentIndex,  bool isPlaying,  int positionMs,  int serverTime,  int stateVersion)?  $default,) {final _that = this;
switch (_that) {
case _GroupPlayback() when $default != null:
return $default(_that.queue,_that.currentIndex,_that.isPlaying,_that.positionMs,_that.serverTime,_that.stateVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupPlayback implements GroupPlayback {
  const _GroupPlayback({required  List<SocketQueueEntry> queue, required this.currentIndex, required this.isPlaying, required this.positionMs, required this.serverTime, required this.stateVersion}): _queue = queue;
  factory _GroupPlayback.fromJson(Map<String, dynamic> json) => _$GroupPlaybackFromJson(json);

/// The group's queue.
 final  List<SocketQueueEntry> _queue;
/// The group's queue.
@override List<SocketQueueEntry> get queue {
  if (_queue is EqualUnmodifiableListView) return _queue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_queue);
}

/// The index of the current item.
@override final  int currentIndex;
/// Whether the group is playing.
@override final  bool isPlaying;
/// The position at [serverTime], in milliseconds.
@override final  int positionMs;
/// The server's clock when the state was taken, in milliseconds.
@override final  int serverTime;
/// Grows with every change of the playback state.
@override final  int stateVersion;

/// Create a copy of GroupPlayback
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupPlaybackCopyWith<_GroupPlayback> get copyWith => __$GroupPlaybackCopyWithImpl<_GroupPlayback>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupPlaybackToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupPlayback&&const DeepCollectionEquality().equals(other.queue, _queue)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.positionMs, positionMs) || other.positionMs == positionMs)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime)&&(identical(other.stateVersion, stateVersion) || other.stateVersion == stateVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_queue),currentIndex,isPlaying,positionMs,serverTime,stateVersion);
}

@override
String toString() {
    return 'GroupPlayback(queue: $queue, currentIndex: $currentIndex, isPlaying: $isPlaying, positionMs: $positionMs, serverTime: $serverTime, stateVersion: $stateVersion)';
}


}

/// @nodoc
abstract mixin class _$GroupPlaybackCopyWith<$Res> implements $GroupPlaybackCopyWith<$Res> {
  factory _$GroupPlaybackCopyWith(_GroupPlayback value, $Res Function(_GroupPlayback) _then) = __$GroupPlaybackCopyWithImpl;
@override @useResult
$Res call({
 List<SocketQueueEntry> queue, int currentIndex, bool isPlaying, int positionMs, int serverTime, int stateVersion
});




}
/// @nodoc
class __$GroupPlaybackCopyWithImpl<$Res>
    implements _$GroupPlaybackCopyWith<$Res> {
  __$GroupPlaybackCopyWithImpl(this._self, this._then);

  final _GroupPlayback _self;
  final $Res Function(_GroupPlayback) _then;

/// Create a copy of GroupPlayback
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? queue = null,Object? currentIndex = null,Object? isPlaying = null,Object? positionMs = null,Object? serverTime = null,Object? stateVersion = null,}) {
  return _then(_GroupPlayback(
queue: null == queue ? _self._queue : queue // ignore: cast_nullable_to_non_nullable
as List<SocketQueueEntry>,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,positionMs: null == positionMs ? _self.positionMs : positionMs // ignore: cast_nullable_to_non_nullable
as int,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as int,stateVersion: null == stateVersion ? _self.stateVersion : stateVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$GroupMemberInfo {

/// The member's user id.
 String get userId;/// The member's username.
 String get username;/// Whether the member hosts the group.
 bool get isHost;/// When the member joined.
 DateTime get joinedAt;/// Whether the member has a socket in the group.
 bool get isConnected;
/// Create a copy of GroupMemberInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupMemberInfoCopyWith<GroupMemberInfo> get copyWith => _$GroupMemberInfoCopyWithImpl<GroupMemberInfo>(this as GroupMemberInfo, _$identity);

  /// Serializes this GroupMemberInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GroupMemberInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupMemberInfo&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.isHost, _this.isHost) || other.isHost == _this.isHost)&&(identical(other.joinedAt, _this.joinedAt) || other.joinedAt == _this.joinedAt)&&(identical(other.isConnected, _this.isConnected) || other.isConnected == _this.isConnected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GroupMemberInfo;
  return Object.hash(runtimeType,_this.userId,_this.username,_this.isHost,_this.joinedAt,_this.isConnected);
}

@override
String toString() {
  final _this = this as GroupMemberInfo;
  return 'GroupMemberInfo(userId: ${_this.userId}, username: ${_this.username}, isHost: ${_this.isHost}, joinedAt: ${_this.joinedAt}, isConnected: ${_this.isConnected})';
}


}

/// @nodoc
abstract mixin class $GroupMemberInfoCopyWith<$Res>  {
  factory $GroupMemberInfoCopyWith(GroupMemberInfo value, $Res Function(GroupMemberInfo) _then) = _$GroupMemberInfoCopyWithImpl;
@useResult
$Res call({
 String userId, String username, bool isHost, DateTime joinedAt, bool isConnected
});




}
/// @nodoc
class _$GroupMemberInfoCopyWithImpl<$Res>
    implements $GroupMemberInfoCopyWith<$Res> {
  _$GroupMemberInfoCopyWithImpl(this._self, this._then);

  final GroupMemberInfo _self;
  final $Res Function(GroupMemberInfo) _then;

/// Create a copy of GroupMemberInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? username = null,Object? isHost = null,Object? joinedAt = null,Object? isConnected = null,}) {
  return _then(GroupMemberInfo(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isConnected: null == isConnected ? _self.isConnected : isConnected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupMemberInfo].
extension GroupMemberInfoPatterns on GroupMemberInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupMemberInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupMemberInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupMemberInfo value)  $default,){
final _that = this;
switch (_that) {
case _GroupMemberInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupMemberInfo value)?  $default,){
final _that = this;
switch (_that) {
case _GroupMemberInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String username,  bool isHost,  DateTime joinedAt,  bool isConnected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupMemberInfo() when $default != null:
return $default(_that.userId,_that.username,_that.isHost,_that.joinedAt,_that.isConnected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String username,  bool isHost,  DateTime joinedAt,  bool isConnected)  $default,) {final _that = this;
switch (_that) {
case _GroupMemberInfo():
return $default(_that.userId,_that.username,_that.isHost,_that.joinedAt,_that.isConnected);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String username,  bool isHost,  DateTime joinedAt,  bool isConnected)?  $default,) {final _that = this;
switch (_that) {
case _GroupMemberInfo() when $default != null:
return $default(_that.userId,_that.username,_that.isHost,_that.joinedAt,_that.isConnected);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupMemberInfo implements GroupMemberInfo {
  const _GroupMemberInfo({required this.userId, required this.username, required this.isHost, required this.joinedAt, required this.isConnected});
  factory _GroupMemberInfo.fromJson(Map<String, dynamic> json) => _$GroupMemberInfoFromJson(json);

/// The member's user id.
@override final  String userId;
/// The member's username.
@override final  String username;
/// Whether the member hosts the group.
@override final  bool isHost;
/// When the member joined.
@override final  DateTime joinedAt;
/// Whether the member has a socket in the group.
@override final  bool isConnected;

/// Create a copy of GroupMemberInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupMemberInfoCopyWith<_GroupMemberInfo> get copyWith => __$GroupMemberInfoCopyWithImpl<_GroupMemberInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupMemberInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupMemberInfo&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.isConnected, isConnected) || other.isConnected == isConnected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,userId,username,isHost,joinedAt,isConnected);
}

@override
String toString() {
    return 'GroupMemberInfo(userId: $userId, username: $username, isHost: $isHost, joinedAt: $joinedAt, isConnected: $isConnected)';
}


}

/// @nodoc
abstract mixin class _$GroupMemberInfoCopyWith<$Res> implements $GroupMemberInfoCopyWith<$Res> {
  factory _$GroupMemberInfoCopyWith(_GroupMemberInfo value, $Res Function(_GroupMemberInfo) _then) = __$GroupMemberInfoCopyWithImpl;
@override @useResult
$Res call({
 String userId, String username, bool isHost, DateTime joinedAt, bool isConnected
});




}
/// @nodoc
class __$GroupMemberInfoCopyWithImpl<$Res>
    implements _$GroupMemberInfoCopyWith<$Res> {
  __$GroupMemberInfoCopyWithImpl(this._self, this._then);

  final _GroupMemberInfo _self;
  final $Res Function(_GroupMemberInfo) _then;

/// Create a copy of GroupMemberInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? username = null,Object? isHost = null,Object? joinedAt = null,Object? isConnected = null,}) {
  return _then(_GroupMemberInfo(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isConnected: null == isConnected ? _self.isConnected : isConnected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$GroupSnapshot {

/// The group id.
 String get id;/// The group name.
 String get name;/// The code other users join with.
 String get joinCode;/// How the group is controlled.
@JsonKey(unknownEnumValue: GroupType.unknown) GroupType get groupType;/// `public` or `private`.
 String get visibility;/// Whether the group has not ended.
 bool get isActive;/// The host's user id.
 String get hostUserId;/// The group's playback state.
@JsonKey(unknownEnumValue: GroupSyncState.unknown) GroupSyncState get syncState;/// The queue and position.
 GroupPlayback get playback;/// The members.
 List<GroupMemberInfo> get members;
/// Create a copy of GroupSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupSnapshotCopyWith<GroupSnapshot> get copyWith => _$GroupSnapshotCopyWithImpl<GroupSnapshot>(this as GroupSnapshot, _$identity);

  /// Serializes this GroupSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GroupSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupSnapshot&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.joinCode, _this.joinCode) || other.joinCode == _this.joinCode)&&(identical(other.groupType, _this.groupType) || other.groupType == _this.groupType)&&(identical(other.visibility, _this.visibility) || other.visibility == _this.visibility)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive)&&(identical(other.hostUserId, _this.hostUserId) || other.hostUserId == _this.hostUserId)&&(identical(other.syncState, _this.syncState) || other.syncState == _this.syncState)&&(identical(other.playback, _this.playback) || other.playback == _this.playback)&&const DeepCollectionEquality().equals(other.members, _this.members));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GroupSnapshot;
  return Object.hash(runtimeType,_this.id,_this.name,_this.joinCode,_this.groupType,_this.visibility,_this.isActive,_this.hostUserId,_this.syncState,_this.playback,const DeepCollectionEquality().hash(_this.members));
}

@override
String toString() {
  final _this = this as GroupSnapshot;
  return 'GroupSnapshot(id: ${_this.id}, name: ${_this.name}, joinCode: ${_this.joinCode}, groupType: ${_this.groupType}, visibility: ${_this.visibility}, isActive: ${_this.isActive}, hostUserId: ${_this.hostUserId}, syncState: ${_this.syncState}, playback: ${_this.playback}, members: ${_this.members})';
}


}

/// @nodoc
abstract mixin class $GroupSnapshotCopyWith<$Res>  {
  factory $GroupSnapshotCopyWith(GroupSnapshot value, $Res Function(GroupSnapshot) _then) = _$GroupSnapshotCopyWithImpl;
@useResult
$Res call({
 String id, String name, String joinCode,@JsonKey(unknownEnumValue: GroupType.unknown) GroupType groupType, String visibility, bool isActive, String hostUserId,@JsonKey(unknownEnumValue: GroupSyncState.unknown) GroupSyncState syncState, GroupPlayback playback, List<GroupMemberInfo> members
});


$GroupPlaybackCopyWith<$Res> get playback;

}
/// @nodoc
class _$GroupSnapshotCopyWithImpl<$Res>
    implements $GroupSnapshotCopyWith<$Res> {
  _$GroupSnapshotCopyWithImpl(this._self, this._then);

  final GroupSnapshot _self;
  final $Res Function(GroupSnapshot) _then;

/// Create a copy of GroupSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? joinCode = null,Object? groupType = null,Object? visibility = null,Object? isActive = null,Object? hostUserId = null,Object? syncState = null,Object? playback = null,Object? members = null,}) {
  return _then(GroupSnapshot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,joinCode: null == joinCode ? _self.joinCode : joinCode // ignore: cast_nullable_to_non_nullable
as String,groupType: null == groupType ? _self.groupType : groupType // ignore: cast_nullable_to_non_nullable
as GroupType,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,hostUserId: null == hostUserId ? _self.hostUserId : hostUserId // ignore: cast_nullable_to_non_nullable
as String,syncState: null == syncState ? _self.syncState : syncState // ignore: cast_nullable_to_non_nullable
as GroupSyncState,playback: null == playback ? _self.playback : playback // ignore: cast_nullable_to_non_nullable
as GroupPlayback,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<GroupMemberInfo>,
  ));
}
/// Create a copy of GroupSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupPlaybackCopyWith<$Res> get playback {
  
  return $GroupPlaybackCopyWith<$Res>(_self.playback, (value) {
    return _then(_self.copyWith(playback: value));
  });
}
}


/// Adds pattern-matching-related methods to [GroupSnapshot].
extension GroupSnapshotPatterns on GroupSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _GroupSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _GroupSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String joinCode, @JsonKey(unknownEnumValue: GroupType.unknown)  GroupType groupType,  String visibility,  bool isActive,  String hostUserId, @JsonKey(unknownEnumValue: GroupSyncState.unknown)  GroupSyncState syncState,  GroupPlayback playback,  List<GroupMemberInfo> members)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupSnapshot() when $default != null:
return $default(_that.id,_that.name,_that.joinCode,_that.groupType,_that.visibility,_that.isActive,_that.hostUserId,_that.syncState,_that.playback,_that.members);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String joinCode, @JsonKey(unknownEnumValue: GroupType.unknown)  GroupType groupType,  String visibility,  bool isActive,  String hostUserId, @JsonKey(unknownEnumValue: GroupSyncState.unknown)  GroupSyncState syncState,  GroupPlayback playback,  List<GroupMemberInfo> members)  $default,) {final _that = this;
switch (_that) {
case _GroupSnapshot():
return $default(_that.id,_that.name,_that.joinCode,_that.groupType,_that.visibility,_that.isActive,_that.hostUserId,_that.syncState,_that.playback,_that.members);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String joinCode, @JsonKey(unknownEnumValue: GroupType.unknown)  GroupType groupType,  String visibility,  bool isActive,  String hostUserId, @JsonKey(unknownEnumValue: GroupSyncState.unknown)  GroupSyncState syncState,  GroupPlayback playback,  List<GroupMemberInfo> members)?  $default,) {final _that = this;
switch (_that) {
case _GroupSnapshot() when $default != null:
return $default(_that.id,_that.name,_that.joinCode,_that.groupType,_that.visibility,_that.isActive,_that.hostUserId,_that.syncState,_that.playback,_that.members);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupSnapshot implements GroupSnapshot {
  const _GroupSnapshot({required this.id, required this.name, required this.joinCode, @JsonKey(unknownEnumValue: GroupType.unknown) required this.groupType, required this.visibility, required this.isActive, required this.hostUserId, @JsonKey(unknownEnumValue: GroupSyncState.unknown) required this.syncState, required this.playback, required  List<GroupMemberInfo> members}): _members = members;
  factory _GroupSnapshot.fromJson(Map<String, dynamic> json) => _$GroupSnapshotFromJson(json);

/// The group id.
@override final  String id;
/// The group name.
@override final  String name;
/// The code other users join with.
@override final  String joinCode;
/// How the group is controlled.
@override@JsonKey(unknownEnumValue: GroupType.unknown) final  GroupType groupType;
/// `public` or `private`.
@override final  String visibility;
/// Whether the group has not ended.
@override final  bool isActive;
/// The host's user id.
@override final  String hostUserId;
/// The group's playback state.
@override@JsonKey(unknownEnumValue: GroupSyncState.unknown) final  GroupSyncState syncState;
/// The queue and position.
@override final  GroupPlayback playback;
/// The members.
 final  List<GroupMemberInfo> _members;
/// The members.
@override List<GroupMemberInfo> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}


/// Create a copy of GroupSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupSnapshotCopyWith<_GroupSnapshot> get copyWith => __$GroupSnapshotCopyWithImpl<_GroupSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupSnapshot&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.joinCode, joinCode) || other.joinCode == joinCode)&&(identical(other.groupType, groupType) || other.groupType == groupType)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.hostUserId, hostUserId) || other.hostUserId == hostUserId)&&(identical(other.syncState, syncState) || other.syncState == syncState)&&(identical(other.playback, playback) || other.playback == playback)&&const DeepCollectionEquality().equals(other.members, _members));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,joinCode,groupType,visibility,isActive,hostUserId,syncState,playback,const DeepCollectionEquality().hash(_members));
}

@override
String toString() {
    return 'GroupSnapshot(id: $id, name: $name, joinCode: $joinCode, groupType: $groupType, visibility: $visibility, isActive: $isActive, hostUserId: $hostUserId, syncState: $syncState, playback: $playback, members: $members)';
}


}

/// @nodoc
abstract mixin class _$GroupSnapshotCopyWith<$Res> implements $GroupSnapshotCopyWith<$Res> {
  factory _$GroupSnapshotCopyWith(_GroupSnapshot value, $Res Function(_GroupSnapshot) _then) = __$GroupSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String joinCode,@JsonKey(unknownEnumValue: GroupType.unknown) GroupType groupType, String visibility, bool isActive, String hostUserId,@JsonKey(unknownEnumValue: GroupSyncState.unknown) GroupSyncState syncState, GroupPlayback playback, List<GroupMemberInfo> members
});


@override $GroupPlaybackCopyWith<$Res> get playback;

}
/// @nodoc
class __$GroupSnapshotCopyWithImpl<$Res>
    implements _$GroupSnapshotCopyWith<$Res> {
  __$GroupSnapshotCopyWithImpl(this._self, this._then);

  final _GroupSnapshot _self;
  final $Res Function(_GroupSnapshot) _then;

/// Create a copy of GroupSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? joinCode = null,Object? groupType = null,Object? visibility = null,Object? isActive = null,Object? hostUserId = null,Object? syncState = null,Object? playback = null,Object? members = null,}) {
  return _then(_GroupSnapshot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,joinCode: null == joinCode ? _self.joinCode : joinCode // ignore: cast_nullable_to_non_nullable
as String,groupType: null == groupType ? _self.groupType : groupType // ignore: cast_nullable_to_non_nullable
as GroupType,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,hostUserId: null == hostUserId ? _self.hostUserId : hostUserId // ignore: cast_nullable_to_non_nullable
as String,syncState: null == syncState ? _self.syncState : syncState // ignore: cast_nullable_to_non_nullable
as GroupSyncState,playback: null == playback ? _self.playback : playback // ignore: cast_nullable_to_non_nullable
as GroupPlayback,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<GroupMemberInfo>,
  ));
}

/// Create a copy of GroupSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupPlaybackCopyWith<$Res> get playback {
  
  return $GroupPlaybackCopyWith<$Res>(_self.playback, (value) {
    return _then(_self.copyWith(playback: value));
  });
}
}


/// @nodoc
mixin _$PlaybackDelta {

/// Whether the group is playing.
 bool get isPlaying;/// The position at [serverTime], in milliseconds.
 int get positionMs;/// The server's clock when the change was made, in milliseconds.
 int get serverTime;/// Grows with every change of the playback state.
 int get stateVersion;/// The index of the current item.
 int get currentIndex;
/// Create a copy of PlaybackDelta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackDeltaCopyWith<PlaybackDelta> get copyWith => _$PlaybackDeltaCopyWithImpl<PlaybackDelta>(this as PlaybackDelta, _$identity);

  /// Serializes this PlaybackDelta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlaybackDelta;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackDelta&&(identical(other.isPlaying, _this.isPlaying) || other.isPlaying == _this.isPlaying)&&(identical(other.positionMs, _this.positionMs) || other.positionMs == _this.positionMs)&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime)&&(identical(other.stateVersion, _this.stateVersion) || other.stateVersion == _this.stateVersion)&&(identical(other.currentIndex, _this.currentIndex) || other.currentIndex == _this.currentIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlaybackDelta;
  return Object.hash(runtimeType,_this.isPlaying,_this.positionMs,_this.serverTime,_this.stateVersion,_this.currentIndex);
}

@override
String toString() {
  final _this = this as PlaybackDelta;
  return 'PlaybackDelta(isPlaying: ${_this.isPlaying}, positionMs: ${_this.positionMs}, serverTime: ${_this.serverTime}, stateVersion: ${_this.stateVersion}, currentIndex: ${_this.currentIndex})';
}


}

/// @nodoc
abstract mixin class $PlaybackDeltaCopyWith<$Res>  {
  factory $PlaybackDeltaCopyWith(PlaybackDelta value, $Res Function(PlaybackDelta) _then) = _$PlaybackDeltaCopyWithImpl;
@useResult
$Res call({
 bool isPlaying, int positionMs, int serverTime, int stateVersion, int currentIndex
});




}
/// @nodoc
class _$PlaybackDeltaCopyWithImpl<$Res>
    implements $PlaybackDeltaCopyWith<$Res> {
  _$PlaybackDeltaCopyWithImpl(this._self, this._then);

  final PlaybackDelta _self;
  final $Res Function(PlaybackDelta) _then;

/// Create a copy of PlaybackDelta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isPlaying = null,Object? positionMs = null,Object? serverTime = null,Object? stateVersion = null,Object? currentIndex = null,}) {
  return _then(PlaybackDelta(
isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,positionMs: null == positionMs ? _self.positionMs : positionMs // ignore: cast_nullable_to_non_nullable
as int,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as int,stateVersion: null == stateVersion ? _self.stateVersion : stateVersion // ignore: cast_nullable_to_non_nullable
as int,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaybackDelta].
extension PlaybackDeltaPatterns on PlaybackDelta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaybackDelta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaybackDelta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaybackDelta value)  $default,){
final _that = this;
switch (_that) {
case _PlaybackDelta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaybackDelta value)?  $default,){
final _that = this;
switch (_that) {
case _PlaybackDelta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isPlaying,  int positionMs,  int serverTime,  int stateVersion,  int currentIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaybackDelta() when $default != null:
return $default(_that.isPlaying,_that.positionMs,_that.serverTime,_that.stateVersion,_that.currentIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isPlaying,  int positionMs,  int serverTime,  int stateVersion,  int currentIndex)  $default,) {final _that = this;
switch (_that) {
case _PlaybackDelta():
return $default(_that.isPlaying,_that.positionMs,_that.serverTime,_that.stateVersion,_that.currentIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isPlaying,  int positionMs,  int serverTime,  int stateVersion,  int currentIndex)?  $default,) {final _that = this;
switch (_that) {
case _PlaybackDelta() when $default != null:
return $default(_that.isPlaying,_that.positionMs,_that.serverTime,_that.stateVersion,_that.currentIndex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaybackDelta implements PlaybackDelta {
  const _PlaybackDelta({required this.isPlaying, required this.positionMs, required this.serverTime, required this.stateVersion, required this.currentIndex});
  factory _PlaybackDelta.fromJson(Map<String, dynamic> json) => _$PlaybackDeltaFromJson(json);

/// Whether the group is playing.
@override final  bool isPlaying;
/// The position at [serverTime], in milliseconds.
@override final  int positionMs;
/// The server's clock when the change was made, in milliseconds.
@override final  int serverTime;
/// Grows with every change of the playback state.
@override final  int stateVersion;
/// The index of the current item.
@override final  int currentIndex;

/// Create a copy of PlaybackDelta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaybackDeltaCopyWith<_PlaybackDelta> get copyWith => __$PlaybackDeltaCopyWithImpl<_PlaybackDelta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaybackDeltaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaybackDelta&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.positionMs, positionMs) || other.positionMs == positionMs)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime)&&(identical(other.stateVersion, stateVersion) || other.stateVersion == stateVersion)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,isPlaying,positionMs,serverTime,stateVersion,currentIndex);
}

@override
String toString() {
    return 'PlaybackDelta(isPlaying: $isPlaying, positionMs: $positionMs, serverTime: $serverTime, stateVersion: $stateVersion, currentIndex: $currentIndex)';
}


}

/// @nodoc
abstract mixin class _$PlaybackDeltaCopyWith<$Res> implements $PlaybackDeltaCopyWith<$Res> {
  factory _$PlaybackDeltaCopyWith(_PlaybackDelta value, $Res Function(_PlaybackDelta) _then) = __$PlaybackDeltaCopyWithImpl;
@override @useResult
$Res call({
 bool isPlaying, int positionMs, int serverTime, int stateVersion, int currentIndex
});




}
/// @nodoc
class __$PlaybackDeltaCopyWithImpl<$Res>
    implements _$PlaybackDeltaCopyWith<$Res> {
  __$PlaybackDeltaCopyWithImpl(this._self, this._then);

  final _PlaybackDelta _self;
  final $Res Function(_PlaybackDelta) _then;

/// Create a copy of PlaybackDelta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isPlaying = null,Object? positionMs = null,Object? serverTime = null,Object? stateVersion = null,Object? currentIndex = null,}) {
  return _then(_PlaybackDelta(
isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,positionMs: null == positionMs ? _self.positionMs : positionMs // ignore: cast_nullable_to_non_nullable
as int,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as int,stateVersion: null == stateVersion ? _self.stateVersion : stateVersion // ignore: cast_nullable_to_non_nullable
as int,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$QueueDelta {

/// The whole new queue.
 List<SocketQueueEntry> get queue;/// The index of the current item.
 int get currentIndex;/// Grows with every change of the playback state.
 int get stateVersion;
/// Create a copy of QueueDelta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueDeltaCopyWith<QueueDelta> get copyWith => _$QueueDeltaCopyWithImpl<QueueDelta>(this as QueueDelta, _$identity);

  /// Serializes this QueueDelta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as QueueDelta;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueDelta&&const DeepCollectionEquality().equals(other.queue, _this.queue)&&(identical(other.currentIndex, _this.currentIndex) || other.currentIndex == _this.currentIndex)&&(identical(other.stateVersion, _this.stateVersion) || other.stateVersion == _this.stateVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as QueueDelta;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.queue),_this.currentIndex,_this.stateVersion);
}

@override
String toString() {
  final _this = this as QueueDelta;
  return 'QueueDelta(queue: ${_this.queue}, currentIndex: ${_this.currentIndex}, stateVersion: ${_this.stateVersion})';
}


}

/// @nodoc
abstract mixin class $QueueDeltaCopyWith<$Res>  {
  factory $QueueDeltaCopyWith(QueueDelta value, $Res Function(QueueDelta) _then) = _$QueueDeltaCopyWithImpl;
@useResult
$Res call({
 List<SocketQueueEntry> queue, int currentIndex, int stateVersion
});




}
/// @nodoc
class _$QueueDeltaCopyWithImpl<$Res>
    implements $QueueDeltaCopyWith<$Res> {
  _$QueueDeltaCopyWithImpl(this._self, this._then);

  final QueueDelta _self;
  final $Res Function(QueueDelta) _then;

/// Create a copy of QueueDelta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? queue = null,Object? currentIndex = null,Object? stateVersion = null,}) {
  return _then(QueueDelta(
queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as List<SocketQueueEntry>,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,stateVersion: null == stateVersion ? _self.stateVersion : stateVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [QueueDelta].
extension QueueDeltaPatterns on QueueDelta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueueDelta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueueDelta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueueDelta value)  $default,){
final _that = this;
switch (_that) {
case _QueueDelta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueueDelta value)?  $default,){
final _that = this;
switch (_that) {
case _QueueDelta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SocketQueueEntry> queue,  int currentIndex,  int stateVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueueDelta() when $default != null:
return $default(_that.queue,_that.currentIndex,_that.stateVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SocketQueueEntry> queue,  int currentIndex,  int stateVersion)  $default,) {final _that = this;
switch (_that) {
case _QueueDelta():
return $default(_that.queue,_that.currentIndex,_that.stateVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SocketQueueEntry> queue,  int currentIndex,  int stateVersion)?  $default,) {final _that = this;
switch (_that) {
case _QueueDelta() when $default != null:
return $default(_that.queue,_that.currentIndex,_that.stateVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QueueDelta implements QueueDelta {
  const _QueueDelta({required  List<SocketQueueEntry> queue, required this.currentIndex, required this.stateVersion}): _queue = queue;
  factory _QueueDelta.fromJson(Map<String, dynamic> json) => _$QueueDeltaFromJson(json);

/// The whole new queue.
 final  List<SocketQueueEntry> _queue;
/// The whole new queue.
@override List<SocketQueueEntry> get queue {
  if (_queue is EqualUnmodifiableListView) return _queue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_queue);
}

/// The index of the current item.
@override final  int currentIndex;
/// Grows with every change of the playback state.
@override final  int stateVersion;

/// Create a copy of QueueDelta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueDeltaCopyWith<_QueueDelta> get copyWith => __$QueueDeltaCopyWithImpl<_QueueDelta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QueueDeltaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueueDelta&&const DeepCollectionEquality().equals(other.queue, _queue)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.stateVersion, stateVersion) || other.stateVersion == stateVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_queue),currentIndex,stateVersion);
}

@override
String toString() {
    return 'QueueDelta(queue: $queue, currentIndex: $currentIndex, stateVersion: $stateVersion)';
}


}

/// @nodoc
abstract mixin class _$QueueDeltaCopyWith<$Res> implements $QueueDeltaCopyWith<$Res> {
  factory _$QueueDeltaCopyWith(_QueueDelta value, $Res Function(_QueueDelta) _then) = __$QueueDeltaCopyWithImpl;
@override @useResult
$Res call({
 List<SocketQueueEntry> queue, int currentIndex, int stateVersion
});




}
/// @nodoc
class __$QueueDeltaCopyWithImpl<$Res>
    implements _$QueueDeltaCopyWith<$Res> {
  __$QueueDeltaCopyWithImpl(this._self, this._then);

  final _QueueDelta _self;
  final $Res Function(_QueueDelta) _then;

/// Create a copy of QueueDelta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? queue = null,Object? currentIndex = null,Object? stateVersion = null,}) {
  return _then(_QueueDelta(
queue: null == queue ? _self._queue : queue // ignore: cast_nullable_to_non_nullable
as List<SocketQueueEntry>,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,stateVersion: null == stateVersion ? _self.stateVersion : stateVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$WaitingEvent {

/// The index of the item to load.
 int get currentIndex;
/// Create a copy of WaitingEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaitingEventCopyWith<WaitingEvent> get copyWith => _$WaitingEventCopyWithImpl<WaitingEvent>(this as WaitingEvent, _$identity);

  /// Serializes this WaitingEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as WaitingEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaitingEvent&&(identical(other.currentIndex, _this.currentIndex) || other.currentIndex == _this.currentIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as WaitingEvent;
  return Object.hash(runtimeType,_this.currentIndex);
}

@override
String toString() {
  final _this = this as WaitingEvent;
  return 'WaitingEvent(currentIndex: ${_this.currentIndex})';
}


}

/// @nodoc
abstract mixin class $WaitingEventCopyWith<$Res>  {
  factory $WaitingEventCopyWith(WaitingEvent value, $Res Function(WaitingEvent) _then) = _$WaitingEventCopyWithImpl;
@useResult
$Res call({
 int currentIndex
});




}
/// @nodoc
class _$WaitingEventCopyWithImpl<$Res>
    implements $WaitingEventCopyWith<$Res> {
  _$WaitingEventCopyWithImpl(this._self, this._then);

  final WaitingEvent _self;
  final $Res Function(WaitingEvent) _then;

/// Create a copy of WaitingEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentIndex = null,}) {
  return _then(WaitingEvent(
currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WaitingEvent].
extension WaitingEventPatterns on WaitingEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaitingEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaitingEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaitingEvent value)  $default,){
final _that = this;
switch (_that) {
case _WaitingEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaitingEvent value)?  $default,){
final _that = this;
switch (_that) {
case _WaitingEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaitingEvent() when $default != null:
return $default(_that.currentIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentIndex)  $default,) {final _that = this;
switch (_that) {
case _WaitingEvent():
return $default(_that.currentIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentIndex)?  $default,) {final _that = this;
switch (_that) {
case _WaitingEvent() when $default != null:
return $default(_that.currentIndex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WaitingEvent implements WaitingEvent {
  const _WaitingEvent({required this.currentIndex});
  factory _WaitingEvent.fromJson(Map<String, dynamic> json) => _$WaitingEventFromJson(json);

/// The index of the item to load.
@override final  int currentIndex;

/// Create a copy of WaitingEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaitingEventCopyWith<_WaitingEvent> get copyWith => __$WaitingEventCopyWithImpl<_WaitingEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WaitingEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaitingEvent&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,currentIndex);
}

@override
String toString() {
    return 'WaitingEvent(currentIndex: $currentIndex)';
}


}

/// @nodoc
abstract mixin class _$WaitingEventCopyWith<$Res> implements $WaitingEventCopyWith<$Res> {
  factory _$WaitingEventCopyWith(_WaitingEvent value, $Res Function(_WaitingEvent) _then) = __$WaitingEventCopyWithImpl;
@override @useResult
$Res call({
 int currentIndex
});




}
/// @nodoc
class __$WaitingEventCopyWithImpl<$Res>
    implements _$WaitingEventCopyWith<$Res> {
  __$WaitingEventCopyWithImpl(this._self, this._then);

  final _WaitingEvent _self;
  final $Res Function(_WaitingEvent) _then;

/// Create a copy of WaitingEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentIndex = null,}) {
  return _then(_WaitingEvent(
currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PlayAtEvent {

/// Where to start, in milliseconds.
 int get positionMs;/// When to start, on the server's clock, in milliseconds.
 int get serverTime;/// Grows with every change of the playback state.
 int get stateVersion;
/// Create a copy of PlayAtEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayAtEventCopyWith<PlayAtEvent> get copyWith => _$PlayAtEventCopyWithImpl<PlayAtEvent>(this as PlayAtEvent, _$identity);

  /// Serializes this PlayAtEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlayAtEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayAtEvent&&(identical(other.positionMs, _this.positionMs) || other.positionMs == _this.positionMs)&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime)&&(identical(other.stateVersion, _this.stateVersion) || other.stateVersion == _this.stateVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlayAtEvent;
  return Object.hash(runtimeType,_this.positionMs,_this.serverTime,_this.stateVersion);
}

@override
String toString() {
  final _this = this as PlayAtEvent;
  return 'PlayAtEvent(positionMs: ${_this.positionMs}, serverTime: ${_this.serverTime}, stateVersion: ${_this.stateVersion})';
}


}

/// @nodoc
abstract mixin class $PlayAtEventCopyWith<$Res>  {
  factory $PlayAtEventCopyWith(PlayAtEvent value, $Res Function(PlayAtEvent) _then) = _$PlayAtEventCopyWithImpl;
@useResult
$Res call({
 int positionMs, int serverTime, int stateVersion
});




}
/// @nodoc
class _$PlayAtEventCopyWithImpl<$Res>
    implements $PlayAtEventCopyWith<$Res> {
  _$PlayAtEventCopyWithImpl(this._self, this._then);

  final PlayAtEvent _self;
  final $Res Function(PlayAtEvent) _then;

/// Create a copy of PlayAtEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? positionMs = null,Object? serverTime = null,Object? stateVersion = null,}) {
  return _then(PlayAtEvent(
positionMs: null == positionMs ? _self.positionMs : positionMs // ignore: cast_nullable_to_non_nullable
as int,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as int,stateVersion: null == stateVersion ? _self.stateVersion : stateVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayAtEvent].
extension PlayAtEventPatterns on PlayAtEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayAtEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayAtEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayAtEvent value)  $default,){
final _that = this;
switch (_that) {
case _PlayAtEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayAtEvent value)?  $default,){
final _that = this;
switch (_that) {
case _PlayAtEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int positionMs,  int serverTime,  int stateVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayAtEvent() when $default != null:
return $default(_that.positionMs,_that.serverTime,_that.stateVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int positionMs,  int serverTime,  int stateVersion)  $default,) {final _that = this;
switch (_that) {
case _PlayAtEvent():
return $default(_that.positionMs,_that.serverTime,_that.stateVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int positionMs,  int serverTime,  int stateVersion)?  $default,) {final _that = this;
switch (_that) {
case _PlayAtEvent() when $default != null:
return $default(_that.positionMs,_that.serverTime,_that.stateVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayAtEvent implements PlayAtEvent {
  const _PlayAtEvent({required this.positionMs, required this.serverTime, required this.stateVersion});
  factory _PlayAtEvent.fromJson(Map<String, dynamic> json) => _$PlayAtEventFromJson(json);

/// Where to start, in milliseconds.
@override final  int positionMs;
/// When to start, on the server's clock, in milliseconds.
@override final  int serverTime;
/// Grows with every change of the playback state.
@override final  int stateVersion;

/// Create a copy of PlayAtEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayAtEventCopyWith<_PlayAtEvent> get copyWith => __$PlayAtEventCopyWithImpl<_PlayAtEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayAtEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayAtEvent&&(identical(other.positionMs, positionMs) || other.positionMs == positionMs)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime)&&(identical(other.stateVersion, stateVersion) || other.stateVersion == stateVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,positionMs,serverTime,stateVersion);
}

@override
String toString() {
    return 'PlayAtEvent(positionMs: $positionMs, serverTime: $serverTime, stateVersion: $stateVersion)';
}


}

/// @nodoc
abstract mixin class _$PlayAtEventCopyWith<$Res> implements $PlayAtEventCopyWith<$Res> {
  factory _$PlayAtEventCopyWith(_PlayAtEvent value, $Res Function(_PlayAtEvent) _then) = __$PlayAtEventCopyWithImpl;
@override @useResult
$Res call({
 int positionMs, int serverTime, int stateVersion
});




}
/// @nodoc
class __$PlayAtEventCopyWithImpl<$Res>
    implements _$PlayAtEventCopyWith<$Res> {
  __$PlayAtEventCopyWithImpl(this._self, this._then);

  final _PlayAtEvent _self;
  final $Res Function(_PlayAtEvent) _then;

/// Create a copy of PlayAtEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? positionMs = null,Object? serverTime = null,Object? stateVersion = null,}) {
  return _then(_PlayAtEvent(
positionMs: null == positionMs ? _self.positionMs : positionMs // ignore: cast_nullable_to_non_nullable
as int,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as int,stateVersion: null == stateVersion ? _self.stateVersion : stateVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

MemberEvent _$MemberEventFromJson(
  Map<String, dynamic> json
) {
        switch (json['event']) {
                  case 'group:member-joined':
          return MemberJoined.fromJson(
            json
          );
                case 'group:member-presence':
          return MemberPresence.fromJson(
            json
          );
                case 'group:member-left':
          return MemberLeft.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'event',
  'MemberEvent',
  'Invalid union type "${json['event']}"!'
);
        }
      
}

/// @nodoc
mixin _$MemberEvent {

/// The group.
 String get groupId;/// The member's user id.
 String get userId;
/// Create a copy of MemberEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberEventCopyWith<MemberEvent> get copyWith => _$MemberEventCopyWithImpl<MemberEvent>(this as MemberEvent, _$identity);

  /// Serializes this MemberEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MemberEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberEvent&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.userId, _this.userId) || other.userId == _this.userId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MemberEvent;
  return Object.hash(runtimeType,_this.groupId,_this.userId);
}

@override
String toString() {
  final _this = this as MemberEvent;
  return 'MemberEvent(groupId: ${_this.groupId}, userId: ${_this.userId})';
}


}

/// @nodoc
abstract mixin class $MemberEventCopyWith<$Res>  {
  factory $MemberEventCopyWith(MemberEvent value, $Res Function(MemberEvent) _then) = _$MemberEventCopyWithImpl;
@useResult
$Res call({
 String groupId, String userId
});




}
/// @nodoc
class _$MemberEventCopyWithImpl<$Res>
    implements $MemberEventCopyWith<$Res> {
  _$MemberEventCopyWithImpl(this._self, this._then);

  final MemberEvent _self;
  final $Res Function(MemberEvent) _then;

/// Create a copy of MemberEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupId = null,Object? userId = null,}) {
  return _then(_self.copyWith(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberEvent].
extension MemberEventPatterns on MemberEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MemberJoined value)?  joined,TResult Function( MemberPresence value)?  presence,TResult Function( MemberLeft value)?  left,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MemberJoined() when joined != null:
return joined(_that);case MemberPresence() when presence != null:
return presence(_that);case MemberLeft() when left != null:
return left(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MemberJoined value)  joined,required TResult Function( MemberPresence value)  presence,required TResult Function( MemberLeft value)  left,}){
final _that = this;
switch (_that) {
case MemberJoined():
return joined(_that);case MemberPresence():
return presence(_that);case MemberLeft():
return left(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MemberJoined value)?  joined,TResult? Function( MemberPresence value)?  presence,TResult? Function( MemberLeft value)?  left,}){
final _that = this;
switch (_that) {
case MemberJoined() when joined != null:
return joined(_that);case MemberPresence() when presence != null:
return presence(_that);case MemberLeft() when left != null:
return left(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String groupId,  String userId,  String username)?  joined,TResult Function( String groupId,  String userId,  bool isConnected)?  presence,TResult Function( String groupId,  String userId,  String username,  String? newHostUserId,  String? newHostUsername)?  left,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MemberJoined() when joined != null:
return joined(_that.groupId,_that.userId,_that.username);case MemberPresence() when presence != null:
return presence(_that.groupId,_that.userId,_that.isConnected);case MemberLeft() when left != null:
return left(_that.groupId,_that.userId,_that.username,_that.newHostUserId,_that.newHostUsername);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String groupId,  String userId,  String username)  joined,required TResult Function( String groupId,  String userId,  bool isConnected)  presence,required TResult Function( String groupId,  String userId,  String username,  String? newHostUserId,  String? newHostUsername)  left,}) {final _that = this;
switch (_that) {
case MemberJoined():
return joined(_that.groupId,_that.userId,_that.username);case MemberPresence():
return presence(_that.groupId,_that.userId,_that.isConnected);case MemberLeft():
return left(_that.groupId,_that.userId,_that.username,_that.newHostUserId,_that.newHostUsername);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String groupId,  String userId,  String username)?  joined,TResult? Function( String groupId,  String userId,  bool isConnected)?  presence,TResult? Function( String groupId,  String userId,  String username,  String? newHostUserId,  String? newHostUsername)?  left,}) {final _that = this;
switch (_that) {
case MemberJoined() when joined != null:
return joined(_that.groupId,_that.userId,_that.username);case MemberPresence() when presence != null:
return presence(_that.groupId,_that.userId,_that.isConnected);case MemberLeft() when left != null:
return left(_that.groupId,_that.userId,_that.username,_that.newHostUserId,_that.newHostUsername);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class MemberJoined implements MemberEvent {
  const MemberJoined({required this.groupId, required this.userId, required this.username,  String? $type}): $type = $type ?? 'group:member-joined';
  factory MemberJoined.fromJson(Map<String, dynamic> json) => _$MemberJoinedFromJson(json);

/// The group.
@override final  String groupId;
/// The member's user id.
@override final  String userId;
/// The member's username.
 final  String username;

@JsonKey(name: 'event')
final String $type;


/// Create a copy of MemberEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberJoinedCopyWith<MemberJoined> get copyWith => _$MemberJoinedCopyWithImpl<MemberJoined>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberJoinedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberJoined&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,groupId,userId,username);
}

@override
String toString() {
    return 'MemberEvent.joined(groupId: $groupId, userId: $userId, username: $username)';
}


}

/// @nodoc
abstract mixin class $MemberJoinedCopyWith<$Res> implements $MemberEventCopyWith<$Res> {
  factory $MemberJoinedCopyWith(MemberJoined value, $Res Function(MemberJoined) _then) = _$MemberJoinedCopyWithImpl;
@override @useResult
$Res call({
 String groupId, String userId, String username
});




}
/// @nodoc
class _$MemberJoinedCopyWithImpl<$Res>
    implements $MemberJoinedCopyWith<$Res> {
  _$MemberJoinedCopyWithImpl(this._self, this._then);

  final MemberJoined _self;
  final $Res Function(MemberJoined) _then;

/// Create a copy of MemberEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupId = null,Object? userId = null,Object? username = null,}) {
  return _then(MemberJoined(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class MemberPresence implements MemberEvent {
  const MemberPresence({required this.groupId, required this.userId, required this.isConnected,  String? $type}): $type = $type ?? 'group:member-presence';
  factory MemberPresence.fromJson(Map<String, dynamic> json) => _$MemberPresenceFromJson(json);

/// The group.
@override final  String groupId;
/// The member's user id.
@override final  String userId;
/// Whether the member has a socket in the group.
 final  bool isConnected;

@JsonKey(name: 'event')
final String $type;


/// Create a copy of MemberEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberPresenceCopyWith<MemberPresence> get copyWith => _$MemberPresenceCopyWithImpl<MemberPresence>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberPresenceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberPresence&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.isConnected, isConnected) || other.isConnected == isConnected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,groupId,userId,isConnected);
}

@override
String toString() {
    return 'MemberEvent.presence(groupId: $groupId, userId: $userId, isConnected: $isConnected)';
}


}

/// @nodoc
abstract mixin class $MemberPresenceCopyWith<$Res> implements $MemberEventCopyWith<$Res> {
  factory $MemberPresenceCopyWith(MemberPresence value, $Res Function(MemberPresence) _then) = _$MemberPresenceCopyWithImpl;
@override @useResult
$Res call({
 String groupId, String userId, bool isConnected
});




}
/// @nodoc
class _$MemberPresenceCopyWithImpl<$Res>
    implements $MemberPresenceCopyWith<$Res> {
  _$MemberPresenceCopyWithImpl(this._self, this._then);

  final MemberPresence _self;
  final $Res Function(MemberPresence) _then;

/// Create a copy of MemberEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupId = null,Object? userId = null,Object? isConnected = null,}) {
  return _then(MemberPresence(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,isConnected: null == isConnected ? _self.isConnected : isConnected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
@JsonSerializable()

class MemberLeft implements MemberEvent {
  const MemberLeft({required this.groupId, required this.userId, required this.username, this.newHostUserId, this.newHostUsername,  String? $type}): $type = $type ?? 'group:member-left';
  factory MemberLeft.fromJson(Map<String, dynamic> json) => _$MemberLeftFromJson(json);

/// The group.
@override final  String groupId;
/// The member's user id.
@override final  String userId;
/// The member's username.
 final  String username;
/// The new host's user id, when the host left.
 final  String? newHostUserId;
/// The new host's username, when the host left.
 final  String? newHostUsername;

@JsonKey(name: 'event')
final String $type;


/// Create a copy of MemberEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberLeftCopyWith<MemberLeft> get copyWith => _$MemberLeftCopyWithImpl<MemberLeft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberLeftToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberLeft&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.newHostUserId, newHostUserId) || other.newHostUserId == newHostUserId)&&(identical(other.newHostUsername, newHostUsername) || other.newHostUsername == newHostUsername));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,groupId,userId,username,newHostUserId,newHostUsername);
}

@override
String toString() {
    return 'MemberEvent.left(groupId: $groupId, userId: $userId, username: $username, newHostUserId: $newHostUserId, newHostUsername: $newHostUsername)';
}


}

/// @nodoc
abstract mixin class $MemberLeftCopyWith<$Res> implements $MemberEventCopyWith<$Res> {
  factory $MemberLeftCopyWith(MemberLeft value, $Res Function(MemberLeft) _then) = _$MemberLeftCopyWithImpl;
@override @useResult
$Res call({
 String groupId, String userId, String username, String? newHostUserId, String? newHostUsername
});




}
/// @nodoc
class _$MemberLeftCopyWithImpl<$Res>
    implements $MemberLeftCopyWith<$Res> {
  _$MemberLeftCopyWithImpl(this._self, this._then);

  final MemberLeft _self;
  final $Res Function(MemberLeft) _then;

/// Create a copy of MemberEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupId = null,Object? userId = null,Object? username = null,Object? newHostUserId = freezed,Object? newHostUsername = freezed,}) {
  return _then(MemberLeft(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,newHostUserId: freezed == newHostUserId ? _self.newHostUserId : newHostUserId // ignore: cast_nullable_to_non_nullable
as String?,newHostUsername: freezed == newHostUsername ? _self.newHostUsername : newHostUsername // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

GroupEnded _$GroupEndedFromJson(
  Map<String, dynamic> json
) {
        switch (json['event']) {
                  case 'group:ended':
          return GroupClosed.fromJson(
            json
          );
                case 'group:membership-revoked':
          return MembershipRevoked.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'event',
  'GroupEnded',
  'Invalid union type "${json['event']}"!'
);
        }
      
}

/// @nodoc
mixin _$GroupEnded {

/// Why the group ended.
 String? get reason;/// The group.
 String? get groupId;
/// Create a copy of GroupEnded
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupEndedCopyWith<GroupEnded> get copyWith => _$GroupEndedCopyWithImpl<GroupEnded>(this as GroupEnded, _$identity);

  /// Serializes this GroupEnded to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GroupEnded;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupEnded&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GroupEnded;
  return Object.hash(runtimeType,_this.reason,_this.groupId);
}

@override
String toString() {
  final _this = this as GroupEnded;
  return 'GroupEnded(reason: ${_this.reason}, groupId: ${_this.groupId})';
}


}

/// @nodoc
abstract mixin class $GroupEndedCopyWith<$Res>  {
  factory $GroupEndedCopyWith(GroupEnded value, $Res Function(GroupEnded) _then) = _$GroupEndedCopyWithImpl;
@useResult
$Res call({
 String? reason, String? groupId
});




}
/// @nodoc
class _$GroupEndedCopyWithImpl<$Res>
    implements $GroupEndedCopyWith<$Res> {
  _$GroupEndedCopyWithImpl(this._self, this._then);

  final GroupEnded _self;
  final $Res Function(GroupEnded) _then;

/// Create a copy of GroupEnded
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reason = freezed,Object? groupId = freezed,}) {
  return _then(_self.copyWith(
reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupEnded].
extension GroupEndedPatterns on GroupEnded {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GroupClosed value)?  ended,TResult Function( MembershipRevoked value)?  revoked,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GroupClosed() when ended != null:
return ended(_that);case MembershipRevoked() when revoked != null:
return revoked(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GroupClosed value)  ended,required TResult Function( MembershipRevoked value)  revoked,}){
final _that = this;
switch (_that) {
case GroupClosed():
return ended(_that);case MembershipRevoked():
return revoked(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GroupClosed value)?  ended,TResult? Function( MembershipRevoked value)?  revoked,}){
final _that = this;
switch (_that) {
case GroupClosed() when ended != null:
return ended(_that);case MembershipRevoked() when revoked != null:
return revoked(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? reason,  String? groupId)?  ended,TResult Function( String? reason,  String? groupId)?  revoked,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GroupClosed() when ended != null:
return ended(_that.reason,_that.groupId);case MembershipRevoked() when revoked != null:
return revoked(_that.reason,_that.groupId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? reason,  String? groupId)  ended,required TResult Function( String? reason,  String? groupId)  revoked,}) {final _that = this;
switch (_that) {
case GroupClosed():
return ended(_that.reason,_that.groupId);case MembershipRevoked():
return revoked(_that.reason,_that.groupId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? reason,  String? groupId)?  ended,TResult? Function( String? reason,  String? groupId)?  revoked,}) {final _that = this;
switch (_that) {
case GroupClosed() when ended != null:
return ended(_that.reason,_that.groupId);case MembershipRevoked() when revoked != null:
return revoked(_that.reason,_that.groupId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class GroupClosed implements GroupEnded {
  const GroupClosed({this.reason, this.groupId,  String? $type}): $type = $type ?? 'group:ended';
  factory GroupClosed.fromJson(Map<String, dynamic> json) => _$GroupClosedFromJson(json);

/// Why the group ended.
@override final  String? reason;
/// The group.
@override final  String? groupId;

@JsonKey(name: 'event')
final String $type;


/// Create a copy of GroupEnded
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupClosedCopyWith<GroupClosed> get copyWith => _$GroupClosedCopyWithImpl<GroupClosed>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupClosedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupClosed&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.groupId, groupId) || other.groupId == groupId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,reason,groupId);
}

@override
String toString() {
    return 'GroupEnded.ended(reason: $reason, groupId: $groupId)';
}


}

/// @nodoc
abstract mixin class $GroupClosedCopyWith<$Res> implements $GroupEndedCopyWith<$Res> {
  factory $GroupClosedCopyWith(GroupClosed value, $Res Function(GroupClosed) _then) = _$GroupClosedCopyWithImpl;
@override @useResult
$Res call({
 String? reason, String? groupId
});




}
/// @nodoc
class _$GroupClosedCopyWithImpl<$Res>
    implements $GroupClosedCopyWith<$Res> {
  _$GroupClosedCopyWithImpl(this._self, this._then);

  final GroupClosed _self;
  final $Res Function(GroupClosed) _then;

/// Create a copy of GroupEnded
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reason = freezed,Object? groupId = freezed,}) {
  return _then(GroupClosed(
reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class MembershipRevoked implements GroupEnded {
  const MembershipRevoked({this.reason, this.groupId,  String? $type}): $type = $type ?? 'group:membership-revoked';
  factory MembershipRevoked.fromJson(Map<String, dynamic> json) => _$MembershipRevokedFromJson(json);

/// Why the membership was revoked.
@override final  String? reason;
/// The group.
@override final  String? groupId;

@JsonKey(name: 'event')
final String $type;


/// Create a copy of GroupEnded
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipRevokedCopyWith<MembershipRevoked> get copyWith => _$MembershipRevokedCopyWithImpl<MembershipRevoked>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MembershipRevokedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MembershipRevoked&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.groupId, groupId) || other.groupId == groupId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,reason,groupId);
}

@override
String toString() {
    return 'GroupEnded.revoked(reason: $reason, groupId: $groupId)';
}


}

/// @nodoc
abstract mixin class $MembershipRevokedCopyWith<$Res> implements $GroupEndedCopyWith<$Res> {
  factory $MembershipRevokedCopyWith(MembershipRevoked value, $Res Function(MembershipRevoked) _then) = _$MembershipRevokedCopyWithImpl;
@override @useResult
$Res call({
 String? reason, String? groupId
});




}
/// @nodoc
class _$MembershipRevokedCopyWithImpl<$Res>
    implements $MembershipRevokedCopyWith<$Res> {
  _$MembershipRevokedCopyWithImpl(this._self, this._then);

  final MembershipRevoked _self;
  final $Res Function(MembershipRevoked) _then;

/// Create a copy of GroupEnded
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reason = freezed,Object? groupId = freezed,}) {
  return _then(MembershipRevoked(
reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PresenceUpdated {

/// The user whose presence changed.
 String get userId;
/// Create a copy of PresenceUpdated
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresenceUpdatedCopyWith<PresenceUpdated> get copyWith => _$PresenceUpdatedCopyWithImpl<PresenceUpdated>(this as PresenceUpdated, _$identity);

  /// Serializes this PresenceUpdated to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PresenceUpdated;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresenceUpdated&&(identical(other.userId, _this.userId) || other.userId == _this.userId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PresenceUpdated;
  return Object.hash(runtimeType,_this.userId);
}

@override
String toString() {
  final _this = this as PresenceUpdated;
  return 'PresenceUpdated(userId: ${_this.userId})';
}


}

/// @nodoc
abstract mixin class $PresenceUpdatedCopyWith<$Res>  {
  factory $PresenceUpdatedCopyWith(PresenceUpdated value, $Res Function(PresenceUpdated) _then) = _$PresenceUpdatedCopyWithImpl;
@useResult
$Res call({
 String userId
});




}
/// @nodoc
class _$PresenceUpdatedCopyWithImpl<$Res>
    implements $PresenceUpdatedCopyWith<$Res> {
  _$PresenceUpdatedCopyWithImpl(this._self, this._then);

  final PresenceUpdated _self;
  final $Res Function(PresenceUpdated) _then;

/// Create a copy of PresenceUpdated
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,}) {
  return _then(PresenceUpdated(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PresenceUpdated].
extension PresenceUpdatedPatterns on PresenceUpdated {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresenceUpdated value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresenceUpdated() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresenceUpdated value)  $default,){
final _that = this;
switch (_that) {
case _PresenceUpdated():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresenceUpdated value)?  $default,){
final _that = this;
switch (_that) {
case _PresenceUpdated() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresenceUpdated() when $default != null:
return $default(_that.userId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId)  $default,) {final _that = this;
switch (_that) {
case _PresenceUpdated():
return $default(_that.userId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId)?  $default,) {final _that = this;
switch (_that) {
case _PresenceUpdated() when $default != null:
return $default(_that.userId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PresenceUpdated implements PresenceUpdated {
  const _PresenceUpdated({required this.userId});
  factory _PresenceUpdated.fromJson(Map<String, dynamic> json) => _$PresenceUpdatedFromJson(json);

/// The user whose presence changed.
@override final  String userId;

/// Create a copy of PresenceUpdated
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresenceUpdatedCopyWith<_PresenceUpdated> get copyWith => __$PresenceUpdatedCopyWithImpl<_PresenceUpdated>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PresenceUpdatedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresenceUpdated&&(identical(other.userId, userId) || other.userId == userId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,userId);
}

@override
String toString() {
    return 'PresenceUpdated(userId: $userId)';
}


}

/// @nodoc
abstract mixin class _$PresenceUpdatedCopyWith<$Res> implements $PresenceUpdatedCopyWith<$Res> {
  factory _$PresenceUpdatedCopyWith(_PresenceUpdated value, $Res Function(_PresenceUpdated) _then) = __$PresenceUpdatedCopyWithImpl;
@override @useResult
$Res call({
 String userId
});




}
/// @nodoc
class __$PresenceUpdatedCopyWithImpl<$Res>
    implements _$PresenceUpdatedCopyWith<$Res> {
  __$PresenceUpdatedCopyWithImpl(this._self, this._then);

  final _PresenceUpdated _self;
  final $Res Function(_PresenceUpdated) _then;

/// Create a copy of PresenceUpdated
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,}) {
  return _then(_PresenceUpdated(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Ack {

/// Whether the server applied the command.
 bool get ok;
/// Create a copy of Ack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AckCopyWith<Ack> get copyWith => _$AckCopyWithImpl<Ack>(this as Ack, _$identity);

  /// Serializes this Ack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Ack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ack&&(identical(other.ok, _this.ok) || other.ok == _this.ok));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Ack;
  return Object.hash(runtimeType,_this.ok);
}

@override
String toString() {
  final _this = this as Ack;
  return 'Ack(ok: ${_this.ok})';
}


}

/// @nodoc
abstract mixin class $AckCopyWith<$Res>  {
  factory $AckCopyWith(Ack value, $Res Function(Ack) _then) = _$AckCopyWithImpl;
@useResult
$Res call({
 bool ok
});




}
/// @nodoc
class _$AckCopyWithImpl<$Res>
    implements $AckCopyWith<$Res> {
  _$AckCopyWithImpl(this._self, this._then);

  final Ack _self;
  final $Res Function(Ack) _then;

/// Create a copy of Ack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ok = null,}) {
  return _then(Ack(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Ack].
extension AckPatterns on Ack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Ack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Ack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Ack value)  $default,){
final _that = this;
switch (_that) {
case _Ack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Ack value)?  $default,){
final _that = this;
switch (_that) {
case _Ack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool ok)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Ack() when $default != null:
return $default(_that.ok);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool ok)  $default,) {final _that = this;
switch (_that) {
case _Ack():
return $default(_that.ok);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool ok)?  $default,) {final _that = this;
switch (_that) {
case _Ack() when $default != null:
return $default(_that.ok);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Ack implements Ack {
  const _Ack({this.ok = false});
  factory _Ack.fromJson(Map<String, dynamic> json) => _$AckFromJson(json);

/// Whether the server applied the command.
@override@JsonKey() final  bool ok;

/// Create a copy of Ack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AckCopyWith<_Ack> get copyWith => __$AckCopyWithImpl<_Ack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AckToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ack&&(identical(other.ok, ok) || other.ok == ok));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,ok);
}

@override
String toString() {
    return 'Ack(ok: $ok)';
}


}

/// @nodoc
abstract mixin class _$AckCopyWith<$Res> implements $AckCopyWith<$Res> {
  factory _$AckCopyWith(_Ack value, $Res Function(_Ack) _then) = __$AckCopyWithImpl;
@override @useResult
$Res call({
 bool ok
});




}
/// @nodoc
class __$AckCopyWithImpl<$Res>
    implements _$AckCopyWith<$Res> {
  __$AckCopyWithImpl(this._self, this._then);

  final _Ack _self;
  final $Res Function(_Ack) _then;

/// Create a copy of Ack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ok = null,}) {
  return _then(_Ack(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$QueueAck {

/// Whether the server applied the command.
 bool get ok;/// How many tracks of an addition were queued.
 int? get acceptedCount;/// How many tracks of an addition were not queued.
 int? get skippedCount;/// Whether the queue limit cut the addition short.
 bool? get truncated;
/// Create a copy of QueueAck
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueAckCopyWith<QueueAck> get copyWith => _$QueueAckCopyWithImpl<QueueAck>(this as QueueAck, _$identity);

  /// Serializes this QueueAck to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as QueueAck;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueAck&&(identical(other.ok, _this.ok) || other.ok == _this.ok)&&(identical(other.acceptedCount, _this.acceptedCount) || other.acceptedCount == _this.acceptedCount)&&(identical(other.skippedCount, _this.skippedCount) || other.skippedCount == _this.skippedCount)&&(identical(other.truncated, _this.truncated) || other.truncated == _this.truncated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as QueueAck;
  return Object.hash(runtimeType,_this.ok,_this.acceptedCount,_this.skippedCount,_this.truncated);
}

@override
String toString() {
  final _this = this as QueueAck;
  return 'QueueAck(ok: ${_this.ok}, acceptedCount: ${_this.acceptedCount}, skippedCount: ${_this.skippedCount}, truncated: ${_this.truncated})';
}


}

/// @nodoc
abstract mixin class $QueueAckCopyWith<$Res>  {
  factory $QueueAckCopyWith(QueueAck value, $Res Function(QueueAck) _then) = _$QueueAckCopyWithImpl;
@useResult
$Res call({
 bool ok, int? acceptedCount, int? skippedCount, bool? truncated
});




}
/// @nodoc
class _$QueueAckCopyWithImpl<$Res>
    implements $QueueAckCopyWith<$Res> {
  _$QueueAckCopyWithImpl(this._self, this._then);

  final QueueAck _self;
  final $Res Function(QueueAck) _then;

/// Create a copy of QueueAck
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ok = null,Object? acceptedCount = freezed,Object? skippedCount = freezed,Object? truncated = freezed,}) {
  return _then(QueueAck(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,acceptedCount: freezed == acceptedCount ? _self.acceptedCount : acceptedCount // ignore: cast_nullable_to_non_nullable
as int?,skippedCount: freezed == skippedCount ? _self.skippedCount : skippedCount // ignore: cast_nullable_to_non_nullable
as int?,truncated: freezed == truncated ? _self.truncated : truncated // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [QueueAck].
extension QueueAckPatterns on QueueAck {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueueAck value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueueAck() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueueAck value)  $default,){
final _that = this;
switch (_that) {
case _QueueAck():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueueAck value)?  $default,){
final _that = this;
switch (_that) {
case _QueueAck() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool ok,  int? acceptedCount,  int? skippedCount,  bool? truncated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueueAck() when $default != null:
return $default(_that.ok,_that.acceptedCount,_that.skippedCount,_that.truncated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool ok,  int? acceptedCount,  int? skippedCount,  bool? truncated)  $default,) {final _that = this;
switch (_that) {
case _QueueAck():
return $default(_that.ok,_that.acceptedCount,_that.skippedCount,_that.truncated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool ok,  int? acceptedCount,  int? skippedCount,  bool? truncated)?  $default,) {final _that = this;
switch (_that) {
case _QueueAck() when $default != null:
return $default(_that.ok,_that.acceptedCount,_that.skippedCount,_that.truncated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QueueAck implements QueueAck {
  const _QueueAck({this.ok = false, this.acceptedCount, this.skippedCount, this.truncated});
  factory _QueueAck.fromJson(Map<String, dynamic> json) => _$QueueAckFromJson(json);

/// Whether the server applied the command.
@override@JsonKey() final  bool ok;
/// How many tracks of an addition were queued.
@override final  int? acceptedCount;
/// How many tracks of an addition were not queued.
@override final  int? skippedCount;
/// Whether the queue limit cut the addition short.
@override final  bool? truncated;

/// Create a copy of QueueAck
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueAckCopyWith<_QueueAck> get copyWith => __$QueueAckCopyWithImpl<_QueueAck>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QueueAckToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueueAck&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.acceptedCount, acceptedCount) || other.acceptedCount == acceptedCount)&&(identical(other.skippedCount, skippedCount) || other.skippedCount == skippedCount)&&(identical(other.truncated, truncated) || other.truncated == truncated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,ok,acceptedCount,skippedCount,truncated);
}

@override
String toString() {
    return 'QueueAck(ok: $ok, acceptedCount: $acceptedCount, skippedCount: $skippedCount, truncated: $truncated)';
}


}

/// @nodoc
abstract mixin class _$QueueAckCopyWith<$Res> implements $QueueAckCopyWith<$Res> {
  factory _$QueueAckCopyWith(_QueueAck value, $Res Function(_QueueAck) _then) = __$QueueAckCopyWithImpl;
@override @useResult
$Res call({
 bool ok, int? acceptedCount, int? skippedCount, bool? truncated
});




}
/// @nodoc
class __$QueueAckCopyWithImpl<$Res>
    implements _$QueueAckCopyWith<$Res> {
  __$QueueAckCopyWithImpl(this._self, this._then);

  final _QueueAck _self;
  final $Res Function(_QueueAck) _then;

/// Create a copy of QueueAck
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ok = null,Object? acceptedCount = freezed,Object? skippedCount = freezed,Object? truncated = freezed,}) {
  return _then(_QueueAck(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,acceptedCount: freezed == acceptedCount ? _self.acceptedCount : acceptedCount // ignore: cast_nullable_to_non_nullable
as int?,skippedCount: freezed == skippedCount ? _self.skippedCount : skippedCount // ignore: cast_nullable_to_non_nullable
as int?,truncated: freezed == truncated ? _self.truncated : truncated // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
