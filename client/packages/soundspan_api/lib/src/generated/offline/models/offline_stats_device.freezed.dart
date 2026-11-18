// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offline_stats_device.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OfflineStatsDevice {


/// Create a copy of OfflineStatsDevice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfflineStatsDeviceCopyWith<OfflineStatsDevice> get copyWith => _$OfflineStatsDeviceCopyWithImpl<OfflineStatsDevice>(this as OfflineStatsDevice, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OfflineStatsDevice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OfflineStatsDevice&&(identical(other.deviceId, _this.deviceId) || other.deviceId == _this.deviceId)&&(identical(other.trackCount, _this.trackCount) || other.trackCount == _this.trackCount)&&(identical(other.usedMb, _this.usedMb) || other.usedMb == _this.usedMb)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as OfflineStatsDevice;
  return Object.hash(runtimeType,_this.deviceId,_this.trackCount,_this.usedMb,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as OfflineStatsDevice;
  return 'OfflineStatsDevice(deviceId: ${_this.deviceId}, trackCount: ${_this.trackCount}, usedMb: ${_this.usedMb}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $OfflineStatsDeviceCopyWith<$Res>  {
  factory $OfflineStatsDeviceCopyWith(OfflineStatsDevice value, $Res Function(OfflineStatsDevice) _then) = _$OfflineStatsDeviceCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String deviceId,@JsonKey(required: true, disallowNullValue: true, fromJson: OfflineStatsDevice._read_trackCount, toJson: OfflineStatsDevice._write_trackCount) int trackCount,@JsonKey(required: true, disallowNullValue: true) num usedMb,@JsonKey(readValue: OfflineStatsDevice._extras, fromJson: OfflineStatsDevice._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$OfflineStatsDeviceCopyWithImpl<$Res>
    implements $OfflineStatsDeviceCopyWith<$Res> {
  _$OfflineStatsDeviceCopyWithImpl(this._self, this._then);

  final OfflineStatsDevice _self;
  final $Res Function(OfflineStatsDevice) _then;

/// Create a copy of OfflineStatsDevice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? trackCount = null,Object? usedMb = null,Object? additionalProperties = null,}) {
  return _then(OfflineStatsDevice(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,usedMb: null == usedMb ? _self.usedMb : usedMb // ignore: cast_nullable_to_non_nullable
as num,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [OfflineStatsDevice].
extension OfflineStatsDevicePatterns on OfflineStatsDevice {
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
