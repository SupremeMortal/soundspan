// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrackMeta {

/// The track title.
 String get title;/// The artist name; empty when the server sent none.
 String get artist;/// The album title; empty when the server sent none.
 String get album;/// The duration in whole seconds.
 int get durationSec;/// The value to pass to the cover-art endpoint, if any.
 String? get artworkRef;/// The ISRC, if known.
 String? get isrc;
/// Create a copy of TrackMeta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackMetaCopyWith<TrackMeta> get copyWith => _$TrackMetaCopyWithImpl<TrackMeta>(this as TrackMeta, _$identity);

  /// Serializes this TrackMeta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TrackMeta;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackMeta&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&(identical(other.album, _this.album) || other.album == _this.album)&&(identical(other.durationSec, _this.durationSec) || other.durationSec == _this.durationSec)&&(identical(other.artworkRef, _this.artworkRef) || other.artworkRef == _this.artworkRef)&&(identical(other.isrc, _this.isrc) || other.isrc == _this.isrc));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TrackMeta;
  return Object.hash(runtimeType,_this.title,_this.artist,_this.album,_this.durationSec,_this.artworkRef,_this.isrc);
}

@override
String toString() {
  final _this = this as TrackMeta;
  return 'TrackMeta(title: ${_this.title}, artist: ${_this.artist}, album: ${_this.album}, durationSec: ${_this.durationSec}, artworkRef: ${_this.artworkRef}, isrc: ${_this.isrc})';
}


}

