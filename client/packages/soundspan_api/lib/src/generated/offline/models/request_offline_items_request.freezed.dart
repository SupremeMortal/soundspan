// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'request_offline_items_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RequestOfflineItemsRequest {


/// Create a copy of RequestOfflineItemsRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RequestOfflineItemsRequestCopyWith<RequestOfflineItemsRequest> get copyWith => _$RequestOfflineItemsRequestCopyWithImpl<RequestOfflineItemsRequest>(this as RequestOfflineItemsRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RequestOfflineItemsRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RequestOfflineItemsRequest&&(identical(other.deviceId, _this.deviceId) || other.deviceId == _this.deviceId)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.quality, _this.quality) || other.quality == _this.quality)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as RequestOfflineItemsRequest;
  return Object.hash(runtimeType,_this.deviceId,_this.id,_this.kind,_this.quality,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as RequestOfflineItemsRequest;
  return 'RequestOfflineItemsRequest(deviceId: ${_this.deviceId}, id: ${_this.id}, kind: ${_this.kind}, quality: ${_this.quality}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $RequestOfflineItemsRequestCopyWith<$Res>  {
  factory $RequestOfflineItemsRequestCopyWith(RequestOfflineItemsRequest value, $Res Function(RequestOfflineItemsRequest) _then) = _$RequestOfflineItemsRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String deviceId,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true, disallowNullValue: true, fromJson: RequestOfflineItemsRequest._read_kind, toJson: RequestOfflineItemsRequest._write_kind) RequestOfflineItemsRequestKind kind,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: RequestOfflineItemsRequest._read_quality, toJson: RequestOfflineItemsRequest._write_quality) RequestOfflineItemsRequestQuality? quality,@JsonKey(readValue: RequestOfflineItemsRequest._extras, fromJson: RequestOfflineItemsRequest._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$RequestOfflineItemsRequestCopyWithImpl<$Res>
    implements $RequestOfflineItemsRequestCopyWith<$Res> {
  _$RequestOfflineItemsRequestCopyWithImpl(this._self, this._then);

  final RequestOfflineItemsRequest _self;
  final $Res Function(RequestOfflineItemsRequest) _then;

/// Create a copy of RequestOfflineItemsRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? id = null,Object? kind = null,Object? quality = freezed,Object? additionalProperties = null,}) {
  return _then(RequestOfflineItemsRequest(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RequestOfflineItemsRequestKind,quality: freezed == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as RequestOfflineItemsRequestQuality?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [RequestOfflineItemsRequest].
extension RequestOfflineItemsRequestPatterns on RequestOfflineItemsRequest {
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
