// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'liked_tracks_pagination.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LikedTracksPagination {


/// Create a copy of LikedTracksPagination
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LikedTracksPaginationCopyWith<LikedTracksPagination> get copyWith => _$LikedTracksPaginationCopyWithImpl<LikedTracksPagination>(this as LikedTracksPagination, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LikedTracksPagination;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LikedTracksPagination&&(identical(other.hasMore, _this.hasMore) || other.hasMore == _this.hasMore)&&(identical(other.limit, _this.limit) || other.limit == _this.limit)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as LikedTracksPagination;
  return Object.hash(runtimeType,_this.hasMore,_this.limit,_this.nextCursor,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as LikedTracksPagination;
  return 'LikedTracksPagination(hasMore: ${_this.hasMore}, limit: ${_this.limit}, nextCursor: ${_this.nextCursor}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $LikedTracksPaginationCopyWith<$Res>  {
  factory $LikedTracksPaginationCopyWith(LikedTracksPagination value, $Res Function(LikedTracksPagination) _then) = _$LikedTracksPaginationCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) bool hasMore,@JsonKey(required: true, disallowNullValue: true, fromJson: LikedTracksPagination._read_limit, toJson: LikedTracksPagination._write_limit) int limit,@JsonKey(required: true, disallowNullValue: true) LikedTracksCursor nextCursor,@JsonKey(readValue: LikedTracksPagination._extras, fromJson: LikedTracksPagination._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$LikedTracksCursorCopyWith<$Res> get nextCursor;

}
/// @nodoc
class _$LikedTracksPaginationCopyWithImpl<$Res>
    implements $LikedTracksPaginationCopyWith<$Res> {
  _$LikedTracksPaginationCopyWithImpl(this._self, this._then);

  final LikedTracksPagination _self;
  final $Res Function(LikedTracksPagination) _then;

/// Create a copy of LikedTracksPagination
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hasMore = null,Object? limit = null,Object? nextCursor = null,Object? additionalProperties = null,}) {
  return _then(LikedTracksPagination(
hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,nextCursor: null == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as LikedTracksCursor,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of LikedTracksPagination
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LikedTracksCursorCopyWith<$Res> get nextCursor {
  
  return $LikedTracksCursorCopyWith<$Res>(_self.nextCursor, (value) {
    return _then(_self.copyWith(nextCursor: value));
  });
}
}


/// Adds pattern-matching-related methods to [LikedTracksPagination].
extension LikedTracksPaginationPatterns on LikedTracksPagination {
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
