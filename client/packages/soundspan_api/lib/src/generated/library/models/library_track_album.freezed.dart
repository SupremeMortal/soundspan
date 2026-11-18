// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_track_album.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LibraryTrackAlbum {


/// Create a copy of LibraryTrackAlbum
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryTrackAlbumCopyWith<LibraryTrackAlbum> get copyWith => _$LibraryTrackAlbumCopyWithImpl<LibraryTrackAlbum>(this as LibraryTrackAlbum, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LibraryTrackAlbum;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryTrackAlbum&&(identical(other.albumLoudnessLufs, _this.albumLoudnessLufs) || other.albumLoudnessLufs == _this.albumLoudnessLufs)&&(identical(other.albumTruePeakDb, _this.albumTruePeakDb) || other.albumTruePeakDb == _this.albumTruePeakDb)&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&(identical(other.coverArt, _this.coverArt) || other.coverArt == _this.coverArt)&&(identical(other.coverUrl, _this.coverUrl) || other.coverUrl == _this.coverUrl)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.matchedInLibrary, _this.matchedInLibrary) || other.matchedInLibrary == _this.matchedInLibrary)&&(identical(other.matchedRgMbid, _this.matchedRgMbid) || other.matchedRgMbid == _this.matchedRgMbid)&&(identical(other.rgMbid, _this.rgMbid) || other.rgMbid == _this.rgMbid)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as LibraryTrackAlbum;
  return Object.hash(runtimeType,_this.albumLoudnessLufs,_this.albumTruePeakDb,_this.artist,_this.coverArt,_this.coverUrl,_this.id,_this.matchedInLibrary,_this.matchedRgMbid,_this.rgMbid,_this.title,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as LibraryTrackAlbum;
  return 'LibraryTrackAlbum(albumLoudnessLufs: ${_this.albumLoudnessLufs}, albumTruePeakDb: ${_this.albumTruePeakDb}, artist: ${_this.artist}, coverArt: ${_this.coverArt}, coverUrl: ${_this.coverUrl}, id: ${_this.id}, matchedInLibrary: ${_this.matchedInLibrary}, matchedRgMbid: ${_this.matchedRgMbid}, rgMbid: ${_this.rgMbid}, title: ${_this.title}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $LibraryTrackAlbumCopyWith<$Res>  {
  factory $LibraryTrackAlbumCopyWith(LibraryTrackAlbum value, $Res Function(LibraryTrackAlbum) _then) = _$LibraryTrackAlbumCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) num? albumLoudnessLufs,@JsonKey(includeIfNull: false) num? albumTruePeakDb,@JsonKey(disallowNullValue: true, includeIfNull: false) LibraryTrackArtist? artist,@JsonKey(required: true) String? coverArt,@JsonKey(includeIfNull: false) String? coverUrl,@JsonKey(required: true) String? id,@JsonKey(disallowNullValue: true, includeIfNull: false) bool? matchedInLibrary,@JsonKey(includeIfNull: false) String? matchedRgMbid,@JsonKey(includeIfNull: false) String? rgMbid,@JsonKey(required: true, disallowNullValue: true) String title,@JsonKey(readValue: LibraryTrackAlbum._extras, fromJson: LibraryTrackAlbum._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$LibraryTrackArtistCopyWith<$Res>? get artist;

}
/// @nodoc
class _$LibraryTrackAlbumCopyWithImpl<$Res>
    implements $LibraryTrackAlbumCopyWith<$Res> {
  _$LibraryTrackAlbumCopyWithImpl(this._self, this._then);

  final LibraryTrackAlbum _self;
  final $Res Function(LibraryTrackAlbum) _then;

/// Create a copy of LibraryTrackAlbum
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? albumLoudnessLufs = freezed,Object? albumTruePeakDb = freezed,Object? artist = freezed,Object? coverArt = freezed,Object? coverUrl = freezed,Object? id = freezed,Object? matchedInLibrary = freezed,Object? matchedRgMbid = freezed,Object? rgMbid = freezed,Object? title = null,Object? additionalProperties = null,}) {
  return _then(LibraryTrackAlbum(
albumLoudnessLufs: freezed == albumLoudnessLufs ? _self.albumLoudnessLufs : albumLoudnessLufs // ignore: cast_nullable_to_non_nullable
as num?,albumTruePeakDb: freezed == albumTruePeakDb ? _self.albumTruePeakDb : albumTruePeakDb // ignore: cast_nullable_to_non_nullable
as num?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as LibraryTrackArtist?,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,matchedInLibrary: freezed == matchedInLibrary ? _self.matchedInLibrary : matchedInLibrary // ignore: cast_nullable_to_non_nullable
as bool?,matchedRgMbid: freezed == matchedRgMbid ? _self.matchedRgMbid : matchedRgMbid // ignore: cast_nullable_to_non_nullable
as String?,rgMbid: freezed == rgMbid ? _self.rgMbid : rgMbid // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of LibraryTrackAlbum
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LibraryTrackArtistCopyWith<$Res>? get artist {
    if (_self.artist == null) {
    return null;
  }

  return $LibraryTrackArtistCopyWith<$Res>(_self.artist!, (value) {
    return _then(_self.copyWith(artist: value));
  });
}
}


/// Adds pattern-matching-related methods to [LibraryTrackAlbum].
extension LibraryTrackAlbumPatterns on LibraryTrackAlbum {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

// dart format on
