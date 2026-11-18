// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offline_items_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OfflineItemsResponse {


/// Create a copy of OfflineItemsResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfflineItemsResponseCopyWith<OfflineItemsResponse> get copyWith => _$OfflineItemsResponseCopyWithImpl<OfflineItemsResponse>(this as OfflineItemsResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OfflineItemsResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OfflineItemsResponse&&(identical(other.cacheLimitBytes, _this.cacheLimitBytes) || other.cacheLimitBytes == _this.cacheLimitBytes)&&(identical(other.cacheUsedBytes, _this.cacheUsedBytes) || other.cacheUsedBytes == _this.cacheUsedBytes)&&(identical(other.estimatedTotalBytes, _this.estimatedTotalBytes) || other.estimatedTotalBytes == _this.estimatedTotalBytes)&&const DeepCollectionEquality().equals(other.items, _this.items)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as OfflineItemsResponse;
  return Object.hash(runtimeType,_this.cacheLimitBytes,_this.cacheUsedBytes,_this.estimatedTotalBytes,const DeepCollectionEquality().hash(_this.items),const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as OfflineItemsResponse;
  return 'OfflineItemsResponse(cacheLimitBytes: ${_this.cacheLimitBytes}, cacheUsedBytes: ${_this.cacheUsedBytes}, estimatedTotalBytes: ${_this.estimatedTotalBytes}, items: ${_this.items}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $OfflineItemsResponseCopyWith<$Res>  {
  factory $OfflineItemsResponseCopyWith(OfflineItemsResponse value, $Res Function(OfflineItemsResponse) _then) = _$OfflineItemsResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true, fromJson: OfflineItemsResponse._read_cacheLimitBytes, toJson: OfflineItemsResponse._write_cacheLimitBytes) int cacheLimitBytes,@JsonKey(required: true, disallowNullValue: true, fromJson: OfflineItemsResponse._read_cacheUsedBytes, toJson: OfflineItemsResponse._write_cacheUsedBytes) int cacheUsedBytes,@JsonKey(required: true, disallowNullValue: true, fromJson: OfflineItemsResponse._read_estimatedTotalBytes, toJson: OfflineItemsResponse._write_estimatedTotalBytes) int estimatedTotalBytes,@JsonKey(required: true, disallowNullValue: true) List<OfflineItem> items,@JsonKey(readValue: OfflineItemsResponse._extras, fromJson: OfflineItemsResponse._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$OfflineItemsResponseCopyWithImpl<$Res>
    implements $OfflineItemsResponseCopyWith<$Res> {
  _$OfflineItemsResponseCopyWithImpl(this._self, this._then);

  final OfflineItemsResponse _self;
  final $Res Function(OfflineItemsResponse) _then;

/// Create a copy of OfflineItemsResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cacheLimitBytes = null,Object? cacheUsedBytes = null,Object? estimatedTotalBytes = null,Object? items = null,Object? additionalProperties = null,}) {
  return _then(OfflineItemsResponse(
cacheLimitBytes: null == cacheLimitBytes ? _self.cacheLimitBytes : cacheLimitBytes // ignore: cast_nullable_to_non_nullable
as int,cacheUsedBytes: null == cacheUsedBytes ? _self.cacheUsedBytes : cacheUsedBytes // ignore: cast_nullable_to_non_nullable
as int,estimatedTotalBytes: null == estimatedTotalBytes ? _self.estimatedTotalBytes : estimatedTotalBytes // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<OfflineItem>,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [OfflineItemsResponse].
extension OfflineItemsResponsePatterns on OfflineItemsResponse {
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
