// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'album_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AlbumSummary {


/// Create a copy of AlbumSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlbumSummaryCopyWith<AlbumSummary> get copyWith => _$AlbumSummaryCopyWithImpl<AlbumSummary>(this as AlbumSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AlbumSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlbumSummary&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&(identical(other.artistId, _this.artistId) || other.artistId == _this.artistId)&&(identical(other.coverArt, _this.coverArt) || other.coverArt == _this.coverArt)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.peer, _this.peer) || other.peer == _this.peer)&&const DeepCollectionEquality().equals(other.remoteSources, _this.remoteSources)&&(identical(other.rgMbid, _this.rgMbid) || other.rgMbid == _this.rgMbid)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.year, _this.year) || other.year == _this.year)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as AlbumSummary;
  return Object.hash(runtimeType,_this.artist,_this.artistId,_this.coverArt,_this.id,_this.peer,const DeepCollectionEquality().hash(_this.remoteSources),_this.rgMbid,_this.source,_this.title,_this.year,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as AlbumSummary;
  return 'AlbumSummary(artist: ${_this.artist}, artistId: ${_this.artistId}, coverArt: ${_this.coverArt}, id: ${_this.id}, peer: ${_this.peer}, remoteSources: ${_this.remoteSources}, rgMbid: ${_this.rgMbid}, source: ${_this.source}, title: ${_this.title}, year: ${_this.year}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $AlbumSummaryCopyWith<$Res>  {
  factory $AlbumSummaryCopyWith(AlbumSummary value, $Res Function(AlbumSummary) _then) = _$AlbumSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) ArtistRef artist,@JsonKey(required: true, disallowNullValue: true) String artistId,@JsonKey(required: true) String? coverArt,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(includeIfNull: false) PeerRef? peer,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: AlbumSummary._read_remoteSources, toJson: AlbumSummary._write_remoteSources) List<RemoteProvider>? remoteSources,@JsonKey(required: true) String? rgMbid,@JsonKey(required: true, disallowNullValue: true, fromJson: AlbumSummary._read_source, toJson: AlbumSummary._write_source) AlbumSummarySource source,@JsonKey(required: true, disallowNullValue: true) String title,@JsonKey(required: true, fromJson: AlbumSummary._read_year, toJson: AlbumSummary._write_year) int? year,@JsonKey(readValue: AlbumSummary._extras, fromJson: AlbumSummary._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$ArtistRefCopyWith<$Res> get artist;$PeerRefCopyWith<$Res>? get peer;

}
/// @nodoc
class _$AlbumSummaryCopyWithImpl<$Res>
    implements $AlbumSummaryCopyWith<$Res> {
  _$AlbumSummaryCopyWithImpl(this._self, this._then);

  final AlbumSummary _self;
  final $Res Function(AlbumSummary) _then;

/// Create a copy of AlbumSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? artist = null,Object? artistId = null,Object? coverArt = freezed,Object? id = null,Object? peer = freezed,Object? remoteSources = freezed,Object? rgMbid = freezed,Object? source = null,Object? title = null,Object? year = freezed,Object? additionalProperties = null,}) {
  return _then(AlbumSummary(
artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as ArtistRef,artistId: null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,peer: freezed == peer ? _self.peer : peer // ignore: cast_nullable_to_non_nullable
as PeerRef?,remoteSources: freezed == remoteSources ? _self.remoteSources : remoteSources // ignore: cast_nullable_to_non_nullable
as List<RemoteProvider>?,rgMbid: freezed == rgMbid ? _self.rgMbid : rgMbid // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as AlbumSummarySource,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of AlbumSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistRefCopyWith<$Res> get artist {
  
  return $ArtistRefCopyWith<$Res>(_self.artist, (value) {
    return _then(_self.copyWith(artist: value));
  });
}/// Create a copy of AlbumSummary
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


/// Adds pattern-matching-related methods to [AlbumSummary].
extension AlbumSummaryPatterns on AlbumSummary {
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
