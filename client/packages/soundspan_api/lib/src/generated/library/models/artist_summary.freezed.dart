// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ArtistSummary {


/// Create a copy of ArtistSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistSummaryCopyWith<ArtistSummary> get copyWith => _$ArtistSummaryCopyWithImpl<ArtistSummary>(this as ArtistSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ArtistSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistSummary&&(identical(other.albumCount, _this.albumCount) || other.albumCount == _this.albumCount)&&(identical(other.coverArt, _this.coverArt) || other.coverArt == _this.coverArt)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.mbid, _this.mbid) || other.mbid == _this.mbid)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.peer, _this.peer) || other.peer == _this.peer)&&const DeepCollectionEquality().equals(other.remoteSources, _this.remoteSources)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.trackCount, _this.trackCount) || other.trackCount == _this.trackCount)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as ArtistSummary;
  return Object.hash(runtimeType,_this.albumCount,_this.coverArt,_this.id,_this.mbid,_this.name,_this.peer,const DeepCollectionEquality().hash(_this.remoteSources),_this.source,_this.trackCount,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as ArtistSummary;
  return 'ArtistSummary(albumCount: ${_this.albumCount}, coverArt: ${_this.coverArt}, id: ${_this.id}, mbid: ${_this.mbid}, name: ${_this.name}, peer: ${_this.peer}, remoteSources: ${_this.remoteSources}, source: ${_this.source}, trackCount: ${_this.trackCount}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $ArtistSummaryCopyWith<$Res>  {
  factory $ArtistSummaryCopyWith(ArtistSummary value, $Res Function(ArtistSummary) _then) = _$ArtistSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true, fromJson: ArtistSummary._read_albumCount, toJson: ArtistSummary._write_albumCount) int albumCount,@JsonKey(required: true) String? coverArt,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true) String? mbid,@JsonKey(required: true, disallowNullValue: true) String name,@JsonKey(disallowNullValue: true, includeIfNull: false) PeerRef? peer,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: ArtistSummary._read_remoteSources, toJson: ArtistSummary._write_remoteSources) List<RemoteProvider>? remoteSources,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: ArtistSummary._read_source, toJson: ArtistSummary._write_source) ArtistSummarySource? source,@JsonKey(required: true, disallowNullValue: true, fromJson: ArtistSummary._read_trackCount, toJson: ArtistSummary._write_trackCount) int trackCount,@JsonKey(readValue: ArtistSummary._extras, fromJson: ArtistSummary._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$PeerRefCopyWith<$Res>? get peer;

}
/// @nodoc
class _$ArtistSummaryCopyWithImpl<$Res>
    implements $ArtistSummaryCopyWith<$Res> {
  _$ArtistSummaryCopyWithImpl(this._self, this._then);

  final ArtistSummary _self;
  final $Res Function(ArtistSummary) _then;

/// Create a copy of ArtistSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? albumCount = null,Object? coverArt = freezed,Object? id = null,Object? mbid = freezed,Object? name = null,Object? peer = freezed,Object? remoteSources = freezed,Object? source = freezed,Object? trackCount = null,Object? additionalProperties = null,}) {
  return _then(ArtistSummary(
albumCount: null == albumCount ? _self.albumCount : albumCount // ignore: cast_nullable_to_non_nullable
as int,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mbid: freezed == mbid ? _self.mbid : mbid // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,peer: freezed == peer ? _self.peer : peer // ignore: cast_nullable_to_non_nullable
as PeerRef?,remoteSources: freezed == remoteSources ? _self.remoteSources : remoteSources // ignore: cast_nullable_to_non_nullable
as List<RemoteProvider>?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ArtistSummarySource?,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of ArtistSummary
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


/// Adds pattern-matching-related methods to [ArtistSummary].
extension ArtistSummaryPatterns on ArtistSummary {
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
