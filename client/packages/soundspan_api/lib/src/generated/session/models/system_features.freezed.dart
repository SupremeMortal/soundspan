// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'system_features.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SystemFeatures {


/// Create a copy of SystemFeatures
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SystemFeaturesCopyWith<SystemFeatures> get copyWith => _$SystemFeaturesCopyWithImpl<SystemFeatures>(this as SystemFeatures, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SystemFeatures;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SystemFeatures&&(identical(other.audioAnalysis, _this.audioAnalysis) || other.audioAnalysis == _this.audioAnalysis)&&(identical(other.autoPlaylists, _this.autoPlaylists) || other.autoPlaylists == _this.autoPlaylists)&&(identical(other.discovery, _this.discovery) || other.discovery == _this.discovery)&&(identical(other.federation, _this.federation) || other.federation == _this.federation)&&(identical(other.loudnessTargetLufs, _this.loudnessTargetLufs) || other.loudnessTargetLufs == _this.loudnessTargetLufs)&&(identical(other.vibeEmbeddings, _this.vibeEmbeddings) || other.vibeEmbeddings == _this.vibeEmbeddings)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as SystemFeatures;
  return Object.hash(runtimeType,_this.audioAnalysis,_this.autoPlaylists,_this.discovery,_this.federation,_this.loudnessTargetLufs,_this.vibeEmbeddings,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as SystemFeatures;
  return 'SystemFeatures(audioAnalysis: ${_this.audioAnalysis}, autoPlaylists: ${_this.autoPlaylists}, discovery: ${_this.discovery}, federation: ${_this.federation}, loudnessTargetLufs: ${_this.loudnessTargetLufs}, vibeEmbeddings: ${_this.vibeEmbeddings}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $SystemFeaturesCopyWith<$Res>  {
  factory $SystemFeaturesCopyWith(SystemFeatures value, $Res Function(SystemFeatures) _then) = _$SystemFeaturesCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) bool audioAnalysis,@JsonKey(required: true, disallowNullValue: true) bool autoPlaylists,@JsonKey(required: true, disallowNullValue: true) bool discovery,@JsonKey(required: true, disallowNullValue: true) bool federation,@JsonKey(required: true, disallowNullValue: true) num loudnessTargetLufs,@JsonKey(required: true, disallowNullValue: true) bool vibeEmbeddings,@JsonKey(readValue: SystemFeatures._extras, fromJson: SystemFeatures._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$SystemFeaturesCopyWithImpl<$Res>
    implements $SystemFeaturesCopyWith<$Res> {
  _$SystemFeaturesCopyWithImpl(this._self, this._then);

  final SystemFeatures _self;
  final $Res Function(SystemFeatures) _then;

/// Create a copy of SystemFeatures
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? audioAnalysis = null,Object? autoPlaylists = null,Object? discovery = null,Object? federation = null,Object? loudnessTargetLufs = null,Object? vibeEmbeddings = null,Object? additionalProperties = null,}) {
  return _then(SystemFeatures(
audioAnalysis: null == audioAnalysis ? _self.audioAnalysis : audioAnalysis // ignore: cast_nullable_to_non_nullable
as bool,autoPlaylists: null == autoPlaylists ? _self.autoPlaylists : autoPlaylists // ignore: cast_nullable_to_non_nullable
as bool,discovery: null == discovery ? _self.discovery : discovery // ignore: cast_nullable_to_non_nullable
as bool,federation: null == federation ? _self.federation : federation // ignore: cast_nullable_to_non_nullable
as bool,loudnessTargetLufs: null == loudnessTargetLufs ? _self.loudnessTargetLufs : loudnessTargetLufs // ignore: cast_nullable_to_non_nullable
as num,vibeEmbeddings: null == vibeEmbeddings ? _self.vibeEmbeddings : vibeEmbeddings // ignore: cast_nullable_to_non_nullable
as bool,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [SystemFeatures].
extension SystemFeaturesPatterns on SystemFeatures {
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
