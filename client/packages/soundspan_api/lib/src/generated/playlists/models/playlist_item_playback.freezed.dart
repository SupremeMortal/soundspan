// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist_item_playback.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaylistItemPlayback {


/// Create a copy of PlaylistItemPlayback
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistItemPlaybackCopyWith<PlaylistItemPlayback> get copyWith => _$PlaylistItemPlaybackCopyWithImpl<PlaylistItemPlayback>(this as PlaylistItemPlayback, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlaylistItemPlayback;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistItemPlayback&&(identical(other.isPlayable, _this.isPlayable) || other.isPlayable == _this.isPlayable)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as PlaylistItemPlayback;
  return Object.hash(runtimeType,_this.isPlayable,_this.message,_this.reason,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as PlaylistItemPlayback;
  return 'PlaylistItemPlayback(isPlayable: ${_this.isPlayable}, message: ${_this.message}, reason: ${_this.reason}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $PlaylistItemPlaybackCopyWith<$Res>  {
  factory $PlaylistItemPlaybackCopyWith(PlaylistItemPlayback value, $Res Function(PlaylistItemPlayback) _then) = _$PlaylistItemPlaybackCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) bool isPlayable,@JsonKey(required: true) String? message,@JsonKey(required: true) String? reason,@JsonKey(readValue: PlaylistItemPlayback._extras, fromJson: PlaylistItemPlayback._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$PlaylistItemPlaybackCopyWithImpl<$Res>
    implements $PlaylistItemPlaybackCopyWith<$Res> {
  _$PlaylistItemPlaybackCopyWithImpl(this._self, this._then);

  final PlaylistItemPlayback _self;
  final $Res Function(PlaylistItemPlayback) _then;

/// Create a copy of PlaylistItemPlayback
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isPlayable = null,Object? message = freezed,Object? reason = freezed,Object? additionalProperties = null,}) {
  return _then(PlaylistItemPlayback(
isPlayable: null == isPlayable ? _self.isPlayable : isPlayable // ignore: cast_nullable_to_non_nullable
as bool,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaylistItemPlayback].
extension PlaylistItemPlaybackPatterns on PlaylistItemPlayback {
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
