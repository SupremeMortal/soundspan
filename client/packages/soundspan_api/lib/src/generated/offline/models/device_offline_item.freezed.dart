// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_offline_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeviceOfflineItem {


/// Create a copy of DeviceOfflineItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceOfflineItemCopyWith<DeviceOfflineItem> get copyWith => _$DeviceOfflineItemCopyWithImpl<DeviceOfflineItem>(this as DeviceOfflineItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DeviceOfflineItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceOfflineItem&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&(identical(other.quality, _this.quality) || other.quality == _this.quality)&&(identical(other.revoked, _this.revoked) || other.revoked == _this.revoked)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as DeviceOfflineItem;
  return Object.hash(runtimeType,_this.playbackId,_this.quality,_this.revoked,_this.sizeBytes,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as DeviceOfflineItem;
  return 'DeviceOfflineItem(playbackId: ${_this.playbackId}, quality: ${_this.quality}, revoked: ${_this.revoked}, sizeBytes: ${_this.sizeBytes}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $DeviceOfflineItemCopyWith<$Res>  {
  factory $DeviceOfflineItemCopyWith(DeviceOfflineItem value, $Res Function(DeviceOfflineItem) _then) = _$DeviceOfflineItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String playbackId,@JsonKey(required: true, disallowNullValue: true, fromJson: DeviceOfflineItem._read_quality, toJson: DeviceOfflineItem._write_quality) DeviceOfflineItemQuality quality,@JsonKey(required: true, disallowNullValue: true) bool revoked,@JsonKey(required: true, disallowNullValue: true, fromJson: DeviceOfflineItem._read_sizeBytes, toJson: DeviceOfflineItem._write_sizeBytes) int sizeBytes,@JsonKey(readValue: DeviceOfflineItem._extras, fromJson: DeviceOfflineItem._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$DeviceOfflineItemCopyWithImpl<$Res>
    implements $DeviceOfflineItemCopyWith<$Res> {
  _$DeviceOfflineItemCopyWithImpl(this._self, this._then);

  final DeviceOfflineItem _self;
  final $Res Function(DeviceOfflineItem) _then;

/// Create a copy of DeviceOfflineItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playbackId = null,Object? quality = null,Object? revoked = null,Object? sizeBytes = null,Object? additionalProperties = null,}) {
  return _then(DeviceOfflineItem(
playbackId: null == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as String,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as DeviceOfflineItemQuality,revoked: null == revoked ? _self.revoked : revoked // ignore: cast_nullable_to_non_nullable
as bool,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceOfflineItem].
extension DeviceOfflineItemPatterns on DeviceOfflineItem {
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
