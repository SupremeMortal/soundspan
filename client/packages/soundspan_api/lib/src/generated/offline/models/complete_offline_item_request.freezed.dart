// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'complete_offline_item_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CompleteOfflineItemRequest {


/// Create a copy of CompleteOfflineItemRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompleteOfflineItemRequestCopyWith<CompleteOfflineItemRequest> get copyWith => _$CompleteOfflineItemRequestCopyWithImpl<CompleteOfflineItemRequest>(this as CompleteOfflineItemRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CompleteOfflineItemRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompleteOfflineItemRequest&&(identical(other.deviceId, _this.deviceId) || other.deviceId == _this.deviceId)&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&(identical(other.quality, _this.quality) || other.quality == _this.quality)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as CompleteOfflineItemRequest;
  return Object.hash(runtimeType,_this.deviceId,_this.playbackId,_this.quality,_this.sizeBytes,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as CompleteOfflineItemRequest;
  return 'CompleteOfflineItemRequest(deviceId: ${_this.deviceId}, playbackId: ${_this.playbackId}, quality: ${_this.quality}, sizeBytes: ${_this.sizeBytes}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $CompleteOfflineItemRequestCopyWith<$Res>  {
  factory $CompleteOfflineItemRequestCopyWith(CompleteOfflineItemRequest value, $Res Function(CompleteOfflineItemRequest) _then) = _$CompleteOfflineItemRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String deviceId,@JsonKey(required: true, disallowNullValue: true) String playbackId,@JsonKey(required: true, disallowNullValue: true, fromJson: CompleteOfflineItemRequest._read_quality, toJson: CompleteOfflineItemRequest._write_quality) CompleteOfflineItemRequestQuality quality,@JsonKey(required: true, disallowNullValue: true, fromJson: CompleteOfflineItemRequest._read_sizeBytes, toJson: CompleteOfflineItemRequest._write_sizeBytes) int sizeBytes,@JsonKey(readValue: CompleteOfflineItemRequest._extras, fromJson: CompleteOfflineItemRequest._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$CompleteOfflineItemRequestCopyWithImpl<$Res>
    implements $CompleteOfflineItemRequestCopyWith<$Res> {
  _$CompleteOfflineItemRequestCopyWithImpl(this._self, this._then);

  final CompleteOfflineItemRequest _self;
  final $Res Function(CompleteOfflineItemRequest) _then;

/// Create a copy of CompleteOfflineItemRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? playbackId = null,Object? quality = null,Object? sizeBytes = null,Object? additionalProperties = null,}) {
  return _then(CompleteOfflineItemRequest(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,playbackId: null == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as String,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as CompleteOfflineItemRequestQuality,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [CompleteOfflineItemRequest].
extension CompleteOfflineItemRequestPatterns on CompleteOfflineItemRequest {
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
