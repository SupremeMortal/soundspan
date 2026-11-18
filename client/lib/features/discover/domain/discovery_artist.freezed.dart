// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discovery_artist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DiscoveryArtist {

/// The artist name.
 String get name;/// The value to pass to the cover-art endpoint, if any.
 String? get artworkRef;/// The id of the artist in the user's library, when the payload names
/// one; null for an artist the library does not hold.
 String? get libraryArtistId;
/// Create a copy of DiscoveryArtist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscoveryArtistCopyWith<DiscoveryArtist> get copyWith => _$DiscoveryArtistCopyWithImpl<DiscoveryArtist>(this as DiscoveryArtist, _$identity);

  /// Serializes this DiscoveryArtist to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DiscoveryArtist;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscoveryArtist&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.artworkRef, _this.artworkRef) || other.artworkRef == _this.artworkRef)&&(identical(other.libraryArtistId, _this.libraryArtistId) || other.libraryArtistId == _this.libraryArtistId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DiscoveryArtist;
  return Object.hash(runtimeType,_this.name,_this.artworkRef,_this.libraryArtistId);
}

@override
String toString() {
  final _this = this as DiscoveryArtist;
  return 'DiscoveryArtist(name: ${_this.name}, artworkRef: ${_this.artworkRef}, libraryArtistId: ${_this.libraryArtistId})';
}


}

/// @nodoc
abstract mixin class $DiscoveryArtistCopyWith<$Res>  {
  factory $DiscoveryArtistCopyWith(DiscoveryArtist value, $Res Function(DiscoveryArtist) _then) = _$DiscoveryArtistCopyWithImpl;
@useResult
$Res call({
 String name, String? artworkRef, String? libraryArtistId
});




}
/// @nodoc
class _$DiscoveryArtistCopyWithImpl<$Res>
    implements $DiscoveryArtistCopyWith<$Res> {
  _$DiscoveryArtistCopyWithImpl(this._self, this._then);

  final DiscoveryArtist _self;
  final $Res Function(DiscoveryArtist) _then;

/// Create a copy of DiscoveryArtist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? artworkRef = freezed,Object? libraryArtistId = freezed,}) {
  return _then(DiscoveryArtist(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,libraryArtistId: freezed == libraryArtistId ? _self.libraryArtistId : libraryArtistId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DiscoveryArtist].
extension DiscoveryArtistPatterns on DiscoveryArtist {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiscoveryArtist value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiscoveryArtist() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiscoveryArtist value)  $default,){
final _that = this;
switch (_that) {
case _DiscoveryArtist():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiscoveryArtist value)?  $default,){
final _that = this;
switch (_that) {
case _DiscoveryArtist() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? artworkRef,  String? libraryArtistId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiscoveryArtist() when $default != null:
return $default(_that.name,_that.artworkRef,_that.libraryArtistId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? artworkRef,  String? libraryArtistId)  $default,) {final _that = this;
switch (_that) {
case _DiscoveryArtist():
return $default(_that.name,_that.artworkRef,_that.libraryArtistId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? artworkRef,  String? libraryArtistId)?  $default,) {final _that = this;
switch (_that) {
case _DiscoveryArtist() when $default != null:
return $default(_that.name,_that.artworkRef,_that.libraryArtistId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DiscoveryArtist implements DiscoveryArtist {
  const _DiscoveryArtist({required this.name, this.artworkRef, this.libraryArtistId});
  factory _DiscoveryArtist.fromJson(Map<String, dynamic> json) => _$DiscoveryArtistFromJson(json);

/// The artist name.
@override final  String name;
/// The value to pass to the cover-art endpoint, if any.
@override final  String? artworkRef;
/// The id of the artist in the user's library, when the payload names
/// one; null for an artist the library does not hold.
@override final  String? libraryArtistId;

/// Create a copy of DiscoveryArtist
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiscoveryArtistCopyWith<_DiscoveryArtist> get copyWith => __$DiscoveryArtistCopyWithImpl<_DiscoveryArtist>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DiscoveryArtistToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiscoveryArtist&&(identical(other.name, name) || other.name == name)&&(identical(other.artworkRef, artworkRef) || other.artworkRef == artworkRef)&&(identical(other.libraryArtistId, libraryArtistId) || other.libraryArtistId == libraryArtistId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,artworkRef,libraryArtistId);
}

@override
String toString() {
    return 'DiscoveryArtist(name: $name, artworkRef: $artworkRef, libraryArtistId: $libraryArtistId)';
}


}

/// @nodoc
abstract mixin class _$DiscoveryArtistCopyWith<$Res> implements $DiscoveryArtistCopyWith<$Res> {
  factory _$DiscoveryArtistCopyWith(_DiscoveryArtist value, $Res Function(_DiscoveryArtist) _then) = __$DiscoveryArtistCopyWithImpl;
@override @useResult
$Res call({
 String name, String? artworkRef, String? libraryArtistId
});




}
/// @nodoc
class __$DiscoveryArtistCopyWithImpl<$Res>
    implements _$DiscoveryArtistCopyWith<$Res> {
  __$DiscoveryArtistCopyWithImpl(this._self, this._then);

  final _DiscoveryArtist _self;
  final $Res Function(_DiscoveryArtist) _then;

/// Create a copy of DiscoveryArtist
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? artworkRef = freezed,Object? libraryArtistId = freezed,}) {
  return _then(_DiscoveryArtist(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,libraryArtistId: freezed == libraryArtistId ? _self.libraryArtistId : libraryArtistId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
