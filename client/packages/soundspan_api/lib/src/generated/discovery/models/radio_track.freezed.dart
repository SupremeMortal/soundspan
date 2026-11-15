// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'radio_track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RadioTrack {


/// Create a copy of RadioTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioTrackCopyWith<RadioTrack> get copyWith => _$RadioTrackCopyWithImpl<RadioTrack>(this as RadioTrack, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RadioTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioTrack&&(identical(other.album, _this.album) || other.album == _this.album)&&(identical(other.albumId, _this.albumId) || other.albumId == _this.albumId)&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&(identical(other.audioFeatures, _this.audioFeatures) || other.audioFeatures == _this.audioFeatures)&&(identical(other.discNo, _this.discNo) || other.discNo == _this.discNo)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.isrc, _this.isrc) || other.isrc == _this.isrc)&&(identical(other.loudnessLufs, _this.loudnessLufs) || other.loudnessLufs == _this.loudnessLufs)&&(identical(other.peer, _this.peer) || other.peer == _this.peer)&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.trackNo, _this.trackNo) || other.trackNo == _this.trackNo)&&(identical(other.truePeakDb, _this.truePeakDb) || other.truePeakDb == _this.truePeakDb)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as RadioTrack;
  return Object.hash(runtimeType,_this.album,_this.albumId,_this.artist,_this.audioFeatures,_this.discNo,_this.duration,_this.id,_this.isrc,_this.loudnessLufs,_this.peer,_this.playbackId,_this.title,_this.trackNo,_this.truePeakDb,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as RadioTrack;
  return 'RadioTrack(album: ${_this.album}, albumId: ${_this.albumId}, artist: ${_this.artist}, audioFeatures: ${_this.audioFeatures}, discNo: ${_this.discNo}, duration: ${_this.duration}, id: ${_this.id}, isrc: ${_this.isrc}, loudnessLufs: ${_this.loudnessLufs}, peer: ${_this.peer}, playbackId: ${_this.playbackId}, title: ${_this.title}, trackNo: ${_this.trackNo}, truePeakDb: ${_this.truePeakDb}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $RadioTrackCopyWith<$Res>  {
  factory $RadioTrackCopyWith(RadioTrack value, $Res Function(RadioTrack) _then) = _$RadioTrackCopyWithImpl;
@useResult
$Res call({
@JsonKey(disallowNullValue: true, includeIfNull: false) TrackAlbumRef? album,@JsonKey(disallowNullValue: true, includeIfNull: false) String? albumId,@JsonKey(disallowNullValue: true, includeIfNull: false) TrackArtistRef? artist,@JsonKey(disallowNullValue: true, includeIfNull: false) RadioAudioFeatures? audioFeatures,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: RadioTrack._read_discNo, toJson: RadioTrack._write_discNo) int? discNo,@JsonKey(required: true, disallowNullValue: true, fromJson: RadioTrack._read_duration, toJson: RadioTrack._write_duration) int duration,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(includeIfNull: false) String? isrc,@JsonKey(includeIfNull: false) num? loudnessLufs,@JsonKey(includeIfNull: false) PeerRef? peer,@JsonKey(required: true, disallowNullValue: true) String playbackId,@JsonKey(required: true, disallowNullValue: true) String title,@JsonKey(required: true, disallowNullValue: true, fromJson: RadioTrack._read_trackNo, toJson: RadioTrack._write_trackNo) int trackNo,@JsonKey(includeIfNull: false) num? truePeakDb,@JsonKey(readValue: RadioTrack._extras, fromJson: RadioTrack._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$TrackAlbumRefCopyWith<$Res>? get album;$TrackArtistRefCopyWith<$Res>? get artist;$RadioAudioFeaturesCopyWith<$Res>? get audioFeatures;$PeerRefCopyWith<$Res>? get peer;

}
/// @nodoc
class _$RadioTrackCopyWithImpl<$Res>
    implements $RadioTrackCopyWith<$Res> {
  _$RadioTrackCopyWithImpl(this._self, this._then);

  final RadioTrack _self;
  final $Res Function(RadioTrack) _then;

/// Create a copy of RadioTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? album = freezed,Object? albumId = freezed,Object? artist = freezed,Object? audioFeatures = freezed,Object? discNo = freezed,Object? duration = null,Object? id = null,Object? isrc = freezed,Object? loudnessLufs = freezed,Object? peer = freezed,Object? playbackId = null,Object? title = null,Object? trackNo = null,Object? truePeakDb = freezed,Object? additionalProperties = null,}) {
  return _then(RadioTrack(
album: freezed == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as TrackAlbumRef?,albumId: freezed == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as TrackArtistRef?,audioFeatures: freezed == audioFeatures ? _self.audioFeatures : audioFeatures // ignore: cast_nullable_to_non_nullable
as RadioAudioFeatures?,discNo: freezed == discNo ? _self.discNo : discNo // ignore: cast_nullable_to_non_nullable
as int?,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,isrc: freezed == isrc ? _self.isrc : isrc // ignore: cast_nullable_to_non_nullable
as String?,loudnessLufs: freezed == loudnessLufs ? _self.loudnessLufs : loudnessLufs // ignore: cast_nullable_to_non_nullable
as num?,peer: freezed == peer ? _self.peer : peer // ignore: cast_nullable_to_non_nullable
as PeerRef?,playbackId: null == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,trackNo: null == trackNo ? _self.trackNo : trackNo // ignore: cast_nullable_to_non_nullable
as int,truePeakDb: freezed == truePeakDb ? _self.truePeakDb : truePeakDb // ignore: cast_nullable_to_non_nullable
as num?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of RadioTrack
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackAlbumRefCopyWith<$Res>? get album {
    if (_self.album == null) {
    return null;
  }

  return $TrackAlbumRefCopyWith<$Res>(_self.album!, (value) {
    return _then(_self.copyWith(album: value));
  });
}/// Create a copy of RadioTrack
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackArtistRefCopyWith<$Res>? get artist {
    if (_self.artist == null) {
    return null;
  }

  return $TrackArtistRefCopyWith<$Res>(_self.artist!, (value) {
    return _then(_self.copyWith(artist: value));
  });
}/// Create a copy of RadioTrack
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RadioAudioFeaturesCopyWith<$Res>? get audioFeatures {
    if (_self.audioFeatures == null) {
    return null;
  }

  return $RadioAudioFeaturesCopyWith<$Res>(_self.audioFeatures!, (value) {
    return _then(_self.copyWith(audioFeatures: value));
  });
}/// Create a copy of RadioTrack
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


/// Adds pattern-matching-related methods to [RadioTrack].
extension RadioTrackPatterns on RadioTrack {
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
