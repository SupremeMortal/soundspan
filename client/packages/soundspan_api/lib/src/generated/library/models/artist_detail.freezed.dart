// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ArtistDetail {


/// Create a copy of ArtistDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistDetailCopyWith<ArtistDetail> get copyWith => _$ArtistDetailCopyWithImpl<ArtistDetail>(this as ArtistDetail, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ArtistDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistDetail&&const DeepCollectionEquality().equals(other.albums, _this.albums)&&(identical(other.bio, _this.bio) || other.bio == _this.bio)&&(identical(other.coverArt, _this.coverArt) || other.coverArt == _this.coverArt)&&(identical(other.discographyComplete, _this.discographyComplete) || other.discographyComplete == _this.discographyComplete)&&const DeepCollectionEquality().equals(other.genres, _this.genres)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.mbid, _this.mbid) || other.mbid == _this.mbid)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.peer, _this.peer) || other.peer == _this.peer)&&const DeepCollectionEquality().equals(other.similarArtists, _this.similarArtists)&&(identical(other.source, _this.source) || other.source == _this.source)&&const DeepCollectionEquality().equals(other.topTracks, _this.topTracks)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as ArtistDetail;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.albums),_this.bio,_this.coverArt,_this.discographyComplete,const DeepCollectionEquality().hash(_this.genres),_this.id,_this.mbid,_this.name,_this.peer,const DeepCollectionEquality().hash(_this.similarArtists),_this.source,const DeepCollectionEquality().hash(_this.topTracks),const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as ArtistDetail;
  return 'ArtistDetail(albums: ${_this.albums}, bio: ${_this.bio}, coverArt: ${_this.coverArt}, discographyComplete: ${_this.discographyComplete}, genres: ${_this.genres}, id: ${_this.id}, mbid: ${_this.mbid}, name: ${_this.name}, peer: ${_this.peer}, similarArtists: ${_this.similarArtists}, source: ${_this.source}, topTracks: ${_this.topTracks}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $ArtistDetailCopyWith<$Res>  {
  factory $ArtistDetailCopyWith(ArtistDetail value, $Res Function(ArtistDetail) _then) = _$ArtistDetailCopyWithImpl;
@useResult
$Res call({
@JsonKey(disallowNullValue: true, includeIfNull: false) List<ArtistAlbum>? albums,@JsonKey(required: true) String? bio,@JsonKey(required: true) String? coverArt,@JsonKey(required: true, disallowNullValue: true) bool discographyComplete,@JsonKey(required: true, disallowNullValue: true) List<String> genres,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true) String? mbid,@JsonKey(required: true, disallowNullValue: true) String name,@JsonKey(disallowNullValue: true, includeIfNull: false) PeerRef? peer,@JsonKey(disallowNullValue: true, includeIfNull: false) List<SimilarArtist>? similarArtists,@JsonKey(required: true, disallowNullValue: true, fromJson: ArtistDetail._read_source, toJson: ArtistDetail._write_source) ArtistDetailSource source,@JsonKey(disallowNullValue: true, includeIfNull: false) List<ArtistTopTrack>? topTracks,@JsonKey(readValue: ArtistDetail._extras, fromJson: ArtistDetail._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$PeerRefCopyWith<$Res>? get peer;

}
/// @nodoc
class _$ArtistDetailCopyWithImpl<$Res>
    implements $ArtistDetailCopyWith<$Res> {
  _$ArtistDetailCopyWithImpl(this._self, this._then);

  final ArtistDetail _self;
  final $Res Function(ArtistDetail) _then;

/// Create a copy of ArtistDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? albums = freezed,Object? bio = freezed,Object? coverArt = freezed,Object? discographyComplete = null,Object? genres = null,Object? id = null,Object? mbid = freezed,Object? name = null,Object? peer = freezed,Object? similarArtists = freezed,Object? source = null,Object? topTracks = freezed,Object? additionalProperties = null,}) {
  return _then(ArtistDetail(
albums: freezed == albums ? _self.albums : albums // ignore: cast_nullable_to_non_nullable
as List<ArtistAlbum>?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,discographyComplete: null == discographyComplete ? _self.discographyComplete : discographyComplete // ignore: cast_nullable_to_non_nullable
as bool,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mbid: freezed == mbid ? _self.mbid : mbid // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,peer: freezed == peer ? _self.peer : peer // ignore: cast_nullable_to_non_nullable
as PeerRef?,similarArtists: freezed == similarArtists ? _self.similarArtists : similarArtists // ignore: cast_nullable_to_non_nullable
as List<SimilarArtist>?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ArtistDetailSource,topTracks: freezed == topTracks ? _self.topTracks : topTracks // ignore: cast_nullable_to_non_nullable
as List<ArtistTopTrack>?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of ArtistDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeerRefCopyWith<$Res>? get peer {
    if (_self.peer == null) {
    return null;
  }

  return $PeerRefCopyWith<$Res>(_self.peer!, (value) {
    return _then(_self.copyWith(peer: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArtistDetail].
extension ArtistDetailPatterns on ArtistDetail {
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
