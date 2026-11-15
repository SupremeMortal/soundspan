// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vibe_search_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VibeSearchRequest {


/// Create a copy of VibeSearchRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VibeSearchRequestCopyWith<VibeSearchRequest> get copyWith => _$VibeSearchRequestCopyWithImpl<VibeSearchRequest>(this as VibeSearchRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as VibeSearchRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VibeSearchRequest&&(identical(other.limit, _this.limit) || other.limit == _this.limit)&&(identical(other.minSimilarity, _this.minSimilarity) || other.minSimilarity == _this.minSimilarity)&&(identical(other.query, _this.query) || other.query == _this.query)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as VibeSearchRequest;
  return Object.hash(runtimeType,_this.limit,_this.minSimilarity,_this.query,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as VibeSearchRequest;
  return 'VibeSearchRequest(limit: ${_this.limit}, minSimilarity: ${_this.minSimilarity}, query: ${_this.query}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $VibeSearchRequestCopyWith<$Res>  {
  factory $VibeSearchRequestCopyWith(VibeSearchRequest value, $Res Function(VibeSearchRequest) _then) = _$VibeSearchRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: VibeSearchRequest._read_limit, toJson: VibeSearchRequest._write_limit) int? limit,@JsonKey(disallowNullValue: true, includeIfNull: false) num? minSimilarity,@JsonKey(required: true, disallowNullValue: true) String query,@JsonKey(readValue: VibeSearchRequest._extras, fromJson: VibeSearchRequest._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$VibeSearchRequestCopyWithImpl<$Res>
    implements $VibeSearchRequestCopyWith<$Res> {
  _$VibeSearchRequestCopyWithImpl(this._self, this._then);

  final VibeSearchRequest _self;
  final $Res Function(VibeSearchRequest) _then;

/// Create a copy of VibeSearchRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? limit = freezed,Object? minSimilarity = freezed,Object? query = null,Object? additionalProperties = null,}) {
  return _then(VibeSearchRequest(
limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int?,minSimilarity: freezed == minSimilarity ? _self.minSimilarity : minSimilarity // ignore: cast_nullable_to_non_nullable
as num?,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [VibeSearchRequest].
extension VibeSearchRequestPatterns on VibeSearchRequest {
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
