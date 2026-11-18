// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'radio_decades_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RadioDecadesResponse {


/// Create a copy of RadioDecadesResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioDecadesResponseCopyWith<RadioDecadesResponse> get copyWith => _$RadioDecadesResponseCopyWithImpl<RadioDecadesResponse>(this as RadioDecadesResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RadioDecadesResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioDecadesResponse&&const DeepCollectionEquality().equals(other.decades, _this.decades)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as RadioDecadesResponse;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.decades),const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as RadioDecadesResponse;
  return 'RadioDecadesResponse(decades: ${_this.decades}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $RadioDecadesResponseCopyWith<$Res>  {
  factory $RadioDecadesResponseCopyWith(RadioDecadesResponse value, $Res Function(RadioDecadesResponse) _then) = _$RadioDecadesResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) List<RadioDecade> decades,@JsonKey(readValue: RadioDecadesResponse._extras, fromJson: RadioDecadesResponse._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$RadioDecadesResponseCopyWithImpl<$Res>
    implements $RadioDecadesResponseCopyWith<$Res> {
  _$RadioDecadesResponseCopyWithImpl(this._self, this._then);

  final RadioDecadesResponse _self;
  final $Res Function(RadioDecadesResponse) _then;

/// Create a copy of RadioDecadesResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? decades = null,Object? additionalProperties = null,}) {
  return _then(RadioDecadesResponse(
decades: null == decades ? _self.decades : decades // ignore: cast_nullable_to_non_nullable
as List<RadioDecade>,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [RadioDecadesResponse].
extension RadioDecadesResponsePatterns on RadioDecadesResponse {
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
