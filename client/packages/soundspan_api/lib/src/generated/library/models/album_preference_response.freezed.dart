// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'album_preference_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AlbumPreferenceResponse {


/// Create a copy of AlbumPreferenceResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlbumPreferenceResponseCopyWith<AlbumPreferenceResponse> get copyWith => _$AlbumPreferenceResponseCopyWithImpl<AlbumPreferenceResponse>(this as AlbumPreferenceResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AlbumPreferenceResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlbumPreferenceResponse&&(identical(other.albumId, _this.albumId) || other.albumId == _this.albumId)&&(identical(other.dislikedAt, _this.dislikedAt) || other.dislikedAt == _this.dislikedAt)&&(identical(other.likedAt, _this.likedAt) || other.likedAt == _this.likedAt)&&(identical(other.score, _this.score) || other.score == _this.score)&&(identical(other.signal, _this.signal) || other.signal == _this.signal)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.trackCount, _this.trackCount) || other.trackCount == _this.trackCount)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as AlbumPreferenceResponse;
  return Object.hash(runtimeType,_this.albumId,_this.dislikedAt,_this.likedAt,_this.score,_this.signal,_this.state,_this.trackCount,_this.updatedAt,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as AlbumPreferenceResponse;
  return 'AlbumPreferenceResponse(albumId: ${_this.albumId}, dislikedAt: ${_this.dislikedAt}, likedAt: ${_this.likedAt}, score: ${_this.score}, signal: ${_this.signal}, state: ${_this.state}, trackCount: ${_this.trackCount}, updatedAt: ${_this.updatedAt}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $AlbumPreferenceResponseCopyWith<$Res>  {
  factory $AlbumPreferenceResponseCopyWith(AlbumPreferenceResponse value, $Res Function(AlbumPreferenceResponse) _then) = _$AlbumPreferenceResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String albumId,@JsonKey(required: true, fromJson: AlbumPreferenceResponse._read_dislikedAt, toJson: AlbumPreferenceResponse._write_dislikedAt) DateTime? dislikedAt,@JsonKey(required: true, fromJson: AlbumPreferenceResponse._read_likedAt, toJson: AlbumPreferenceResponse._write_likedAt) DateTime? likedAt,@JsonKey(required: true, disallowNullValue: true, fromJson: AlbumPreferenceResponse._read_score, toJson: AlbumPreferenceResponse._write_score) int score,@JsonKey(required: true, disallowNullValue: true, fromJson: AlbumPreferenceResponse._read_signal, toJson: AlbumPreferenceResponse._write_signal) PreferenceSignal signal,@JsonKey(required: true, disallowNullValue: true, fromJson: AlbumPreferenceResponse._read_state, toJson: AlbumPreferenceResponse._write_state) PreferenceState state,@JsonKey(required: true, disallowNullValue: true, fromJson: AlbumPreferenceResponse._read_trackCount, toJson: AlbumPreferenceResponse._write_trackCount) int trackCount,@JsonKey(required: true, fromJson: AlbumPreferenceResponse._read_updatedAt, toJson: AlbumPreferenceResponse._write_updatedAt) DateTime? updatedAt,@JsonKey(readValue: AlbumPreferenceResponse._extras, fromJson: AlbumPreferenceResponse._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$AlbumPreferenceResponseCopyWithImpl<$Res>
    implements $AlbumPreferenceResponseCopyWith<$Res> {
  _$AlbumPreferenceResponseCopyWithImpl(this._self, this._then);

  final AlbumPreferenceResponse _self;
  final $Res Function(AlbumPreferenceResponse) _then;

/// Create a copy of AlbumPreferenceResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? albumId = null,Object? dislikedAt = freezed,Object? likedAt = freezed,Object? score = null,Object? signal = null,Object? state = null,Object? trackCount = null,Object? updatedAt = freezed,Object? additionalProperties = null,}) {
  return _then(AlbumPreferenceResponse(
albumId: null == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String,dislikedAt: freezed == dislikedAt ? _self.dislikedAt : dislikedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,likedAt: freezed == likedAt ? _self.likedAt : likedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,signal: null == signal ? _self.signal : signal // ignore: cast_nullable_to_non_nullable
as PreferenceSignal,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PreferenceState,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [AlbumPreferenceResponse].
extension AlbumPreferenceResponsePatterns on AlbumPreferenceResponse {
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
