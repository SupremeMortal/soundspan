// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'episode_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EpisodeProgress {


/// Create a copy of EpisodeProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EpisodeProgressCopyWith<EpisodeProgress> get copyWith => _$EpisodeProgressCopyWithImpl<EpisodeProgress>(this as EpisodeProgress, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EpisodeProgress;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EpisodeProgress&&(identical(other.currentTime, _this.currentTime) || other.currentTime == _this.currentTime)&&(identical(other.isFinished, _this.isFinished) || other.isFinished == _this.isFinished)&&(identical(other.lastPlayedAt, _this.lastPlayedAt) || other.lastPlayedAt == _this.lastPlayedAt)&&(identical(other.progress, _this.progress) || other.progress == _this.progress)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as EpisodeProgress;
  return Object.hash(runtimeType,_this.currentTime,_this.isFinished,_this.lastPlayedAt,_this.progress,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as EpisodeProgress;
  return 'EpisodeProgress(currentTime: ${_this.currentTime}, isFinished: ${_this.isFinished}, lastPlayedAt: ${_this.lastPlayedAt}, progress: ${_this.progress}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $EpisodeProgressCopyWith<$Res>  {
  factory $EpisodeProgressCopyWith(EpisodeProgress value, $Res Function(EpisodeProgress) _then) = _$EpisodeProgressCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) num currentTime,@JsonKey(required: true, disallowNullValue: true) bool isFinished,@JsonKey(required: true, disallowNullValue: true, fromJson: EpisodeProgress._read_lastPlayedAt, toJson: EpisodeProgress._write_lastPlayedAt) DateTime lastPlayedAt,@JsonKey(required: true, disallowNullValue: true) num progress,@JsonKey(readValue: EpisodeProgress._extras, fromJson: EpisodeProgress._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$EpisodeProgressCopyWithImpl<$Res>
    implements $EpisodeProgressCopyWith<$Res> {
  _$EpisodeProgressCopyWithImpl(this._self, this._then);

  final EpisodeProgress _self;
  final $Res Function(EpisodeProgress) _then;

/// Create a copy of EpisodeProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentTime = null,Object? isFinished = null,Object? lastPlayedAt = null,Object? progress = null,Object? additionalProperties = null,}) {
  return _then(EpisodeProgress(
currentTime: null == currentTime ? _self.currentTime : currentTime // ignore: cast_nullable_to_non_nullable
as num,isFinished: null == isFinished ? _self.isFinished : isFinished // ignore: cast_nullable_to_non_nullable
as bool,lastPlayedAt: null == lastPlayedAt ? _self.lastPlayedAt : lastPlayedAt // ignore: cast_nullable_to_non_nullable
as DateTime,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as num,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [EpisodeProgress].
extension EpisodeProgressPatterns on EpisodeProgress {
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
