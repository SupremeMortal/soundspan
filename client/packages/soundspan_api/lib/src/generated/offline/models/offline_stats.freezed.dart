// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offline_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OfflineStats {


/// Create a copy of OfflineStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfflineStatsCopyWith<OfflineStats> get copyWith => _$OfflineStatsCopyWithImpl<OfflineStats>(this as OfflineStats, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OfflineStats;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OfflineStats&&(identical(other.availableMb, _this.availableMb) || other.availableMb == _this.availableMb)&&(identical(other.device, _this.device) || other.device == _this.device)&&(identical(other.maxMb, _this.maxMb) || other.maxMb == _this.maxMb)&&(identical(other.percentUsed, _this.percentUsed) || other.percentUsed == _this.percentUsed)&&(identical(other.trackCount, _this.trackCount) || other.trackCount == _this.trackCount)&&(identical(other.usedMb, _this.usedMb) || other.usedMb == _this.usedMb)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as OfflineStats;
  return Object.hash(runtimeType,_this.availableMb,_this.device,_this.maxMb,_this.percentUsed,_this.trackCount,_this.usedMb,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as OfflineStats;
  return 'OfflineStats(availableMb: ${_this.availableMb}, device: ${_this.device}, maxMb: ${_this.maxMb}, percentUsed: ${_this.percentUsed}, trackCount: ${_this.trackCount}, usedMb: ${_this.usedMb}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $OfflineStatsCopyWith<$Res>  {
  factory $OfflineStatsCopyWith(OfflineStats value, $Res Function(OfflineStats) _then) = _$OfflineStatsCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) num availableMb,@JsonKey(disallowNullValue: true, includeIfNull: false) OfflineStatsDevice? device,@JsonKey(required: true, disallowNullValue: true, fromJson: OfflineStats._read_maxMb, toJson: OfflineStats._write_maxMb) int maxMb,@JsonKey(required: true, disallowNullValue: true) num percentUsed,@JsonKey(required: true, disallowNullValue: true, fromJson: OfflineStats._read_trackCount, toJson: OfflineStats._write_trackCount) int trackCount,@JsonKey(required: true, disallowNullValue: true) num usedMb,@JsonKey(readValue: OfflineStats._extras, fromJson: OfflineStats._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$OfflineStatsDeviceCopyWith<$Res>? get device;

}
/// @nodoc
class _$OfflineStatsCopyWithImpl<$Res>
    implements $OfflineStatsCopyWith<$Res> {
  _$OfflineStatsCopyWithImpl(this._self, this._then);

  final OfflineStats _self;
  final $Res Function(OfflineStats) _then;

/// Create a copy of OfflineStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? availableMb = null,Object? device = freezed,Object? maxMb = null,Object? percentUsed = null,Object? trackCount = null,Object? usedMb = null,Object? additionalProperties = null,}) {
  return _then(OfflineStats(
availableMb: null == availableMb ? _self.availableMb : availableMb // ignore: cast_nullable_to_non_nullable
as num,device: freezed == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as OfflineStatsDevice?,maxMb: null == maxMb ? _self.maxMb : maxMb // ignore: cast_nullable_to_non_nullable
as int,percentUsed: null == percentUsed ? _self.percentUsed : percentUsed // ignore: cast_nullable_to_non_nullable
as num,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,usedMb: null == usedMb ? _self.usedMb : usedMb // ignore: cast_nullable_to_non_nullable
as num,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of OfflineStats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OfflineStatsDeviceCopyWith<$Res>? get device {
    if (_self.device == null) {
    return null;
  }

  return $OfflineStatsDeviceCopyWith<$Res>(_self.device!, (value) {
    return _then(_self.copyWith(device: value));
  });
}
}


/// Adds pattern-matching-related methods to [OfflineStats].
extension OfflineStatsPatterns on OfflineStats {
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