/// @nodoc
abstract mixin class $TrackMetaCopyWith<$Res>  {
  factory $TrackMetaCopyWith(TrackMeta value, $Res Function(TrackMeta) _then) = _$TrackMetaCopyWithImpl;
@useResult
$Res call({
 String title, String artist, String album, int durationSec, String? artworkRef, String? isrc
});




}
/// @nodoc
class _$TrackMetaCopyWithImpl<$Res>
    implements $TrackMetaCopyWith<$Res> {
  _$TrackMetaCopyWithImpl(this._self, this._then);

  final TrackMeta _self;
  final $Res Function(TrackMeta) _then;

/// Create a copy of TrackMeta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? artist = null,Object? album = null,Object? durationSec = null,Object? artworkRef = freezed,Object? isrc = freezed,}) {
  return _then(TrackMeta(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String,durationSec: null == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,isrc: freezed == isrc ? _self.isrc : isrc // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrackMeta].
extension TrackMetaPatterns on TrackMeta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackMeta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackMeta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackMeta value)  $default,){
final _that = this;
switch (_that) {
case _TrackMeta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackMeta value)?  $default,){
final _that = this;
switch (_that) {
case _TrackMeta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String artist,  String album,  int durationSec,  String? artworkRef,  String? isrc)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackMeta() when $default != null:
return $default(_that.title,_that.artist,_that.album,_that.durationSec,_that.artworkRef,_that.isrc);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String artist,  String album,  int durationSec,  String? artworkRef,  String? isrc)  $default,) {final _that = this;
switch (_that) {
case _TrackMeta():
return $default(_that.title,_that.artist,_that.album,_that.durationSec,_that.artworkRef,_that.isrc);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String artist,  String album,  int durationSec,  String? artworkRef,  String? isrc)?  $default,) {final _that = this;
switch (_that) {
case _TrackMeta() when $default != null:
return $default(_that.title,_that.artist,_that.album,_that.durationSec,_that.artworkRef,_that.isrc);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrackMeta implements TrackMeta {
  const _TrackMeta({required this.title, required this.artist, required this.album, required this.durationSec, this.artworkRef, this.isrc});
  factory _TrackMeta.fromJson(Map<String, dynamic> json) => _$TrackMetaFromJson(json);

/// The track title.
@override final  String title;
/// The artist name; empty when the server sent none.
@override final  String artist;
/// The album title; empty when the server sent none.
@override final  String album;
/// The duration in whole seconds.
@override final  int durationSec;
/// The value to pass to the cover-art endpoint, if any.
@override final  String? artworkRef;
/// The ISRC, if known.
@override final  String? isrc;

/// Create a copy of TrackMeta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackMetaCopyWith<_TrackMeta> get copyWith => __$TrackMetaCopyWithImpl<_TrackMeta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackMetaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackMeta&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.album, album) || other.album == album)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.artworkRef, artworkRef) || other.artworkRef == artworkRef)&&(identical(other.isrc, isrc) || other.isrc == isrc));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,artist,album,durationSec,artworkRef,isrc);
}

@override
String toString() {
    return 'TrackMeta(title: $title, artist: $artist, album: $album, durationSec: $durationSec, artworkRef: $artworkRef, isrc: $isrc)';
}


}

/// @nodoc
abstract mixin class _$TrackMetaCopyWith<$Res> implements $TrackMetaCopyWith<$Res> {
  factory _$TrackMetaCopyWith(_TrackMeta value, $Res Function(_TrackMeta) _then) = __$TrackMetaCopyWithImpl;
@override @useResult
$Res call({
 String title, String artist, String album, int durationSec, String? artworkRef, String? isrc
});




}
/// @nodoc
class __$TrackMetaCopyWithImpl<$Res>
    implements _$TrackMetaCopyWith<$Res> {
  __$TrackMetaCopyWithImpl(this._self, this._then);

  final _TrackMeta _self;
  final $Res Function(_TrackMeta) _then;

/// Create a copy of TrackMeta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? artist = null,Object? album = null,Object? durationSec = null,Object? artworkRef = freezed,Object? isrc = freezed,}) {
  return _then(_TrackMeta(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String,durationSec: null == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,isrc: freezed == isrc ? _self.isrc : isrc // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Loudness {

/// Integrated loudness of the track, in LUFS.
 double? get loudnessLufs;/// True peak of the track, in dBTP.
 double? get truePeakDb;/// Integrated loudness of the track's album, in LUFS.
 double? get albumLoudnessLufs;/// True peak of the track's album, in dBTP.
 double? get albumTruePeakDb;
/// Create a copy of Loudness
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoudnessCopyWith<Loudness> get copyWith => _$LoudnessCopyWithImpl<Loudness>(this as Loudness, _$identity);

  /// Serializes this Loudness to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Loudness;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Loudness&&(identical(other.loudnessLufs, _this.loudnessLufs) || other.loudnessLufs == _this.loudnessLufs)&&(identical(other.truePeakDb, _this.truePeakDb) || other.truePeakDb == _this.truePeakDb)&&(identical(other.albumLoudnessLufs, _this.albumLoudnessLufs) || other.albumLoudnessLufs == _this.albumLoudnessLufs)&&(identical(other.albumTruePeakDb, _this.albumTruePeakDb) || other.albumTruePeakDb == _this.albumTruePeakDb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Loudness;
  return Object.hash(runtimeType,_this.loudnessLufs,_this.truePeakDb,_this.albumLoudnessLufs,_this.albumTruePeakDb);
}

@override
String toString() {
  final _this = this as Loudness;
  return 'Loudness(loudnessLufs: ${_this.loudnessLufs}, truePeakDb: ${_this.truePeakDb}, albumLoudnessLufs: ${_this.albumLoudnessLufs}, albumTruePeakDb: ${_this.albumTruePeakDb})';
}


}

/// @nodoc
abstract mixin class $LoudnessCopyWith<$Res>  {
  factory $LoudnessCopyWith(Loudness value, $Res Function(Loudness) _then) = _$LoudnessCopyWithImpl;
@useResult
$Res call({
 double? loudnessLufs, double? truePeakDb, double? albumLoudnessLufs, double? albumTruePeakDb
});




}
/// @nodoc
class _$LoudnessCopyWithImpl<$Res>
    implements $LoudnessCopyWith<$Res> {
  _$LoudnessCopyWithImpl(this._self, this._then);

  final Loudness _self;
  final $Res Function(Loudness) _then;

/// Create a copy of Loudness
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loudnessLufs = freezed,Object? truePeakDb = freezed,Object? albumLoudnessLufs = freezed,Object? albumTruePeakDb = freezed,}) {
  return _then(Loudness(
loudnessLufs: freezed == loudnessLufs ? _self.loudnessLufs : loudnessLufs // ignore: cast_nullable_to_non_nullable
as double?,truePeakDb: freezed == truePeakDb ? _self.truePeakDb : truePeakDb // ignore: cast_nullable_to_non_nullable
as double?,albumLoudnessLufs: freezed == albumLoudnessLufs ? _self.albumLoudnessLufs : albumLoudnessLufs // ignore: cast_nullable_to_non_nullable
as double?,albumTruePeakDb: freezed == albumTruePeakDb ? _self.albumTruePeakDb : albumTruePeakDb // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [Loudness].
extension LoudnessPatterns on Loudness {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Loudness value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Loudness() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Loudness value)  $default,){
final _that = this;
switch (_that) {
case _Loudness():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Loudness value)?  $default,){
final _that = this;
switch (_that) {
case _Loudness() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? loudnessLufs,  double? truePeakDb,  double? albumLoudnessLufs,  double? albumTruePeakDb)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Loudness() when $default != null:
return $default(_that.loudnessLufs,_that.truePeakDb,_that.albumLoudnessLufs,_that.albumTruePeakDb);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? loudnessLufs,  double? truePeakDb,  double? albumLoudnessLufs,  double? albumTruePeakDb)  $default,) {final _that = this;
switch (_that) {
case _Loudness():
return $default(_that.loudnessLufs,_that.truePeakDb,_that.albumLoudnessLufs,_that.albumTruePeakDb);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? loudnessLufs,  double? truePeakDb,  double? albumLoudnessLufs,  double? albumTruePeakDb)?  $default,) {final _that = this;
switch (_that) {
case _Loudness() when $default != null:
return $default(_that.loudnessLufs,_that.truePeakDb,_that.albumLoudnessLufs,_that.albumTruePeakDb);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Loudness implements Loudness {
  const _Loudness({this.loudnessLufs, this.truePeakDb, this.albumLoudnessLufs, this.albumTruePeakDb});
  factory _Loudness.fromJson(Map<String, dynamic> json) => _$LoudnessFromJson(json);

/// Integrated loudness of the track, in LUFS.
@override final  double? loudnessLufs;
/// True peak of the track, in dBTP.
@override final  double? truePeakDb;
/// Integrated loudness of the track's album, in LUFS.
@override final  double? albumLoudnessLufs;
/// True peak of the track's album, in dBTP.
@override final  double? albumTruePeakDb;

/// Create a copy of Loudness
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoudnessCopyWith<_Loudness> get copyWith => __$LoudnessCopyWithImpl<_Loudness>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LoudnessToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loudness&&(identical(other.loudnessLufs, loudnessLufs) || other.loudnessLufs == loudnessLufs)&&(identical(other.truePeakDb, truePeakDb) || other.truePeakDb == truePeakDb)&&(identical(other.albumLoudnessLufs, albumLoudnessLufs) || other.albumLoudnessLufs == albumLoudnessLufs)&&(identical(other.albumTruePeakDb, albumTruePeakDb) || other.albumTruePeakDb == albumTruePeakDb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,loudnessLufs,truePeakDb,albumLoudnessLufs,albumTruePeakDb);
}

@override
String toString() {
    return 'Loudness(loudnessLufs: $loudnessLufs, truePeakDb: $truePeakDb, albumLoudnessLufs: $albumLoudnessLufs, albumTruePeakDb: $albumTruePeakDb)';
}


}

/// @nodoc
abstract mixin class _$LoudnessCopyWith<$Res> implements $LoudnessCopyWith<$Res> {
  factory _$LoudnessCopyWith(_Loudness value, $Res Function(_Loudness) _then) = __$LoudnessCopyWithImpl;
@override @useResult
$Res call({
 double? loudnessLufs, double? truePeakDb, double? albumLoudnessLufs, double? albumTruePeakDb
});




}
/// @nodoc
class __$LoudnessCopyWithImpl<$Res>
    implements _$LoudnessCopyWith<$Res> {
  __$LoudnessCopyWithImpl(this._self, this._then);

  final _Loudness _self;
  final $Res Function(_Loudness) _then;

/// Create a copy of Loudness
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? loudnessLufs = freezed,Object? truePeakDb = freezed,Object? albumLoudnessLufs = freezed,Object? albumTruePeakDb = freezed,}) {
  return _then(_Loudness(
loudnessLufs: freezed == loudnessLufs ? _self.loudnessLufs : loudnessLufs // ignore: cast_nullable_to_non_nullable
as double?,truePeakDb: freezed == truePeakDb ? _self.truePeakDb : truePeakDb // ignore: cast_nullable_to_non_nullable
as double?,albumLoudnessLufs: freezed == albumLoudnessLufs ? _self.albumLoudnessLufs : albumLoudnessLufs // ignore: cast_nullable_to_non_nullable
as double?,albumTruePeakDb: freezed == albumTruePeakDb ? _self.albumTruePeakDb : albumTruePeakDb // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$Track {

/// What is shown and sent back as `metadata`.
 TrackMeta get meta;/// The id to play the track by; null means not playable, and the row is
/// shown disabled.
@PlaybackIdConverter() PlaybackId? get playbackId;/// The library album id, if any.
 String? get albumId;/// The library artist id, if any.
 String? get artistId;/// Loudness values, if the server sent any.
 Loudness? get loudness;/// The user's preference.
 Preference get preference;/// The disc number, if known.
 int? get discNumber;/// The track number on its disc, if known.
 int? get trackNumber;/// The track id the server sent on the payload, for lyrics and vibe
/// lookups. It says nothing about where the track comes from and is
/// never used to decide playability or to branch.
 String? get libraryTrackId;
/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackCopyWith<Track> get copyWith => _$TrackCopyWithImpl<Track>(this as Track, _$identity);

  /// Serializes this Track to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Track;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Track&&(identical(other.meta, _this.meta) || other.meta == _this.meta)&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&(identical(other.albumId, _this.albumId) || other.albumId == _this.albumId)&&(identical(other.artistId, _this.artistId) || other.artistId == _this.artistId)&&(identical(other.loudness, _this.loudness) || other.loudness == _this.loudness)&&(identical(other.preference, _this.preference) || other.preference == _this.preference)&&(identical(other.discNumber, _this.discNumber) || other.discNumber == _this.discNumber)&&(identical(other.trackNumber, _this.trackNumber) || other.trackNumber == _this.trackNumber)&&(identical(other.libraryTrackId, _this.libraryTrackId) || other.libraryTrackId == _this.libraryTrackId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Track;
  return Object.hash(runtimeType,_this.meta,_this.playbackId,_this.albumId,_this.artistId,_this.loudness,_this.preference,_this.discNumber,_this.trackNumber,_this.libraryTrackId);
}

@override
String toString() {
  final _this = this as Track;
  return 'Track(meta: ${_this.meta}, playbackId: ${_this.playbackId}, albumId: ${_this.albumId}, artistId: ${_this.artistId}, loudness: ${_this.loudness}, preference: ${_this.preference}, discNumber: ${_this.discNumber}, trackNumber: ${_this.trackNumber}, libraryTrackId: ${_this.libraryTrackId})';
}


}

/// @nodoc
abstract mixin class $TrackCopyWith<$Res>  {
  factory $TrackCopyWith(Track value, $Res Function(Track) _then) = _$TrackCopyWithImpl;
@useResult
$Res call({
 TrackMeta meta,@PlaybackIdConverter() PlaybackId? playbackId, String? albumId, String? artistId, Loudness? loudness, Preference preference, int? discNumber, int? trackNumber, String? libraryTrackId
});


$TrackMetaCopyWith<$Res> get meta;$LoudnessCopyWith<$Res>? get loudness;

}
/// @nodoc
class _$TrackCopyWithImpl<$Res>
    implements $TrackCopyWith<$Res> {
  _$TrackCopyWithImpl(this._self, this._then);

  final Track _self;
  final $Res Function(Track) _then;

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? meta = null,Object? playbackId = freezed,Object? albumId = freezed,Object? artistId = freezed,Object? loudness = freezed,Object? preference = null,Object? discNumber = freezed,Object? trackNumber = freezed,Object? libraryTrackId = freezed,}) {
  return _then(Track(
meta: null == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as TrackMeta,playbackId: freezed == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as PlaybackId?,albumId: freezed == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String?,artistId: freezed == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String?,loudness: freezed == loudness ? _self.loudness : loudness // ignore: cast_nullable_to_non_nullable
as Loudness?,preference: null == preference ? _self.preference : preference // ignore: cast_nullable_to_non_nullable
as Preference,discNumber: freezed == discNumber ? _self.discNumber : discNumber // ignore: cast_nullable_to_non_nullable
as int?,trackNumber: freezed == trackNumber ? _self.trackNumber : trackNumber // ignore: cast_nullable_to_non_nullable
as int?,libraryTrackId: freezed == libraryTrackId ? _self.libraryTrackId : libraryTrackId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackMetaCopyWith<$Res> get meta {
  
  return $TrackMetaCopyWith<$Res>(_self.meta, (value) {
    return _then(_self.copyWith(meta: value));
  });
}/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LoudnessCopyWith<$Res>? get loudness {
    if (_self.loudness == null) {
    return null;
  }

  return $LoudnessCopyWith<$Res>(_self.loudness!, (value) {
    return _then(_self.copyWith(loudness: value));
  });
}
}


/// Adds pattern-matching-related methods to [Track].
extension TrackPatterns on Track {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Track value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Track() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Track value)  $default,){
final _that = this;
switch (_that) {
case _Track():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Track value)?  $default,){
final _that = this;
switch (_that) {
case _Track() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TrackMeta meta, @PlaybackIdConverter()  PlaybackId? playbackId,  String? albumId,  String? artistId,  Loudness? loudness,  Preference preference,  int? discNumber,  int? trackNumber,  String? libraryTrackId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Track() when $default != null:
return $default(_that.meta,_that.playbackId,_that.albumId,_that.artistId,_that.loudness,_that.preference,_that.discNumber,_that.trackNumber,_that.libraryTrackId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TrackMeta meta, @PlaybackIdConverter()  PlaybackId? playbackId,  String? albumId,  String? artistId,  Loudness? loudness,  Preference preference,  int? discNumber,  int? trackNumber,  String? libraryTrackId)  $default,) {final _that = this;
switch (_that) {
case _Track():
return $default(_that.meta,_that.playbackId,_that.albumId,_that.artistId,_that.loudness,_that.preference,_that.discNumber,_that.trackNumber,_that.libraryTrackId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TrackMeta meta, @PlaybackIdConverter()  PlaybackId? playbackId,  String? albumId,  String? artistId,  Loudness? loudness,  Preference preference,  int? discNumber,  int? trackNumber,  String? libraryTrackId)?  $default,) {final _that = this;
switch (_that) {
case _Track() when $default != null:
return $default(_that.meta,_that.playbackId,_that.albumId,_that.artistId,_that.loudness,_that.preference,_that.discNumber,_that.trackNumber,_that.libraryTrackId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Track implements Track {
  const _Track({required this.meta, @PlaybackIdConverter() this.playbackId, this.albumId, this.artistId, this.loudness, this.preference = Preference.neutral, this.discNumber, this.trackNumber, this.libraryTrackId});
  factory _Track.fromJson(Map<String, dynamic> json) => _$TrackFromJson(json);

/// What is shown and sent back as `metadata`.
@override final  TrackMeta meta;
/// The id to play the track by; null means not playable, and the row is
/// shown disabled.
@override@PlaybackIdConverter() final  PlaybackId? playbackId;
/// The library album id, if any.
@override final  String? albumId;
/// The library artist id, if any.
@override final  String? artistId;
/// Loudness values, if the server sent any.
@override final  Loudness? loudness;
/// The user's preference.
@override@JsonKey() final  Preference preference;
/// The disc number, if known.
@override final  int? discNumber;
/// The track number on its disc, if known.
@override final  int? trackNumber;
/// The track id the server sent on the payload, for lyrics and vibe
/// lookups. It says nothing about where the track comes from and is
/// never used to decide playability or to branch.
@override final  String? libraryTrackId;

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackCopyWith<_Track> get copyWith => __$TrackCopyWithImpl<_Track>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Track&&(identical(other.meta, meta) || other.meta == meta)&&(identical(other.playbackId, playbackId) || other.playbackId == playbackId)&&(identical(other.albumId, albumId) || other.albumId == albumId)&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.loudness, loudness) || other.loudness == loudness)&&(identical(other.preference, preference) || other.preference == preference)&&(identical(other.discNumber, discNumber) || other.discNumber == discNumber)&&(identical(other.trackNumber, trackNumber) || other.trackNumber == trackNumber)&&(identical(other.libraryTrackId, libraryTrackId) || other.libraryTrackId == libraryTrackId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,meta,playbackId,albumId,artistId,loudness,preference,discNumber,trackNumber,libraryTrackId);
}

@override
String toString() {
    return 'Track(meta: $meta, playbackId: $playbackId, albumId: $albumId, artistId: $artistId, loudness: $loudness, preference: $preference, discNumber: $discNumber, trackNumber: $trackNumber, libraryTrackId: $libraryTrackId)';
}


}

/// @nodoc
abstract mixin class _$TrackCopyWith<$Res> implements $TrackCopyWith<$Res> {
  factory _$TrackCopyWith(_Track value, $Res Function(_Track) _then) = __$TrackCopyWithImpl;
@override @useResult
$Res call({
 TrackMeta meta,@PlaybackIdConverter() PlaybackId? playbackId, String? albumId, String? artistId, Loudness? loudness, Preference preference, int? discNumber, int? trackNumber, String? libraryTrackId
});


@override $TrackMetaCopyWith<$Res> get meta;@override $LoudnessCopyWith<$Res>? get loudness;

}
/// @nodoc
class __$TrackCopyWithImpl<$Res>
    implements _$TrackCopyWith<$Res> {
  __$TrackCopyWithImpl(this._self, this._then);

  final _Track _self;
  final $Res Function(_Track) _then;

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? meta = null,Object? playbackId = freezed,Object? albumId = freezed,Object? artistId = freezed,Object? loudness = freezed,Object? preference = null,Object? discNumber = freezed,Object? trackNumber = freezed,Object? libraryTrackId = freezed,}) {
  return _then(_Track(
meta: null == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as TrackMeta,playbackId: freezed == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as PlaybackId?,albumId: freezed == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String?,artistId: freezed == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String?,loudness: freezed == loudness ? _self.loudness : loudness // ignore: cast_nullable_to_non_nullable
as Loudness?,preference: null == preference ? _self.preference : preference // ignore: cast_nullable_to_non_nullable
as Preference,discNumber: freezed == discNumber ? _self.discNumber : discNumber // ignore: cast_nullable_to_non_nullable
as int?,trackNumber: freezed == trackNumber ? _self.trackNumber : trackNumber // ignore: cast_nullable_to_non_nullable
as int?,libraryTrackId: freezed == libraryTrackId ? _self.libraryTrackId : libraryTrackId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackMetaCopyWith<$Res> get meta {
  
  return $TrackMetaCopyWith<$Res>(_self.meta, (value) {
    return _then(_self.copyWith(meta: value));
  });
}/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LoudnessCopyWith<$Res>? get loudness {
    if (_self.loudness == null) {
    return null;
  }

  return $LoudnessCopyWith<$Res>(_self.loudness!, (value) {
    return _then(_self.copyWith(loudness: value));
  });
}
}

// dart format on
