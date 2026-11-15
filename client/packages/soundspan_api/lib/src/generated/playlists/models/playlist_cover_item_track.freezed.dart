// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist_cover_item_track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaylistCoverItemTrack {


/// Create a copy of PlaylistCoverItemTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistCoverItemTrackCopyWith<PlaylistCoverItemTrack> get copyWith => _$PlaylistCoverItemTrackCopyWithImpl<PlaylistCoverItemTrack>(this as PlaylistCoverItemTrack, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlaylistCoverItemTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistCoverItemTrack&&(identical(other.album, _this.album) || other.album == _this.album)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as PlaylistCoverItemTrack;
  return Object.hash(runtimeType,_this.album,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as PlaylistCoverItemTrack;
  return 'PlaylistCoverItemTrack(album: ${_this.album}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $PlaylistCoverItemTrackCopyWith<$Res>  {
  factory $PlaylistCoverItemTrackCopyWith(PlaylistCoverItemTrack value, $Res Function(PlaylistCoverItemTrack) _then) = _$PlaylistCoverItemTrackCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) PlaylistCoverAlbum album,@JsonKey(readValue: PlaylistCoverItemTrack._extras, fromJson: PlaylistCoverItemTrack._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$PlaylistCoverAlbumCopyWith<$Res> get album;

}
/// @nodoc
class _$PlaylistCoverItemTrackCopyWithImpl<$Res>
    implements $PlaylistCoverItemTrackCopyWith<$Res> {
  _$PlaylistCoverItemTrackCopyWithImpl(this._self, this._then);

  final PlaylistCoverItemTrack _self;
  final $Res Function(PlaylistCoverItemTrack) _then;

/// Create a copy of PlaylistCoverItemTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? album = null,Object? additionalProperties = null,}) {
  return _then(PlaylistCoverItemTrack(
album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as PlaylistCoverAlbum,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of PlaylistCoverItemTrack
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaylistCoverAlbumCopyWith<$Res> get album {
  
  return $PlaylistCoverAlbumCopyWith<$Res>(_self.album, (value) {
    return _then(_self.copyWith(album: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlaylistCoverItemTrack].
extension PlaylistCoverItemTrackPatterns on PlaylistCoverItemTrack {
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
