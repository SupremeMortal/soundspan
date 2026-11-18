// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playback_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaybackMetadata {


/// Create a copy of PlaybackMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackMetadataCopyWith<PlaybackMetadata> get copyWith => _$PlaybackMetadataCopyWithImpl<PlaybackMetadata>(this as PlaybackMetadata, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlaybackMetadata;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackMetadata&&(identical(other.album, _this.album) || other.album == _this.album)&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&(identical(other.artworkUrl, _this.artworkUrl) || other.artworkUrl == _this.artworkUrl)&&(identical(other.durationSec, _this.durationSec) || other.durationSec == _this.durationSec)&&(identical(other.isrc, _this.isrc) || other.isrc == _this.isrc)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as PlaybackMetadata;
  return Object.hash(runtimeType,_this.album,_this.artist,_this.artworkUrl,_this.durationSec,_this.isrc,_this.title,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as PlaybackMetadata;
  return 'PlaybackMetadata(album: ${_this.album}, artist: ${_this.artist}, artworkUrl: ${_this.artworkUrl}, durationSec: ${_this.durationSec}, isrc: ${_this.isrc}, title: ${_this.title}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $PlaybackMetadataCopyWith<$Res>  {
  factory $PlaybackMetadataCopyWith(PlaybackMetadata value, $Res Function(PlaybackMetadata) _then) = _$PlaybackMetadataCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String album,@JsonKey(required: true, disallowNullValue: true) String artist,@JsonKey(disallowNullValue: true, includeIfNull: false) String? artworkUrl,@JsonKey(required: true, disallowNullValue: true, fromJson: PlaybackMetadata._read_durationSec, toJson: PlaybackMetadata._write_durationSec) int durationSec,@JsonKey(disallowNullValue: true, includeIfNull: false) String? isrc,@JsonKey(required: true, disallowNullValue: true) String title,@JsonKey(readValue: PlaybackMetadata._extras, fromJson: PlaybackMetadata._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$PlaybackMetadataCopyWithImpl<$Res>
    implements $PlaybackMetadataCopyWith<$Res> {
  _$PlaybackMetadataCopyWithImpl(this._self, this._then);

  final PlaybackMetadata _self;
  final $Res Function(PlaybackMetadata) _then;

/// Create a copy of PlaybackMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? album = null,Object? artist = null,Object? artworkUrl = freezed,Object? durationSec = null,Object? isrc = freezed,Object? title = null,Object? additionalProperties = null,}) {
  return _then(PlaybackMetadata(
album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,artworkUrl: freezed == artworkUrl ? _self.artworkUrl : artworkUrl // ignore: cast_nullable_to_non_nullable
as String?,durationSec: null == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int,isrc: freezed == isrc ? _self.isrc : isrc // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaybackMetadata].
extension PlaybackMetadataPatterns on PlaybackMetadata {
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
