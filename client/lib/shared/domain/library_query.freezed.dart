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

/// @nodoc
mixin _$AlbumQuery {

/// Only the albums of this artist.
 String? get artistId;/// Which albums.
 AlbumFilter? get filter;/// The order.
 AlbumSort? get sortBy;/// Which part of the library.
 LibraryOrigin? get origin;
/// Create a copy of AlbumQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlbumQueryCopyWith<AlbumQuery> get copyWith => _$AlbumQueryCopyWithImpl<AlbumQuery>(this as AlbumQuery, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AlbumQuery;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlbumQuery&&(identical(other.artistId, _this.artistId) || other.artistId == _this.artistId)&&(identical(other.filter, _this.filter) || other.filter == _this.filter)&&(identical(other.sortBy, _this.sortBy) || other.sortBy == _this.sortBy)&&(identical(other.origin, _this.origin) || other.origin == _this.origin));
}


@override
int get hashCode {
  final _this = this as AlbumQuery;
  return Object.hash(runtimeType,_this.artistId,_this.filter,_this.sortBy,_this.origin);
}

@override
String toString() {
  final _this = this as AlbumQuery;
  return 'AlbumQuery(artistId: ${_this.artistId}, filter: ${_this.filter}, sortBy: ${_this.sortBy}, origin: ${_this.origin})';
}


}

/// @nodoc
abstract mixin class $AlbumQueryCopyWith<$Res>  {
  factory $AlbumQueryCopyWith(AlbumQuery value, $Res Function(AlbumQuery) _then) = _$AlbumQueryCopyWithImpl;
@useResult
$Res call({
 String? artistId, AlbumFilter? filter, AlbumSort? sortBy, LibraryOrigin? origin
});




}
/// @nodoc
class _$AlbumQueryCopyWithImpl<$Res>
    implements $AlbumQueryCopyWith<$Res> {
  _$AlbumQueryCopyWithImpl(this._self, this._then);

  final AlbumQuery _self;
  final $Res Function(AlbumQuery) _then;

/// Create a copy of AlbumQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? artistId = freezed,Object? filter = freezed,Object? sortBy = freezed,Object? origin = freezed,}) {
  return _then(AlbumQuery(
artistId: freezed == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String?,filter: freezed == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as AlbumFilter?,sortBy: freezed == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as AlbumSort?,origin: freezed == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as LibraryOrigin?,
  ));
}

}


/// Adds pattern-matching-related methods to [AlbumQuery].
extension AlbumQueryPatterns on AlbumQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AlbumQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AlbumQuery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AlbumQuery value)  $default,){
final _that = this;
switch (_that) {
case _AlbumQuery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AlbumQuery value)?  $default,){
final _that = this;
switch (_that) {
case _AlbumQuery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? artistId,  AlbumFilter? filter,  AlbumSort? sortBy,  LibraryOrigin? origin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AlbumQuery() when $default != null:
return $default(_that.artistId,_that.filter,_that.sortBy,_that.origin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? artistId,  AlbumFilter? filter,  AlbumSort? sortBy,  LibraryOrigin? origin)  $default,) {final _that = this;
switch (_that) {
case _AlbumQuery():
return $default(_that.artistId,_that.filter,_that.sortBy,_that.origin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? artistId,  AlbumFilter? filter,  AlbumSort? sortBy,  LibraryOrigin? origin)?  $default,) {final _that = this;
switch (_that) {
case _AlbumQuery() when $default != null:
return $default(_that.artistId,_that.filter,_that.sortBy,_that.origin);case _:
  return null;

}
}

}

/// @nodoc


class _AlbumQuery extends AlbumQuery {
  const _AlbumQuery({this.artistId, this.filter, this.sortBy, this.origin}): super._();
  

/// Only the albums of this artist.
@override final  String? artistId;
/// Which albums.
@override final  AlbumFilter? filter;
/// The order.
@override final  AlbumSort? sortBy;
/// Which part of the library.
@override final  LibraryOrigin? origin;

/// Create a copy of AlbumQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlbumQueryCopyWith<_AlbumQuery> get copyWith => __$AlbumQueryCopyWithImpl<_AlbumQuery>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AlbumQuery&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&(identical(other.origin, origin) || other.origin == origin));
}


@override
int get hashCode {
    return Object.hash(runtimeType,artistId,filter,sortBy,origin);
}

@override
String toString() {
    return 'AlbumQuery(artistId: $artistId, filter: $filter, sortBy: $sortBy, origin: $origin)';
}


}

/// @nodoc
abstract mixin class _$AlbumQueryCopyWith<$Res> implements $AlbumQueryCopyWith<$Res> {
  factory _$AlbumQueryCopyWith(_AlbumQuery value, $Res Function(_AlbumQuery) _then) = __$AlbumQueryCopyWithImpl;
@override @useResult
$Res call({
 String? artistId, AlbumFilter? filter, AlbumSort? sortBy, LibraryOrigin? origin
});




}
/// @nodoc
class __$AlbumQueryCopyWithImpl<$Res>
    implements _$AlbumQueryCopyWith<$Res> {
  __$AlbumQueryCopyWithImpl(this._self, this._then);

  final _AlbumQuery _self;
  final $Res Function(_AlbumQuery) _then;

/// Create a copy of AlbumQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? artistId = freezed,Object? filter = freezed,Object? sortBy = freezed,Object? origin = freezed,}) {
  return _then(_AlbumQuery(
artistId: freezed == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String?,filter: freezed == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as AlbumFilter?,sortBy: freezed == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as AlbumSort?,origin: freezed == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as LibraryOrigin?,
  ));
}


}

