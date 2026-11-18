// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'similar_artist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SimilarArtist {


/// Create a copy of SimilarArtist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimilarArtistCopyWith<SimilarArtist> get copyWith => _$SimilarArtistCopyWithImpl<SimilarArtist>(this as SimilarArtist, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SimilarArtist;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimilarArtist&&(identical(other.albumCount, _this.albumCount) || other.albumCount == _this.albumCount)&&(identical(other.coverArt, _this.coverArt) || other.coverArt == _this.coverArt)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.inLibrary, _this.inLibrary) || other.inLibrary == _this.inLibrary)&&(identical(other.mbid, _this.mbid) || other.mbid == _this.mbid)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.ownedAlbumCount, _this.ownedAlbumCount) || other.ownedAlbumCount == _this.ownedAlbumCount)&&(identical(other.weight, _this.weight) || other.weight == _this.weight)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as SimilarArtist;
  return Object.hash(runtimeType,_this.albumCount,_this.coverArt,_this.id,_this.inLibrary,_this.mbid,_this.name,_this.ownedAlbumCount,_this.weight,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as SimilarArtist;
  return 'SimilarArtist(albumCount: ${_this.albumCount}, coverArt: ${_this.coverArt}, id: ${_this.id}, inLibrary: ${_this.inLibrary}, mbid: ${_this.mbid}, name: ${_this.name}, ownedAlbumCount: ${_this.ownedAlbumCount}, weight: ${_this.weight}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $SimilarArtistCopyWith<$Res>  {
  factory $SimilarArtistCopyWith(SimilarArtist value, $Res Function(SimilarArtist) _then) = _$SimilarArtistCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true, fromJson: SimilarArtist._read_albumCount, toJson: SimilarArtist._write_albumCount) int albumCount,@JsonKey(required: true) String? coverArt,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true, disallowNullValue: true) bool inLibrary,@JsonKey(required: true) String? mbid,@JsonKey(required: true, disallowNullValue: true) String name,@JsonKey(required: true, disallowNullValue: true, fromJson: SimilarArtist._read_ownedAlbumCount, toJson: SimilarArtist._write_ownedAlbumCount) int ownedAlbumCount,@JsonKey(required: true, disallowNullValue: true) num weight,@JsonKey(readValue: SimilarArtist._extras, fromJson: SimilarArtist._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$SimilarArtistCopyWithImpl<$Res>
    implements $SimilarArtistCopyWith<$Res> {
  _$SimilarArtistCopyWithImpl(this._self, this._then);

  final SimilarArtist _self;
  final $Res Function(SimilarArtist) _then;

/// Create a copy of SimilarArtist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? albumCount = null,Object? coverArt = freezed,Object? id = null,Object? inLibrary = null,Object? mbid = freezed,Object? name = null,Object? ownedAlbumCount = null,Object? weight = null,Object? additionalProperties = null,}) {
  return _then(SimilarArtist(
albumCount: null == albumCount ? _self.albumCount : albumCount // ignore: cast_nullable_to_non_nullable
as int,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,inLibrary: null == inLibrary ? _self.inLibrary : inLibrary // ignore: cast_nullable_to_non_nullable
as bool,mbid: freezed == mbid ? _self.mbid : mbid // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ownedAlbumCount: null == ownedAlbumCount ? _self.ownedAlbumCount : ownedAlbumCount // ignore: cast_nullable_to_non_nullable
as int,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as num,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [SimilarArtist].
extension SimilarArtistPatterns on SimilarArtist {
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
