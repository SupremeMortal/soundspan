// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vibe_audio_features.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VibeAudioFeatures {


/// Create a copy of VibeAudioFeatures
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VibeAudioFeaturesCopyWith<VibeAudioFeatures> get copyWith => _$VibeAudioFeaturesCopyWithImpl<VibeAudioFeatures>(this as VibeAudioFeatures, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as VibeAudioFeatures;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VibeAudioFeatures&&(identical(other.arousal, _this.arousal) || other.arousal == _this.arousal)&&(identical(other.danceability, _this.danceability) || other.danceability == _this.danceability)&&(identical(other.energy, _this.energy) || other.energy == _this.energy)&&(identical(other.valence, _this.valence) || other.valence == _this.valence)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as VibeAudioFeatures;
  return Object.hash(runtimeType,_this.arousal,_this.danceability,_this.energy,_this.valence,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as VibeAudioFeatures;
  return 'VibeAudioFeatures(arousal: ${_this.arousal}, danceability: ${_this.danceability}, energy: ${_this.energy}, valence: ${_this.valence}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $VibeAudioFeaturesCopyWith<$Res>  {
  factory $VibeAudioFeaturesCopyWith(VibeAudioFeatures value, $Res Function(VibeAudioFeatures) _then) = _$VibeAudioFeaturesCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true) num? arousal,@JsonKey(required: true) num? danceability,@JsonKey(required: true) num? energy,@JsonKey(required: true) num? valence,@JsonKey(readValue: VibeAudioFeatures._extras, fromJson: VibeAudioFeatures._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$VibeAudioFeaturesCopyWithImpl<$Res>
    implements $VibeAudioFeaturesCopyWith<$Res> {
  _$VibeAudioFeaturesCopyWithImpl(this._self, this._then);

  final VibeAudioFeatures _self;
  final $Res Function(VibeAudioFeatures) _then;

/// Create a copy of VibeAudioFeatures
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? arousal = freezed,Object? danceability = freezed,Object? energy = freezed,Object? valence = freezed,Object? additionalProperties = null,}) {
  return _then(VibeAudioFeatures(
arousal: freezed == arousal ? _self.arousal : arousal // ignore: cast_nullable_to_non_nullable
as num?,danceability: freezed == danceability ? _self.danceability : danceability // ignore: cast_nullable_to_non_nullable
as num?,energy: freezed == energy ? _self.energy : energy // ignore: cast_nullable_to_non_nullable
as num?,valence: freezed == valence ? _self.valence : valence // ignore: cast_nullable_to_non_nullable
as num?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [VibeAudioFeatures].
extension VibeAudioFeaturesPatterns on VibeAudioFeatures {
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
