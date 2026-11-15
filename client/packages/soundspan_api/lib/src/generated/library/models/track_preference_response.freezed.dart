// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'track_preference_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrackPreferenceResponse {


/// Create a copy of TrackPreferenceResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackPreferenceResponseCopyWith<TrackPreferenceResponse> get copyWith => _$TrackPreferenceResponseCopyWithImpl<TrackPreferenceResponse>(this as TrackPreferenceResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TrackPreferenceResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackPreferenceResponse&&(identical(other.dislikedAt, _this.dislikedAt) || other.dislikedAt == _this.dislikedAt)&&(identical(other.likedAt, _this.likedAt) || other.likedAt == _this.likedAt)&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&(identical(other.score, _this.score) || other.score == _this.score)&&(identical(other.signal, _this.signal) || other.signal == _this.signal)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.trackId, _this.trackId) || other.trackId == _this.trackId)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as TrackPreferenceResponse;
  return Object.hash(runtimeType,_this.dislikedAt,_this.likedAt,_this.playbackId,_this.score,_this.signal,_this.state,_this.trackId,_this.updatedAt,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as TrackPreferenceResponse;
  return 'TrackPreferenceResponse(dislikedAt: ${_this.dislikedAt}, likedAt: ${_this.likedAt}, playbackId: ${_this.playbackId}, score: ${_this.score}, signal: ${_this.signal}, state: ${_this.state}, trackId: ${_this.trackId}, updatedAt: ${_this.updatedAt}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $TrackPreferenceResponseCopyWith<$Res>  {
  factory $TrackPreferenceResponseCopyWith(TrackPreferenceResponse value, $Res Function(TrackPreferenceResponse) _then) = _$TrackPreferenceResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, fromJson: TrackPreferenceResponse._read_dislikedAt, toJson: TrackPreferenceResponse._write_dislikedAt) DateTime? dislikedAt,@JsonKey(required: true, fromJson: TrackPreferenceResponse._read_likedAt, toJson: TrackPreferenceResponse._write_likedAt) DateTime? likedAt,@JsonKey(required: true, disallowNullValue: true) String playbackId,@JsonKey(required: true, disallowNullValue: true, fromJson: TrackPreferenceResponse._read_score, toJson: TrackPreferenceResponse._write_score) int score,@JsonKey(required: true, disallowNullValue: true, fromJson: TrackPreferenceResponse._read_signal, toJson: TrackPreferenceResponse._write_signal) PreferenceSignal signal,@JsonKey(required: true, disallowNullValue: true, fromJson: TrackPreferenceResponse._read_state, toJson: TrackPreferenceResponse._write_state) PreferenceState state,@JsonKey(required: true, disallowNullValue: true) String trackId,@JsonKey(required: true, fromJson: TrackPreferenceResponse._read_updatedAt, toJson: TrackPreferenceResponse._write_updatedAt) DateTime? updatedAt,@JsonKey(readValue: TrackPreferenceResponse._extras, fromJson: TrackPreferenceResponse._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$TrackPreferenceResponseCopyWithImpl<$Res>
    implements $TrackPreferenceResponseCopyWith<$Res> {
  _$TrackPreferenceResponseCopyWithImpl(this._self, this._then);

  final TrackPreferenceResponse _self;
  final $Res Function(TrackPreferenceResponse) _then;

/// Create a copy of TrackPreferenceResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dislikedAt = freezed,Object? likedAt = freezed,Object? playbackId = null,Object? score = null,Object? signal = null,Object? state = null,Object? trackId = null,Object? updatedAt = freezed,Object? additionalProperties = null,}) {
  return _then(TrackPreferenceResponse(
dislikedAt: freezed == dislikedAt ? _self.dislikedAt : dislikedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,likedAt: freezed == likedAt ? _self.likedAt : likedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,playbackId: null == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,signal: null == signal ? _self.signal : signal // ignore: cast_nullable_to_non_nullable
as PreferenceSignal,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PreferenceState,trackId: null == trackId ? _self.trackId : trackId // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [TrackPreferenceResponse].
extension TrackPreferenceResponsePatterns on TrackPreferenceResponse {
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