/// @nodoc
mixin _$ArtistQuery {

/// Which artists.
 ArtistFilter? get filter;/// The order.
 ArtistSort? get sortBy;/// Which part of the library.
 LibraryOrigin? get origin;
/// Create a copy of ArtistQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistQueryCopyWith<ArtistQuery> get copyWith => _$ArtistQueryCopyWithImpl<ArtistQuery>(this as ArtistQuery, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ArtistQuery;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistQuery&&(identical(other.filter, _this.filter) || other.filter == _this.filter)&&(identical(other.sortBy, _this.sortBy) || other.sortBy == _this.sortBy)&&(identical(other.origin, _this.origin) || other.origin == _this.origin));
}


@override
int get hashCode {
  final _this = this as ArtistQuery;
  return Object.hash(runtimeType,_this.filter,_this.sortBy,_this.origin);
}

@override
String toString() {
  final _this = this as ArtistQuery;
  return 'ArtistQuery(filter: ${_this.filter}, sortBy: ${_this.sortBy}, origin: ${_this.origin})';
}


}

/// @nodoc
abstract mixin class $ArtistQueryCopyWith<$Res>  {
  factory $ArtistQueryCopyWith(ArtistQuery value, $Res Function(ArtistQuery) _then) = _$ArtistQueryCopyWithImpl;
@useResult
$Res call({
 ArtistFilter? filter, ArtistSort? sortBy, LibraryOrigin? origin
});




}
/// @nodoc
class _$ArtistQueryCopyWithImpl<$Res>
    implements $ArtistQueryCopyWith<$Res> {
  _$ArtistQueryCopyWithImpl(this._self, this._then);

  final ArtistQuery _self;
  final $Res Function(ArtistQuery) _then;

/// Create a copy of ArtistQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? filter = freezed,Object? sortBy = freezed,Object? origin = freezed,}) {
  return _then(ArtistQuery(
filter: freezed == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as ArtistFilter?,sortBy: freezed == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as ArtistSort?,origin: freezed == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as LibraryOrigin?,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistQuery].
extension ArtistQueryPatterns on ArtistQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistQuery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistQuery value)  $default,){
final _that = this;
switch (_that) {
case _ArtistQuery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistQuery value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistQuery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ArtistFilter? filter,  ArtistSort? sortBy,  LibraryOrigin? origin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistQuery() when $default != null:
return $default(_that.filter,_that.sortBy,_that.origin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ArtistFilter? filter,  ArtistSort? sortBy,  LibraryOrigin? origin)  $default,) {final _that = this;
switch (_that) {
case _ArtistQuery():
return $default(_that.filter,_that.sortBy,_that.origin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ArtistFilter? filter,  ArtistSort? sortBy,  LibraryOrigin? origin)?  $default,) {final _that = this;
switch (_that) {
case _ArtistQuery() when $default != null:
return $default(_that.filter,_that.sortBy,_that.origin);case _:
  return null;

}
}

}

/// @nodoc


class _ArtistQuery extends ArtistQuery {
  const _ArtistQuery({this.filter, this.sortBy, this.origin}): super._();
  

/// Which artists.
@override final  ArtistFilter? filter;
/// The order.
@override final  ArtistSort? sortBy;
/// Which part of the library.
@override final  LibraryOrigin? origin;

/// Create a copy of ArtistQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistQueryCopyWith<_ArtistQuery> get copyWith => __$ArtistQueryCopyWithImpl<_ArtistQuery>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistQuery&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&(identical(other.origin, origin) || other.origin == origin));
}


@override
int get hashCode {
    return Object.hash(runtimeType,filter,sortBy,origin);
}

@override
String toString() {
    return 'ArtistQuery(filter: $filter, sortBy: $sortBy, origin: $origin)';
}


}

/// @nodoc
abstract mixin class _$ArtistQueryCopyWith<$Res> implements $ArtistQueryCopyWith<$Res> {
  factory _$ArtistQueryCopyWith(_ArtistQuery value, $Res Function(_ArtistQuery) _then) = __$ArtistQueryCopyWithImpl;
@override @useResult
$Res call({
 ArtistFilter? filter, ArtistSort? sortBy, LibraryOrigin? origin
});




}
/// @nodoc
class __$ArtistQueryCopyWithImpl<$Res>
    implements _$ArtistQueryCopyWith<$Res> {
  __$ArtistQueryCopyWithImpl(this._self, this._then);

  final _ArtistQuery _self;
  final $Res Function(_ArtistQuery) _then;

/// Create a copy of ArtistQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? filter = freezed,Object? sortBy = freezed,Object? origin = freezed,}) {
  return _then(_ArtistQuery(
filter: freezed == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as ArtistFilter?,sortBy: freezed == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as ArtistSort?,origin: freezed == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as LibraryOrigin?,
  ));
}


}

