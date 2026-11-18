// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_episode_progress_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UpdateEpisodeProgressResponse {


/// Create a copy of UpdateEpisodeProgressResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateEpisodeProgressResponseCopyWith<UpdateEpisodeProgressResponse> get copyWith => _$UpdateEpisodeProgressResponseCopyWithImpl<UpdateEpisodeProgressResponse>(this as UpdateEpisodeProgressResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UpdateEpisodeProgressResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateEpisodeProgressResponse&&(identical(other.progress, _this.progress) || other.progress == _this.progress)&&(identical(other.success, _this.success) || other.success == _this.success)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as UpdateEpisodeProgressResponse;
  return Object.hash(runtimeType,_this.progress,_this.success,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as UpdateEpisodeProgressResponse;
  return 'UpdateEpisodeProgressResponse(progress: ${_this.progress}, success: ${_this.success}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $UpdateEpisodeProgressResponseCopyWith<$Res>  {
  factory $UpdateEpisodeProgressResponseCopyWith(UpdateEpisodeProgressResponse value, $Res Function(UpdateEpisodeProgressResponse) _then) = _$UpdateEpisodeProgressResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) SavedEpisodeProgress progress,@JsonKey(required: true, disallowNullValue: true) bool success,@JsonKey(readValue: UpdateEpisodeProgressResponse._extras, fromJson: UpdateEpisodeProgressResponse._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$SavedEpisodeProgressCopyWith<$Res> get progress;

}
/// @nodoc
class _$UpdateEpisodeProgressResponseCopyWithImpl<$Res>
    implements $UpdateEpisodeProgressResponseCopyWith<$Res> {
  _$UpdateEpisodeProgressResponseCopyWithImpl(this._self, this._then);

  final UpdateEpisodeProgressResponse _self;
  final $Res Function(UpdateEpisodeProgressResponse) _then;

/// Create a copy of UpdateEpisodeProgressResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? progress = null,Object? success = null,Object? additionalProperties = null,}) {
  return _then(UpdateEpisodeProgressResponse(
progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as SavedEpisodeProgress,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of UpdateEpisodeProgressResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SavedEpisodeProgressCopyWith<$Res> get progress {
  
  return $SavedEpisodeProgressCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}
}


/// Adds pattern-matching-related methods to [UpdateEpisodeProgressResponse].
extension UpdateEpisodeProgressResponsePatterns on UpdateEpisodeProgressResponse {
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
