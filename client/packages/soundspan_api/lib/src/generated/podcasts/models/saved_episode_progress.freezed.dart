// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_episode_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SavedEpisodeProgress {


/// Create a copy of SavedEpisodeProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedEpisodeProgressCopyWith<SavedEpisodeProgress> get copyWith => _$SavedEpisodeProgressCopyWithImpl<SavedEpisodeProgress>(this as SavedEpisodeProgress, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SavedEpisodeProgress;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedEpisodeProgress&&(identical(other.currentTime, _this.currentTime) || other.currentTime == _this.currentTime)&&(identical(other.isFinished, _this.isFinished) || other.isFinished == _this.isFinished)&&(identical(other.progress, _this.progress) || other.progress == _this.progress)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as SavedEpisodeProgress;
  return Object.hash(runtimeType,_this.currentTime,_this.isFinished,_this.progress,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as SavedEpisodeProgress;
  return 'SavedEpisodeProgress(currentTime: ${_this.currentTime}, isFinished: ${_this.isFinished}, progress: ${_this.progress}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $SavedEpisodeProgressCopyWith<$Res>  {
  factory $SavedEpisodeProgressCopyWith(SavedEpisodeProgress value, $Res Function(SavedEpisodeProgress) _then) = _$SavedEpisodeProgressCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) num currentTime,@JsonKey(required: true, disallowNullValue: true) bool isFinished,@JsonKey(required: true, disallowNullValue: true) num progress,@JsonKey(readValue: SavedEpisodeProgress._extras, fromJson: SavedEpisodeProgress._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$SavedEpisodeProgressCopyWithImpl<$Res>
    implements $SavedEpisodeProgressCopyWith<$Res> {
  _$SavedEpisodeProgressCopyWithImpl(this._self, this._then);

  final SavedEpisodeProgress _self;
  final $Res Function(SavedEpisodeProgress) _then;

/// Create a copy of SavedEpisodeProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentTime = null,Object? isFinished = null,Object? progress = null,Object? additionalProperties = null,}) {
  return _then(SavedEpisodeProgress(
currentTime: null == currentTime ? _self.currentTime : currentTime // ignore: cast_nullable_to_non_nullable
as num,isFinished: null == isFinished ? _self.isFinished : isFinished // ignore: cast_nullable_to_non_nullable
as bool,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as num,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedEpisodeProgress].
extension SavedEpisodeProgressPatterns on SavedEpisodeProgress {
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