/// @nodoc
mixin _$TrackQuery {

/// Only the tracks of this album.
 String? get albumId;/// The order.
 TrackSort? get sortBy;/// Which part of the library.
 LibraryOrigin? get origin;
/// Create a copy of TrackQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackQueryCopyWith<TrackQuery> get copyWith => _$TrackQueryCopyWithImpl<TrackQuery>(this as TrackQuery, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TrackQuery;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackQuery&&(identical(other.albumId, _this.albumId) || other.albumId == _this.albumId)&&(identical(other.sortBy, _this.sortBy) || other.sortBy == _this.sortBy)&&(identical(other.origin, _this.origin) || other.origin == _this.origin));
}


@override
int get hashCode {
  final _this = this as TrackQuery;
  return Object.hash(runtimeType,_this.albumId,_this.sortBy,_this.origin);
}

@override
String toString() {
  final _this = this as TrackQuery;
  return 'TrackQuery(albumId: ${_this.albumId}, sortBy: ${_this.sortBy}, origin: ${_this.origin})';
}


}

/// @nodoc
abstract mixin class $TrackQueryCopyWith<$Res>  {
  factory $TrackQueryCopyWith(TrackQuery value, $Res Function(TrackQuery) _then) = _$TrackQueryCopyWithImpl;
@useResult
$Res call({
 String? albumId, TrackSort? sortBy, LibraryOrigin? origin
});




}
/// @nodoc
class _$TrackQueryCopyWithImpl<$Res>
    implements $TrackQueryCopyWith<$Res> {
  _$TrackQueryCopyWithImpl(this._self, this._then);

  final TrackQuery _self;
  final $Res Function(TrackQuery) _then;

/// Create a copy of TrackQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? albumId = freezed,Object? sortBy = freezed,Object? origin = freezed,}) {
  return _then(TrackQuery(
albumId: freezed == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String?,sortBy: freezed == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as TrackSort?,origin: freezed == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as LibraryOrigin?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrackQuery].
extension TrackQueryPatterns on TrackQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackQuery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackQuery value)  $default,){
final _that = this;
switch (_that) {
case _TrackQuery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackQuery value)?  $default,){
final _that = this;
switch (_that) {
case _TrackQuery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? albumId,  TrackSort? sortBy,  LibraryOrigin? origin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackQuery() when $default != null:
return $default(_that.albumId,_that.sortBy,_that.origin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? albumId,  TrackSort? sortBy,  LibraryOrigin? origin)  $default,) {final _that = this;
switch (_that) {
case _TrackQuery():
return $default(_that.albumId,_that.sortBy,_that.origin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? albumId,  TrackSort? sortBy,  LibraryOrigin? origin)?  $default,) {final _that = this;
switch (_that) {
case _TrackQuery() when $default != null:
return $default(_that.albumId,_that.sortBy,_that.origin);case _:
  return null;

}
}

}

/// @nodoc


class _TrackQuery extends TrackQuery {
  const _TrackQuery({this.albumId, this.sortBy, this.origin}): super._();
  

/// Only the tracks of this album.
@override final  String? albumId;
/// The order.
@override final  TrackSort? sortBy;
/// Which part of the library.
@override final  LibraryOrigin? origin;

/// Create a copy of TrackQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackQueryCopyWith<_TrackQuery> get copyWith => __$TrackQueryCopyWithImpl<_TrackQuery>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackQuery&&(identical(other.albumId, albumId) || other.albumId == albumId)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&(identical(other.origin, origin) || other.origin == origin));
}


@override
int get hashCode {
    return Object.hash(runtimeType,albumId,sortBy,origin);
}

@override
String toString() {
    return 'TrackQuery(albumId: $albumId, sortBy: $sortBy, origin: $origin)';
}


}

/// @nodoc
abstract mixin class _$TrackQueryCopyWith<$Res> implements $TrackQueryCopyWith<$Res> {
  factory _$TrackQueryCopyWith(_TrackQuery value, $Res Function(_TrackQuery) _then) = __$TrackQueryCopyWithImpl;
@override @useResult
$Res call({
 String? albumId, TrackSort? sortBy, LibraryOrigin? origin
});




}
/// @nodoc
class __$TrackQueryCopyWithImpl<$Res>
    implements _$TrackQueryCopyWith<$Res> {
  __$TrackQueryCopyWithImpl(this._self, this._then);

  final _TrackQuery _self;
  final $Res Function(_TrackQuery) _then;

/// Create a copy of TrackQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? albumId = freezed,Object? sortBy = freezed,Object? origin = freezed,}) {
  return _then(_TrackQuery(
albumId: freezed == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String?,sortBy: freezed == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as TrackSort?,origin: freezed == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as LibraryOrigin?,
  ));
}


}

// dart format on
