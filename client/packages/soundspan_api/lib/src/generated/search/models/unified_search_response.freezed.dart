// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unified_search_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UnifiedSearchResponse {


/// Create a copy of UnifiedSearchResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnifiedSearchResponseCopyWith<UnifiedSearchResponse> get copyWith => _$UnifiedSearchResponseCopyWithImpl<UnifiedSearchResponse>(this as UnifiedSearchResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UnifiedSearchResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnifiedSearchResponse&&(identical(other.hasMore, _this.hasMore) || other.hasMore == _this.hasMore)&&const DeepCollectionEquality().equals(other.items, _this.items)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as UnifiedSearchResponse;
  return Object.hash(runtimeType,_this.hasMore,const DeepCollectionEquality().hash(_this.items),const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as UnifiedSearchResponse;
  return 'UnifiedSearchResponse(hasMore: ${_this.hasMore}, items: ${_this.items}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $UnifiedSearchResponseCopyWith<$Res>  {
  factory $UnifiedSearchResponseCopyWith(UnifiedSearchResponse value, $Res Function(UnifiedSearchResponse) _then) = _$UnifiedSearchResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) bool hasMore,@JsonKey(required: true, disallowNullValue: true) List<SearchItem> items,@JsonKey(readValue: UnifiedSearchResponse._extras, fromJson: UnifiedSearchResponse._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$UnifiedSearchResponseCopyWithImpl<$Res>
    implements $UnifiedSearchResponseCopyWith<$Res> {
  _$UnifiedSearchResponseCopyWithImpl(this._self, this._then);

  final UnifiedSearchResponse _self;
  final $Res Function(UnifiedSearchResponse) _then;

/// Create a copy of UnifiedSearchResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hasMore = null,Object? items = null,Object? additionalProperties = null,}) {
  return _then(UnifiedSearchResponse(
hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<SearchItem>,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [UnifiedSearchResponse].
extension UnifiedSearchResponsePatterns on UnifiedSearchResponse {
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
