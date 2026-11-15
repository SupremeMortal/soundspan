// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leave_listen_group_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LeaveListenGroupResponse {


/// Create a copy of LeaveListenGroupResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeaveListenGroupResponseCopyWith<LeaveListenGroupResponse> get copyWith => _$LeaveListenGroupResponseCopyWithImpl<LeaveListenGroupResponse>(this as LeaveListenGroupResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LeaveListenGroupResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeaveListenGroupResponse&&(identical(other.ended, _this.ended) || other.ended == _this.ended)&&(identical(other.newHostUserId, _this.newHostUserId) || other.newHostUserId == _this.newHostUserId)&&(identical(other.newHostUsername, _this.newHostUsername) || other.newHostUsername == _this.newHostUsername)&&(identical(other.success, _this.success) || other.success == _this.success)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as LeaveListenGroupResponse;
  return Object.hash(runtimeType,_this.ended,_this.newHostUserId,_this.newHostUsername,_this.success,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as LeaveListenGroupResponse;
  return 'LeaveListenGroupResponse(ended: ${_this.ended}, newHostUserId: ${_this.newHostUserId}, newHostUsername: ${_this.newHostUsername}, success: ${_this.success}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $LeaveListenGroupResponseCopyWith<$Res>  {
  factory $LeaveListenGroupResponseCopyWith(LeaveListenGroupResponse value, $Res Function(LeaveListenGroupResponse) _then) = _$LeaveListenGroupResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) bool ended,@JsonKey(disallowNullValue: true, includeIfNull: false) String? newHostUserId,@JsonKey(disallowNullValue: true, includeIfNull: false) String? newHostUsername,@JsonKey(required: true, disallowNullValue: true) bool success,@JsonKey(readValue: LeaveListenGroupResponse._extras, fromJson: LeaveListenGroupResponse._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$LeaveListenGroupResponseCopyWithImpl<$Res>
    implements $LeaveListenGroupResponseCopyWith<$Res> {
  _$LeaveListenGroupResponseCopyWithImpl(this._self, this._then);

  final LeaveListenGroupResponse _self;
  final $Res Function(LeaveListenGroupResponse) _then;

/// Create a copy of LeaveListenGroupResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ended = null,Object? newHostUserId = freezed,Object? newHostUsername = freezed,Object? success = null,Object? additionalProperties = null,}) {
  return _then(LeaveListenGroupResponse(
ended: null == ended ? _self.ended : ended // ignore: cast_nullable_to_non_nullable
as bool,newHostUserId: freezed == newHostUserId ? _self.newHostUserId : newHostUserId // ignore: cast_nullable_to_non_nullable
as String?,newHostUsername: freezed == newHostUsername ? _self.newHostUsername : newHostUsername // ignore: cast_nullable_to_non_nullable
as String?,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [LeaveListenGroupResponse].
extension LeaveListenGroupResponsePatterns on LeaveListenGroupResponse {
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
