// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discover_track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiscoverTrack {


/// Create a copy of DiscoverTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscoverTrackCopyWith<DiscoverTrack> get copyWith => _$DiscoverTrackCopyWithImpl<DiscoverTrack>(this as DiscoverTrack, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DiscoverTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscoverTrack&&(identical(other.album, _this.album) || other.album == _this.album)&&(identical(other.albumId, _this.albumId) || other.albumId == _this.albumId)&&(identical(other.albumLoudnessLufs, _this.albumLoudnessLufs) || other.albumLoudnessLufs == _this.albumLoudnessLufs)&&(identical(other.albumTruePeakDb, _this.albumTruePeakDb) || other.albumTruePeakDb == _this.albumTruePeakDb)&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&(identical(other.available, _this.available) || other.available == _this.available)&&(identical(other.coverUrl, _this.coverUrl) || other.coverUrl == _this.coverUrl)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.isLiked, _this.isLiked) || other.isLiked == _this.isLiked)&&(identical(other.likedAt, _this.likedAt) || other.likedAt == _this.likedAt)&&(identical(other.loudnessLufs, _this.loudnessLufs) || other.loudnessLufs == _this.loudnessLufs)&&(identical(other.similarity, _this.similarity) || other.similarity == _this.similarity)&&(identical(other.sourceType, _this.sourceType) || other.sourceType == _this.sourceType)&&(identical(other.tier, _this.tier) || other.tier == _this.tier)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.truePeakDb, _this.truePeakDb) || other.truePeakDb == _this.truePeakDb)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as DiscoverTrack;
  return Object.hash(runtimeType,_this.album,_this.albumId,_this.albumLoudnessLufs,_this.albumTruePeakDb,_this.artist,_this.available,_this.coverUrl,_this.duration,_this.id,_this.isLiked,_this.likedAt,_this.loudnessLufs,_this.similarity,_this.sourceType,_this.tier,_this.title,_this.truePeakDb,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as DiscoverTrack;
  return 'DiscoverTrack(album: ${_this.album}, albumId: ${_this.albumId}, albumLoudnessLufs: ${_this.albumLoudnessLufs}, albumTruePeakDb: ${_this.albumTruePeakDb}, artist: ${_this.artist}, available: ${_this.available}, coverUrl: ${_this.coverUrl}, duration: ${_this.duration}, id: ${_this.id}, isLiked: ${_this.isLiked}, likedAt: ${_this.likedAt}, loudnessLufs: ${_this.loudnessLufs}, similarity: ${_this.similarity}, sourceType: ${_this.sourceType}, tier: ${_this.tier}, title: ${_this.title}, truePeakDb: ${_this.truePeakDb}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $DiscoverTrackCopyWith<$Res>  {
  factory $DiscoverTrackCopyWith(DiscoverTrack value, $Res Function(DiscoverTrack) _then) = _$DiscoverTrackCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String album,@JsonKey(required: true, disallowNullValue: true) String albumId,@JsonKey(includeIfNull: false) num? albumLoudnessLufs,@JsonKey(includeIfNull: false) num? albumTruePeakDb,@JsonKey(required: true, disallowNullValue: true) String artist,@JsonKey(required: true, disallowNullValue: true) bool available,@JsonKey(required: true) String? coverUrl,@JsonKey(required: true, disallowNullValue: true, fromJson: DiscoverTrack._read_duration, toJson: DiscoverTrack._write_duration) int duration,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true, disallowNullValue: true) bool isLiked,@JsonKey(required: true, fromJson: DiscoverTrack._read_likedAt, toJson: DiscoverTrack._write_likedAt) DateTime? likedAt,@JsonKey(includeIfNull: false) num? loudnessLufs,@JsonKey(required: true, disallowNullValue: true) num similarity,@JsonKey(required: true, disallowNullValue: true, fromJson: DiscoverTrack._read_sourceType, toJson: DiscoverTrack._write_sourceType) DiscoverTrackSourceType sourceType,@JsonKey(required: true, disallowNullValue: true, fromJson: DiscoverTrack._read_tier, toJson: DiscoverTrack._write_tier) RecommendationTier tier,@JsonKey(required: true, disallowNullValue: true) String title,@JsonKey(includeIfNull: false) num? truePeakDb,@JsonKey(readValue: DiscoverTrack._extras, fromJson: DiscoverTrack._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$DiscoverTrackCopyWithImpl<$Res>
    implements $DiscoverTrackCopyWith<$Res> {
  _$DiscoverTrackCopyWithImpl(this._self, this._then);

  final DiscoverTrack _self;
  final $Res Function(DiscoverTrack) _then;

/// Create a copy of DiscoverTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? album = null,Object? albumId = null,Object? albumLoudnessLufs = freezed,Object? albumTruePeakDb = freezed,Object? artist = null,Object? available = null,Object? coverUrl = freezed,Object? duration = null,Object? id = null,Object? isLiked = null,Object? likedAt = freezed,Object? loudnessLufs = freezed,Object? similarity = null,Object? sourceType = null,Object? tier = null,Object? title = null,Object? truePeakDb = freezed,Object? additionalProperties = null,}) {
  return _then(DiscoverTrack(
album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String,albumId: null == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String,albumLoudnessLufs: freezed == albumLoudnessLufs ? _self.albumLoudnessLufs : albumLoudnessLufs // ignore: cast_nullable_to_non_nullable
as num?,albumTruePeakDb: freezed == albumTruePeakDb ? _self.albumTruePeakDb : albumTruePeakDb // ignore: cast_nullable_to_non_nullable
as num?,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,likedAt: freezed == likedAt ? _self.likedAt : likedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,loudnessLufs: freezed == loudnessLufs ? _self.loudnessLufs : loudnessLufs // ignore: cast_nullable_to_non_nullable
as num?,similarity: null == similarity ? _self.similarity : similarity // ignore: cast_nullable_to_non_nullable
as num,sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as DiscoverTrackSourceType,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as RecommendationTier,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,truePeakDb: freezed == truePeakDb ? _self.truePeakDb : truePeakDb // ignore: cast_nullable_to_non_nullable
as num?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [DiscoverTrack].
extension DiscoverTrackPatterns on DiscoverTrack {
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
