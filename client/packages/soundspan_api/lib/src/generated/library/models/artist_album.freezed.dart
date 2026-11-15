// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist_album.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ArtistAlbum {


/// Create a copy of ArtistAlbum
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistAlbumCopyWith<ArtistAlbum> get copyWith => _$ArtistAlbumCopyWithImpl<ArtistAlbum>(this as ArtistAlbum, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ArtistAlbum;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistAlbum&&(identical(other.artistId, _this.artistId) || other.artistId == _this.artistId)&&(identical(other.coverArt, _this.coverArt) || other.coverArt == _this.coverArt)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.owned, _this.owned) || other.owned == _this.owned)&&(identical(other.peer, _this.peer) || other.peer == _this.peer)&&(identical(other.provenanceSource, _this.provenanceSource) || other.provenanceSource == _this.provenanceSource)&&const DeepCollectionEquality().equals(other.remoteSources, _this.remoteSources)&&(identical(other.rgMbid, _this.rgMbid) || other.rgMbid == _this.rgMbid)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.tracks, _this.tracks)&&(identical(other.year, _this.year) || other.year == _this.year)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as ArtistAlbum;
  return Object.hash(runtimeType,_this.artistId,_this.coverArt,_this.id,_this.owned,_this.peer,_this.provenanceSource,const DeepCollectionEquality().hash(_this.remoteSources),_this.rgMbid,_this.source,_this.title,const DeepCollectionEquality().hash(_this.tracks),_this.year,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as ArtistAlbum;
  return 'ArtistAlbum(artistId: ${_this.artistId}, coverArt: ${_this.coverArt}, id: ${_this.id}, owned: ${_this.owned}, peer: ${_this.peer}, provenanceSource: ${_this.provenanceSource}, remoteSources: ${_this.remoteSources}, rgMbid: ${_this.rgMbid}, source: ${_this.source}, title: ${_this.title}, tracks: ${_this.tracks}, year: ${_this.year}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $ArtistAlbumCopyWith<$Res>  {
  factory $ArtistAlbumCopyWith(ArtistAlbum value, $Res Function(ArtistAlbum) _then) = _$ArtistAlbumCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String artistId,@JsonKey(required: true) String? coverArt,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true, disallowNullValue: true) bool owned,@JsonKey(includeIfNull: false) PeerRef? peer,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: ArtistAlbum._read_provenanceSource, toJson: ArtistAlbum._write_provenanceSource) ArtistAlbumProvenanceSource? provenanceSource,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: ArtistAlbum._read_remoteSources, toJson: ArtistAlbum._write_remoteSources) List<RemoteProvider>? remoteSources,@JsonKey(required: true) String? rgMbid,@JsonKey(required: true, disallowNullValue: true, fromJson: ArtistAlbum._read_source, toJson: ArtistAlbum._write_source) ArtistAlbumSource source,@JsonKey(required: true, disallowNullValue: true) String title,@JsonKey(required: true, disallowNullValue: true) List<TrackSummary> tracks,@JsonKey(required: true, fromJson: ArtistAlbum._read_year, toJson: ArtistAlbum._write_year) int? year,@JsonKey(readValue: ArtistAlbum._extras, fromJson: ArtistAlbum._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$PeerRefCopyWith<$Res>? get peer;

}
/// @nodoc
class _$ArtistAlbumCopyWithImpl<$Res>
    implements $ArtistAlbumCopyWith<$Res> {
  _$ArtistAlbumCopyWithImpl(this._self, this._then);

  final ArtistAlbum _self;
  final $Res Function(ArtistAlbum) _then;

/// Create a copy of ArtistAlbum
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? artistId = null,Object? coverArt = freezed,Object? id = null,Object? owned = null,Object? peer = freezed,Object? provenanceSource = freezed,Object? remoteSources = freezed,Object? rgMbid = freezed,Object? source = null,Object? title = null,Object? tracks = null,Object? year = freezed,Object? additionalProperties = null,}) {
  return _then(ArtistAlbum(
artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,owned: null == owned ? _self.owned : owned // ignore: cast_nullable_to_non_nullable
as bool,peer: freezed == peer ? _self.peer : peer // ignore: cast_nullable_to_non_nullable
as PeerRef?,provenanceSource: freezed == provenanceSource ? _self.provenanceSource : provenanceSource // ignore: cast_nullable_to_non_nullable
as ArtistAlbumProvenanceSource?,remoteSources: freezed == remoteSources ? _self.remoteSources : remoteSources // ignore: cast_nullable_to_non_nullable
as List<RemoteProvider>?,rgMbid: freezed == rgMbid ? _self.rgMbid : rgMbid // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ArtistAlbumSource,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<TrackSummary>,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of ArtistAlbum
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


/// Adds pattern-matching-related methods to [ArtistAlbum].
extension ArtistAlbumPatterns on ArtistAlbum {
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
