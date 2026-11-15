// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HealthStatus {


/// Create a copy of HealthStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthStatusCopyWith<HealthStatus> get copyWith => _$HealthStatusCopyWithImpl<HealthStatus>(this as HealthStatus, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as HealthStatus;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthStatus&&(identical(other.draining, _this.draining) || other.draining == _this.draining)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.startupComplete, _this.startupComplete) || other.startupComplete == _this.startupComplete)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.uptimeSeconds, _this.uptimeSeconds) || other.uptimeSeconds == _this.uptimeSeconds)&&(identical(other.version, _this.version) || other.version == _this.version)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as HealthStatus;
  return Object.hash(runtimeType,_this.draining,_this.role,_this.startupComplete,_this.status,_this.uptimeSeconds,_this.version,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as HealthStatus;
  return 'HealthStatus(draining: ${_this.draining}, role: ${_this.role}, startupComplete: ${_this.startupComplete}, status: ${_this.status}, uptimeSeconds: ${_this.uptimeSeconds}, version: ${_this.version}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $HealthStatusCopyWith<$Res>  {
  factory $HealthStatusCopyWith(HealthStatus value, $Res Function(HealthStatus) _then) = _$HealthStatusCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) bool draining,@JsonKey(required: true, disallowNullValue: true, fromJson: HealthStatus._read_role, toJson: HealthStatus._write_role) HealthStatusRole role,@JsonKey(required: true, disallowNullValue: true) bool startupComplete,@JsonKey(required: true, disallowNullValue: true) String status,@JsonKey(required: true, disallowNullValue: true, fromJson: HealthStatus._read_uptimeSeconds, toJson: HealthStatus._write_uptimeSeconds) int uptimeSeconds,@JsonKey(required: true, disallowNullValue: true) String version,@JsonKey(readValue: HealthStatus._extras, fromJson: HealthStatus._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$HealthStatusCopyWithImpl<$Res>
    implements $HealthStatusCopyWith<$Res> {
  _$HealthStatusCopyWithImpl(this._self, this._then);

  final HealthStatus _self;
  final $Res Function(HealthStatus) _then;

/// Create a copy of HealthStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? draining = null,Object? role = null,Object? startupComplete = null,Object? status = null,Object? uptimeSeconds = null,Object? version = null,Object? additionalProperties = null,}) {
  return _then(HealthStatus(
draining: null == draining ? _self.draining : draining // ignore: cast_nullable_to_non_nullable
as bool,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as HealthStatusRole,startupComplete: null == startupComplete ? _self.startupComplete : startupComplete // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,uptimeSeconds: null == uptimeSeconds ? _self.uptimeSeconds : uptimeSeconds // ignore: cast_nullable_to_non_nullable
as int,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [HealthStatus].
extension HealthStatusPatterns on HealthStatus {
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
