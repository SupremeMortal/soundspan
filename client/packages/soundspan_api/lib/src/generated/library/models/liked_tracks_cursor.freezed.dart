// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'liked_tracks_cursor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LikedTracksCursor {


/// Create a copy of LikedTracksCursor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LikedTracksCursorCopyWith<LikedTracksCursor> get copyWith => _$LikedTracksCursorCopyWithImpl<LikedTracksCursor>(this as LikedTracksCursor, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LikedTracksCursor;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LikedTracksCursor&&(identical(other.likedAt, _this.likedAt) || other.likedAt == _this.likedAt)&&(identical(other.trackId, _this.trackId) || other.trackId == _this.trackId)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as LikedTracksCursor;
  return Object.hash(runtimeType,_this.likedAt,_this.trackId,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as LikedTracksCursor;
  return 'LikedTracksCursor(likedAt: ${_this.likedAt}, trackId: ${_this.trackId}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $LikedTracksCursorCopyWith<$Res>  {
  factory $LikedTracksCursorCopyWith(LikedTracksCursor value, $Res Function(LikedTracksCursor) _then) = _$LikedTracksCursorCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true, fromJson: LikedTracksCursor._read_likedAt, toJson: LikedTracksCursor._write_likedAt) DateTime likedAt,@JsonKey(required: true, disallowNullValue: true) String trackId,@JsonKey(readValue: LikedTracksCursor._extras, fromJson: LikedTracksCursor._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$LikedTracksCursorCopyWithImpl<$Res>
    implements $LikedTracksCursorCopyWith<$Res> {
  _$LikedTracksCursorCopyWithImpl(this._self, this._then);

  final LikedTracksCursor _self;
  final $Res Function(LikedTracksCursor) _then;

/// Create a copy of LikedTracksCursor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? likedAt = null,Object? trackId = null,Object? additionalProperties = null,}) {
  return _then(LikedTracksCursor(
likedAt: null == likedAt ? _self.likedAt : likedAt // ignore: cast_nullable_to_non_nullable
as DateTime,trackId: null == trackId ? _self.trackId : trackId // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [LikedTracksCursor].
extension LikedTracksCursorPatterns on LikedTracksCursor {
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
