// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_query.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LikedCursor {

/// When the last track of the page was liked, in UTC.
 DateTime get likedAt;/// The id of the last track of the page.
 String get trackId;
/// Create a copy of LikedCursor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LikedCursorCopyWith<LikedCursor> get copyWith => _$LikedCursorCopyWithImpl<LikedCursor>(this as LikedCursor, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LikedCursor;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LikedCursor&&(identical(other.likedAt, _this.likedAt) || other.likedAt == _this.likedAt)&&(identical(other.trackId, _this.trackId) || other.trackId == _this.trackId));
}


@override
int get hashCode {
  final _this = this as LikedCursor;
  return Object.hash(runtimeType,_this.likedAt,_this.trackId);
}

@override
String toString() {
  final _this = this as LikedCursor;
  return 'LikedCursor(likedAt: ${_this.likedAt}, trackId: ${_this.trackId})';
}


}

/// @nodoc
abstract mixin class $LikedCursorCopyWith<$Res>  {
  factory $LikedCursorCopyWith(LikedCursor value, $Res Function(LikedCursor) _then) = _$LikedCursorCopyWithImpl;
@useResult
$Res call({
 DateTime likedAt, String trackId
});




}
/// @nodoc
class _$LikedCursorCopyWithImpl<$Res>
    implements $LikedCursorCopyWith<$Res> {
  _$LikedCursorCopyWithImpl(this._self, this._then);

  final LikedCursor _self;
  final $Res Function(LikedCursor) _then;

/// Create a copy of LikedCursor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? likedAt = null,Object? trackId = null,}) {
  return _then(LikedCursor(
likedAt: null == likedAt ? _self.likedAt : likedAt // ignore: cast_nullable_to_non_nullable
as DateTime,trackId: null == trackId ? _self.trackId : trackId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LikedCursor].
extension LikedCursorPatterns on LikedCursor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LikedCursor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LikedCursor() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LikedCursor value)  $default,){
final _that = this;
switch (_that) {
case _LikedCursor():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LikedCursor value)?  $default,){
final _that = this;
switch (_that) {
case _LikedCursor() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime likedAt,  String trackId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LikedCursor() when $default != null:
return $default(_that.likedAt,_that.trackId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime likedAt,  String trackId)  $default,) {final _that = this;
switch (_that) {
case _LikedCursor():
return $default(_that.likedAt,_that.trackId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime likedAt,  String trackId)?  $default,) {final _that = this;
switch (_that) {
case _LikedCursor() when $default != null:
return $default(_that.likedAt,_that.trackId);case _:
  return null;

}
}

}

/// @nodoc


class _LikedCursor implements LikedCursor {
  const _LikedCursor({required this.likedAt, required this.trackId});
  

/// When the last track of the page was liked, in UTC.
@override final  DateTime likedAt;
/// The id of the last track of the page.
@override final  String trackId;

/// Create a copy of LikedCursor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LikedCursorCopyWith<_LikedCursor> get copyWith => __$LikedCursorCopyWithImpl<_LikedCursor>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LikedCursor&&(identical(other.likedAt, likedAt) || other.likedAt == likedAt)&&(identical(other.trackId, trackId) || other.trackId == trackId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,likedAt,trackId);
}

@override
String toString() {
    return 'LikedCursor(likedAt: $likedAt, trackId: $trackId)';
}


}

/// @nodoc
abstract mixin class _$LikedCursorCopyWith<$Res> implements $LikedCursorCopyWith<$Res> {
  factory _$LikedCursorCopyWith(_LikedCursor value, $Res Function(_LikedCursor) _then) = __$LikedCursorCopyWithImpl;
@override @useResult
$Res call({
 DateTime likedAt, String trackId
});




}
/// @nodoc
class __$LikedCursorCopyWithImpl<$Res>
    implements _$LikedCursorCopyWith<$Res> {
  __$LikedCursorCopyWithImpl(this._self, this._then);

  final _LikedCursor _self;
  final $Res Function(_LikedCursor) _then;

/// Create a copy of LikedCursor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? likedAt = null,Object? trackId = null,}) {
  return _then(_LikedCursor(
likedAt: null == likedAt ? _self.likedAt : likedAt // ignore: cast_nullable_to_non_nullable
as DateTime,trackId: null == trackId ? _self.trackId : trackId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
