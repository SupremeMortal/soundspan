// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'album_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AlbumDetail {


/// Create a copy of AlbumDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlbumDetailCopyWith<AlbumDetail> get copyWith => _$AlbumDetailCopyWithImpl<AlbumDetail>(this as AlbumDetail, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AlbumDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlbumDetail&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&(identical(other.artistId, _this.artistId) || other.artistId == _this.artistId)&&(identical(other.coverArt, _this.coverArt) || other.coverArt == _this.coverArt)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.matchedInLibrary, _this.matchedInLibrary) || other.matchedInLibrary == _this.matchedInLibrary)&&(identical(other.matchedRgMbid, _this.matchedRgMbid) || other.matchedRgMbid == _this.matchedRgMbid)&&(identical(other.owned, _this.owned) || other.owned == _this.owned)&&(identical(other.peer, _this.peer) || other.peer == _this.peer)&&(identical(other.preference, _this.preference) || other.preference == _this.preference)&&const DeepCollectionEquality().equals(other.remoteSources, _this.remoteSources)&&(identical(other.rgMbid, _this.rgMbid) || other.rgMbid == _this.rgMbid)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.tracks, _this.tracks)&&(identical(other.year, _this.year) || other.year == _this.year)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as AlbumDetail;
  return Object.hash(runtimeType,_this.artist,_this.artistId,_this.coverArt,_this.id,_this.matchedInLibrary,_this.matchedRgMbid,_this.owned,_this.peer,_this.preference,const DeepCollectionEquality().hash(_this.remoteSources),_this.rgMbid,_this.source,_this.title,const DeepCollectionEquality().hash(_this.tracks),_this.year,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as AlbumDetail;
  return 'AlbumDetail(artist: ${_this.artist}, artistId: ${_this.artistId}, coverArt: ${_this.coverArt}, id: ${_this.id}, matchedInLibrary: ${_this.matchedInLibrary}, matchedRgMbid: ${_this.matchedRgMbid}, owned: ${_this.owned}, peer: ${_this.peer}, preference: ${_this.preference}, remoteSources: ${_this.remoteSources}, rgMbid: ${_this.rgMbid}, source: ${_this.source}, title: ${_this.title}, tracks: ${_this.tracks}, year: ${_this.year}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $AlbumDetailCopyWith<$Res>  {
  factory $AlbumDetailCopyWith(AlbumDetail value, $Res Function(AlbumDetail) _then) = _$AlbumDetailCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) ArtistRef artist,@JsonKey(required: true, disallowNullValue: true) String artistId,@JsonKey(required: true) String? coverArt,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true, disallowNullValue: true) bool matchedInLibrary,@JsonKey(required: true) String? matchedRgMbid,@JsonKey(required: true, disallowNullValue: true) bool owned,@JsonKey(includeIfNull: false) PeerRef? peer,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: AlbumDetail._read_preference, toJson: AlbumDetail._write_preference) PreferenceState? preference,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: AlbumDetail._read_remoteSources, toJson: AlbumDetail._write_remoteSources) List<RemoteProvider>? remoteSources,@JsonKey(required: true) String? rgMbid,@JsonKey(required: true, disallowNullValue: true, fromJson: AlbumDetail._read_source, toJson: AlbumDetail._write_source) AlbumDetailSource source,@JsonKey(required: true, disallowNullValue: true) String title,@JsonKey(disallowNullValue: true, includeIfNull: false) List<TrackSummary>? tracks,@JsonKey(required: true, fromJson: AlbumDetail._read_year, toJson: AlbumDetail._write_year) int? year,@JsonKey(readValue: AlbumDetail._extras, fromJson: AlbumDetail._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$ArtistRefCopyWith<$Res> get artist;$PeerRefCopyWith<$Res>? get peer;

}
/// @nodoc
class _$AlbumDetailCopyWithImpl<$Res>
    implements $AlbumDetailCopyWith<$Res> {
  _$AlbumDetailCopyWithImpl(this._self, this._then);

  final AlbumDetail _self;
  final $Res Function(AlbumDetail) _then;

/// Create a copy of AlbumDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? artist = null,Object? artistId = null,Object? coverArt = freezed,Object? id = null,Object? matchedInLibrary = null,Object? matchedRgMbid = freezed,Object? owned = null,Object? peer = freezed,Object? preference = freezed,Object? remoteSources = freezed,Object? rgMbid = freezed,Object? source = null,Object? title = null,Object? tracks = freezed,Object? year = freezed,Object? additionalProperties = null,}) {
  return _then(AlbumDetail(
artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as ArtistRef,artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,matchedInLibrary: null == matchedInLibrary ? _self.matchedInLibrary : matchedInLibrary // ignore: cast_nullable_to_non_nullable
as bool,matchedRgMbid: freezed == matchedRgMbid ? _self.matchedRgMbid : matchedRgMbid // ignore: cast_nullable_to_non_nullable
as String?,owned: null == owned ? _self.owned : owned // ignore: cast_nullable_to_non_nullable
as bool,peer: freezed == peer ? _self.peer : peer // ignore: cast_nullable_to_non_nullable
as PeerRef?,preference: freezed == preference ? _self.preference : preference // ignore: cast_nullable_to_non_nullable
as PreferenceState?,remoteSources: freezed == remoteSources ? _self.remoteSources : remoteSources // ignore: cast_nullable_to_non_nullable
as List<RemoteProvider>?,rgMbid: freezed == rgMbid ? _self.rgMbid : rgMbid // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as AlbumDetailSource,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,tracks: freezed == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<TrackSummary>?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of AlbumDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistRefCopyWith<$Res> get artist {
  
  return $ArtistRefCopyWith<$Res>(_self.artist, (value) {
    return _then(_self.copyWith(artist: value));
  });
}/// Create a copy of AlbumDetail
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


/// Adds pattern-matching-related methods to [AlbumDetail].
extension AlbumDetailPatterns on AlbumDetail {
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
