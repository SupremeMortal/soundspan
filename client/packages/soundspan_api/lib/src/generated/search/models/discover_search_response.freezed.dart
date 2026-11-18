// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discover_search_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiscoverSearchResponse {


/// Create a copy of DiscoverSearchResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscoverSearchResponseCopyWith<DiscoverSearchResponse> get copyWith => _$DiscoverSearchResponseCopyWithImpl<DiscoverSearchResponse>(this as DiscoverSearchResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DiscoverSearchResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscoverSearchResponse&&(identical(other.aliasInfo, _this.aliasInfo) || other.aliasInfo == _this.aliasInfo)&&const DeepCollectionEquality().equals(other.results, _this.results)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as DiscoverSearchResponse;
  return Object.hash(runtimeType,_this.aliasInfo,const DeepCollectionEquality().hash(_this.results),const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as DiscoverSearchResponse;
  return 'DiscoverSearchResponse(aliasInfo: ${_this.aliasInfo}, results: ${_this.results}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $DiscoverSearchResponseCopyWith<$Res>  {
  factory $DiscoverSearchResponseCopyWith(DiscoverSearchResponse value, $Res Function(DiscoverSearchResponse) _then) = _$DiscoverSearchResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true) DiscoverAliasInfo? aliasInfo,@JsonKey(required: true, disallowNullValue: true) List<DiscoverResult> results,@JsonKey(readValue: DiscoverSearchResponse._extras, fromJson: DiscoverSearchResponse._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$DiscoverAliasInfoCopyWith<$Res>? get aliasInfo;

}
/// @nodoc
class _$DiscoverSearchResponseCopyWithImpl<$Res>
    implements $DiscoverSearchResponseCopyWith<$Res> {
  _$DiscoverSearchResponseCopyWithImpl(this._self, this._then);

  final DiscoverSearchResponse _self;
  final $Res Function(DiscoverSearchResponse) _then;

/// Create a copy of DiscoverSearchResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? aliasInfo = freezed,Object? results = null,Object? additionalProperties = null,}) {
  return _then(DiscoverSearchResponse(
aliasInfo: freezed == aliasInfo ? _self.aliasInfo : aliasInfo // ignore: cast_nullable_to_non_nullable
as DiscoverAliasInfo?,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<DiscoverResult>,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of DiscoverSearchResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DiscoverAliasInfoCopyWith<$Res>? get aliasInfo {
    if (_self.aliasInfo == null) {
    return null;
  }

  return $DiscoverAliasInfoCopyWith<$Res>(_self.aliasInfo!, (value) {
    return _then(_self.copyWith(aliasInfo: value));
  });
}
}


/// Adds pattern-matching-related methods to [DiscoverSearchResponse].
extension DiscoverSearchResponsePatterns on DiscoverSearchResponse {
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
