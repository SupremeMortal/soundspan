// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_document_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ApiDocumentInfo {


/// Create a copy of ApiDocumentInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiDocumentInfoCopyWith<ApiDocumentInfo> get copyWith => _$ApiDocumentInfoCopyWithImpl<ApiDocumentInfo>(this as ApiDocumentInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ApiDocumentInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiDocumentInfo&&(identical(other.info, _this.info) || other.info == _this.info)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as ApiDocumentInfo;
  return Object.hash(runtimeType,_this.info,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as ApiDocumentInfo;
  return 'ApiDocumentInfo(info: ${_this.info}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $ApiDocumentInfoCopyWith<$Res>  {
  factory $ApiDocumentInfoCopyWith(ApiDocumentInfo value, $Res Function(ApiDocumentInfo) _then) = _$ApiDocumentInfoCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) ApiDocumentInfoInfo info,@JsonKey(readValue: ApiDocumentInfo._extras, fromJson: ApiDocumentInfo._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$ApiDocumentInfoInfoCopyWith<$Res> get info;

}
/// @nodoc
class _$ApiDocumentInfoCopyWithImpl<$Res>
    implements $ApiDocumentInfoCopyWith<$Res> {
  _$ApiDocumentInfoCopyWithImpl(this._self, this._then);

  final ApiDocumentInfo _self;
  final $Res Function(ApiDocumentInfo) _then;

/// Create a copy of ApiDocumentInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? info = null,Object? additionalProperties = null,}) {
  return _then(ApiDocumentInfo(
info: null == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as ApiDocumentInfoInfo,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of ApiDocumentInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiDocumentInfoInfoCopyWith<$Res> get info {
  
  return $ApiDocumentInfoInfoCopyWith<$Res>(_self.info, (value) {
    return _then(_self.copyWith(info: value));
  });
}
}


/// Adds pattern-matching-related methods to [ApiDocumentInfo].
extension ApiDocumentInfoPatterns on ApiDocumentInfo {
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
