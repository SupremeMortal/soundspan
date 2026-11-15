// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discover_current.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiscoverCurrent {


/// Create a copy of DiscoverCurrent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscoverCurrentCopyWith<DiscoverCurrent> get copyWith => _$DiscoverCurrentCopyWithImpl<DiscoverCurrent>(this as DiscoverCurrent, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DiscoverCurrent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscoverCurrent&&(identical(other.totalCount, _this.totalCount) || other.totalCount == _this.totalCount)&&const DeepCollectionEquality().equals(other.tracks, _this.tracks)&&(identical(other.unavailableCount, _this.unavailableCount) || other.unavailableCount == _this.unavailableCount)&&(identical(other.weekEnd, _this.weekEnd) || other.weekEnd == _this.weekEnd)&&(identical(other.weekStart, _this.weekStart) || other.weekStart == _this.weekStart)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as DiscoverCurrent;
  return Object.hash(runtimeType,_this.totalCount,const DeepCollectionEquality().hash(_this.tracks),_this.unavailableCount,_this.weekEnd,_this.weekStart,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as DiscoverCurrent;
  return 'DiscoverCurrent(totalCount: ${_this.totalCount}, tracks: ${_this.tracks}, unavailableCount: ${_this.unavailableCount}, weekEnd: ${_this.weekEnd}, weekStart: ${_this.weekStart}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $DiscoverCurrentCopyWith<$Res>  {
  factory $DiscoverCurrentCopyWith(DiscoverCurrent value, $Res Function(DiscoverCurrent) _then) = _$DiscoverCurrentCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true, fromJson: DiscoverCurrent._read_totalCount, toJson: DiscoverCurrent._write_totalCount) int totalCount,@JsonKey(required: true, disallowNullValue: true) List<DiscoverTrack> tracks,@JsonKey(required: true, disallowNullValue: true, fromJson: DiscoverCurrent._read_unavailableCount, toJson: DiscoverCurrent._write_unavailableCount) int unavailableCount,@JsonKey(required: true, disallowNullValue: true, fromJson: DiscoverCurrent._read_weekEnd, toJson: DiscoverCurrent._write_weekEnd) DateTime weekEnd,@JsonKey(required: true, disallowNullValue: true, fromJson: DiscoverCurrent._read_weekStart, toJson: DiscoverCurrent._write_weekStart) DateTime weekStart,@JsonKey(readValue: DiscoverCurrent._extras, fromJson: DiscoverCurrent._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$DiscoverCurrentCopyWithImpl<$Res>
    implements $DiscoverCurrentCopyWith<$Res> {
  _$DiscoverCurrentCopyWithImpl(this._self, this._then);

  final DiscoverCurrent _self;
  final $Res Function(DiscoverCurrent) _then;

/// Create a copy of DiscoverCurrent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalCount = null,Object? tracks = null,Object? unavailableCount = null,Object? weekEnd = null,Object? weekStart = null,Object? additionalProperties = null,}) {
  return _then(DiscoverCurrent(
totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<DiscoverTrack>,unavailableCount: null == unavailableCount ? _self.unavailableCount : unavailableCount // ignore: cast_nullable_to_non_nullable
as int,weekEnd: null == weekEnd ? _self.weekEnd : weekEnd // ignore: cast_nullable_to_non_nullable
as DateTime,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as DateTime,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [DiscoverCurrent].
extension DiscoverCurrentPatterns on DiscoverCurrent {
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
