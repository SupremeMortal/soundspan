// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_settings_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UpdateSettingsRequest {


/// Create a copy of UpdateSettingsRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateSettingsRequestCopyWith<UpdateSettingsRequest> get copyWith => _$UpdateSettingsRequestCopyWithImpl<UpdateSettingsRequest>(this as UpdateSettingsRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UpdateSettingsRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateSettingsRequest&&(identical(other.loudnessMode, _this.loudnessMode) || other.loudnessMode == _this.loudnessMode)&&(identical(other.maxCacheSizeMb, _this.maxCacheSizeMb) || other.maxCacheSizeMb == _this.maxCacheSizeMb)&&(identical(other.playbackQuality, _this.playbackQuality) || other.playbackQuality == _this.playbackQuality)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as UpdateSettingsRequest;
  return Object.hash(runtimeType,_this.loudnessMode,_this.maxCacheSizeMb,_this.playbackQuality,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as UpdateSettingsRequest;
  return 'UpdateSettingsRequest(loudnessMode: ${_this.loudnessMode}, maxCacheSizeMb: ${_this.maxCacheSizeMb}, playbackQuality: ${_this.playbackQuality}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $UpdateSettingsRequestCopyWith<$Res>  {
  factory $UpdateSettingsRequestCopyWith(UpdateSettingsRequest value, $Res Function(UpdateSettingsRequest) _then) = _$UpdateSettingsRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: UpdateSettingsRequest._read_loudnessMode, toJson: UpdateSettingsRequest._write_loudnessMode) LoudnessMode? loudnessMode,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: UpdateSettingsRequest._read_maxCacheSizeMb, toJson: UpdateSettingsRequest._write_maxCacheSizeMb) int? maxCacheSizeMb,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: UpdateSettingsRequest._read_playbackQuality, toJson: UpdateSettingsRequest._write_playbackQuality) PlaybackQuality? playbackQuality,@JsonKey(readValue: UpdateSettingsRequest._extras, fromJson: UpdateSettingsRequest._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$UpdateSettingsRequestCopyWithImpl<$Res>
    implements $UpdateSettingsRequestCopyWith<$Res> {
  _$UpdateSettingsRequestCopyWithImpl(this._self, this._then);

  final UpdateSettingsRequest _self;
  final $Res Function(UpdateSettingsRequest) _then;

/// Create a copy of UpdateSettingsRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loudnessMode = freezed,Object? maxCacheSizeMb = freezed,Object? playbackQuality = freezed,Object? additionalProperties = null,}) {
  return _then(UpdateSettingsRequest(
loudnessMode: freezed == loudnessMode ? _self.loudnessMode : loudnessMode // ignore: cast_nullable_to_non_nullable
as LoudnessMode?,maxCacheSizeMb: freezed == maxCacheSizeMb ? _self.maxCacheSizeMb : maxCacheSizeMb // ignore: cast_nullable_to_non_nullable
as int?,playbackQuality: freezed == playbackQuality ? _self.playbackQuality : playbackQuality // ignore: cast_nullable_to_non_nullable
as PlaybackQuality?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateSettingsRequest].
extension UpdateSettingsRequestPatterns on UpdateSettingsRequest {
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
