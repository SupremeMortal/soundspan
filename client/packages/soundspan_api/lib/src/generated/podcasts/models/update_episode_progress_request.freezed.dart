// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_episode_progress_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UpdateEpisodeProgressRequest {


/// Create a copy of UpdateEpisodeProgressRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateEpisodeProgressRequestCopyWith<UpdateEpisodeProgressRequest> get copyWith => _$UpdateEpisodeProgressRequestCopyWithImpl<UpdateEpisodeProgressRequest>(this as UpdateEpisodeProgressRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UpdateEpisodeProgressRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateEpisodeProgressRequest&&(identical(other.currentTime, _this.currentTime) || other.currentTime == _this.currentTime)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.isFinished, _this.isFinished) || other.isFinished == _this.isFinished)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as UpdateEpisodeProgressRequest;
  return Object.hash(runtimeType,_this.currentTime,_this.duration,_this.isFinished,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as UpdateEpisodeProgressRequest;
  return 'UpdateEpisodeProgressRequest(currentTime: ${_this.currentTime}, duration: ${_this.duration}, isFinished: ${_this.isFinished}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $UpdateEpisodeProgressRequestCopyWith<$Res>  {
  factory $UpdateEpisodeProgressRequestCopyWith(UpdateEpisodeProgressRequest value, $Res Function(UpdateEpisodeProgressRequest) _then) = _$UpdateEpisodeProgressRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) num currentTime,@JsonKey(required: true, disallowNullValue: true) num duration,@JsonKey(disallowNullValue: true, includeIfNull: false) bool? isFinished,@JsonKey(readValue: UpdateEpisodeProgressRequest._extras, fromJson: UpdateEpisodeProgressRequest._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$UpdateEpisodeProgressRequestCopyWithImpl<$Res>
    implements $UpdateEpisodeProgressRequestCopyWith<$Res> {
  _$UpdateEpisodeProgressRequestCopyWithImpl(this._self, this._then);

  final UpdateEpisodeProgressRequest _self;
  final $Res Function(UpdateEpisodeProgressRequest) _then;

/// Create a copy of UpdateEpisodeProgressRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentTime = null,Object? duration = null,Object? isFinished = freezed,Object? additionalProperties = null,}) {
  return _then(UpdateEpisodeProgressRequest(
currentTime: null == currentTime ? _self.currentTime : currentTime // ignore: cast_nullable_to_non_nullable
as num,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as num,isFinished: freezed == isFinished ? _self.isFinished : isFinished // ignore: cast_nullable_to_non_nullable
as bool?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateEpisodeProgressRequest].
extension UpdateEpisodeProgressRequestPatterns on UpdateEpisodeProgressRequest {
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
