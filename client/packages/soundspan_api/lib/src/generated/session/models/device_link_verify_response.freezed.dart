// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_link_verify_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeviceLinkVerifyResponse {


/// Create a copy of DeviceLinkVerifyResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceLinkVerifyResponseCopyWith<DeviceLinkVerifyResponse> get copyWith => _$DeviceLinkVerifyResponseCopyWithImpl<DeviceLinkVerifyResponse>(this as DeviceLinkVerifyResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DeviceLinkVerifyResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceLinkVerifyResponse&&(identical(other.apiKey, _this.apiKey) || other.apiKey == _this.apiKey)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.username, _this.username) || other.username == _this.username)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as DeviceLinkVerifyResponse;
  return Object.hash(runtimeType,_this.apiKey,_this.userId,_this.username,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as DeviceLinkVerifyResponse;
  return 'DeviceLinkVerifyResponse(apiKey: ${_this.apiKey}, userId: ${_this.userId}, username: ${_this.username}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $DeviceLinkVerifyResponseCopyWith<$Res>  {
  factory $DeviceLinkVerifyResponseCopyWith(DeviceLinkVerifyResponse value, $Res Function(DeviceLinkVerifyResponse) _then) = _$DeviceLinkVerifyResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String apiKey,@JsonKey(required: true, disallowNullValue: true) String userId,@JsonKey(required: true, disallowNullValue: true) String username,@JsonKey(readValue: DeviceLinkVerifyResponse._extras, fromJson: DeviceLinkVerifyResponse._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$DeviceLinkVerifyResponseCopyWithImpl<$Res>
    implements $DeviceLinkVerifyResponseCopyWith<$Res> {
  _$DeviceLinkVerifyResponseCopyWithImpl(this._self, this._then);

  final DeviceLinkVerifyResponse _self;
  final $Res Function(DeviceLinkVerifyResponse) _then;

/// Create a copy of DeviceLinkVerifyResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? apiKey = null,Object? userId = null,Object? username = null,Object? additionalProperties = null,}) {
  return _then(DeviceLinkVerifyResponse(
apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceLinkVerifyResponse].
extension DeviceLinkVerifyResponsePatterns on DeviceLinkVerifyResponse {
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
