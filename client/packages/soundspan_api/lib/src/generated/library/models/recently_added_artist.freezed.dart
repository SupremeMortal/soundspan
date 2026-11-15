// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recently_added_artist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecentlyAddedArtist {


/// Create a copy of RecentlyAddedArtist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentlyAddedArtistCopyWith<RecentlyAddedArtist> get copyWith => _$RecentlyAddedArtistCopyWithImpl<RecentlyAddedArtist>(this as RecentlyAddedArtist, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RecentlyAddedArtist;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentlyAddedArtist&&(identical(other.albumCount, _this.albumCount) || other.albumCount == _this.albumCount)&&(identical(other.coverArt, _this.coverArt) || other.coverArt == _this.coverArt)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.mbid, _this.mbid) || other.mbid == _this.mbid)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as RecentlyAddedArtist;
  return Object.hash(runtimeType,_this.albumCount,_this.coverArt,_this.id,_this.mbid,_this.name,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as RecentlyAddedArtist;
  return 'RecentlyAddedArtist(albumCount: ${_this.albumCount}, coverArt: ${_this.coverArt}, id: ${_this.id}, mbid: ${_this.mbid}, name: ${_this.name}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $RecentlyAddedArtistCopyWith<$Res>  {
  factory $RecentlyAddedArtistCopyWith(RecentlyAddedArtist value, $Res Function(RecentlyAddedArtist) _then) = _$RecentlyAddedArtistCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true, fromJson: RecentlyAddedArtist._read_albumCount, toJson: RecentlyAddedArtist._write_albumCount) int albumCount,@JsonKey(required: true) String? coverArt,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true) String? mbid,@JsonKey(required: true, disallowNullValue: true) String name,@JsonKey(readValue: RecentlyAddedArtist._extras, fromJson: RecentlyAddedArtist._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$RecentlyAddedArtistCopyWithImpl<$Res>
    implements $RecentlyAddedArtistCopyWith<$Res> {
  _$RecentlyAddedArtistCopyWithImpl(this._self, this._then);

  final RecentlyAddedArtist _self;
  final $Res Function(RecentlyAddedArtist) _then;

/// Create a copy of RecentlyAddedArtist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? albumCount = null,Object? coverArt = freezed,Object? id = null,Object? mbid = freezed,Object? name = null,Object? additionalProperties = null,}) {
  return _then(RecentlyAddedArtist(
albumCount: null == albumCount ? _self.albumCount : albumCount // ignore: cast_nullable_to_non_nullable
as int,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mbid: freezed == mbid ? _self.mbid : mbid // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [RecentlyAddedArtist].
extension RecentlyAddedArtistPatterns on RecentlyAddedArtist {
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
