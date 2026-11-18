// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discover_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiscoverResult {


/// Create a copy of DiscoverResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscoverResultCopyWith<DiscoverResult> get copyWith => _$DiscoverResultCopyWithImpl<DiscoverResult>(this as DiscoverResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DiscoverResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscoverResult&&(identical(other.album, _this.album) || other.album == _this.album)&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&(identical(other.bio, _this.bio) || other.bio == _this.bio)&&(identical(other.coverUrl, _this.coverUrl) || other.coverUrl == _this.coverUrl)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.durationSec, _this.durationSec) || other.durationSec == _this.durationSec)&&(identical(other.feedUrl, _this.feedUrl) || other.feedUrl == _this.feedUrl)&&const DeepCollectionEquality().equals(other.genres, _this.genres)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.image, _this.image) || other.image == _this.image)&&(identical(other.itunesId, _this.itunesId) || other.itunesId == _this.itunesId)&&(identical(other.listeners, _this.listeners) || other.listeners == _this.listeners)&&(identical(other.mbid, _this.mbid) || other.mbid == _this.mbid)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&(identical(other.previewUrl, _this.previewUrl) || other.previewUrl == _this.previewUrl)&&const DeepCollectionEquality().equals(other.tags, _this.tags)&&(identical(other.trackCount, _this.trackCount) || other.trackCount == _this.trackCount)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.url, _this.url) || other.url == _this.url)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as DiscoverResult;
  return Object.hashAll([runtimeType,_this.album,_this.artist,_this.bio,_this.coverUrl,_this.description,_this.durationSec,_this.feedUrl,const DeepCollectionEquality().hash(_this.genres),_this.id,_this.image,_this.itunesId,_this.listeners,_this.mbid,_this.name,_this.playbackId,_this.previewUrl,const DeepCollectionEquality().hash(_this.tags),_this.trackCount,_this.type,_this.url,const DeepCollectionEquality().hash(_this.additionalProperties)]);
}

@override
String toString() {
  final _this = this as DiscoverResult;
  return 'DiscoverResult(album: ${_this.album}, artist: ${_this.artist}, bio: ${_this.bio}, coverUrl: ${_this.coverUrl}, description: ${_this.description}, durationSec: ${_this.durationSec}, feedUrl: ${_this.feedUrl}, genres: ${_this.genres}, id: ${_this.id}, image: ${_this.image}, itunesId: ${_this.itunesId}, listeners: ${_this.listeners}, mbid: ${_this.mbid}, name: ${_this.name}, playbackId: ${_this.playbackId}, previewUrl: ${_this.previewUrl}, tags: ${_this.tags}, trackCount: ${_this.trackCount}, type: ${_this.type}, url: ${_this.url}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $DiscoverResultCopyWith<$Res>  {
  factory $DiscoverResultCopyWith(DiscoverResult value, $Res Function(DiscoverResult) _then) = _$DiscoverResultCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) String? album,@JsonKey(disallowNullValue: true, includeIfNull: false) String? artist,@JsonKey(includeIfNull: false) String? bio,@JsonKey(disallowNullValue: true, includeIfNull: false) String? coverUrl,@JsonKey(disallowNullValue: true, includeIfNull: false) String? description,@JsonKey(includeIfNull: false) num? durationSec,@JsonKey(disallowNullValue: true, includeIfNull: false) String? feedUrl,@JsonKey(disallowNullValue: true, includeIfNull: false) List<String>? genres,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(includeIfNull: false) String? image,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: DiscoverResult._read_itunesId, toJson: DiscoverResult._write_itunesId) int? itunesId,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: DiscoverResult._read_listeners, toJson: DiscoverResult._write_listeners) int? listeners,@JsonKey(disallowNullValue: true, includeIfNull: false) String? mbid,@JsonKey(required: true, disallowNullValue: true) String name,@JsonKey(disallowNullValue: true, includeIfNull: false) String? playbackId,@JsonKey(includeIfNull: false) String? previewUrl,@JsonKey(disallowNullValue: true, includeIfNull: false) List<String>? tags,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: DiscoverResult._read_trackCount, toJson: DiscoverResult._write_trackCount) int? trackCount,@JsonKey(required: true, disallowNullValue: true, fromJson: DiscoverResult._read_type, toJson: DiscoverResult._write_type) DiscoverResultType type,@JsonKey(includeIfNull: false) String? url,@JsonKey(readValue: DiscoverResult._extras, fromJson: DiscoverResult._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$DiscoverResultCopyWithImpl<$Res>
    implements $DiscoverResultCopyWith<$Res> {
  _$DiscoverResultCopyWithImpl(this._self, this._then);

  final DiscoverResult _self;
  final $Res Function(DiscoverResult) _then;

/// Create a copy of DiscoverResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? album = freezed,Object? artist = freezed,Object? bio = freezed,Object? coverUrl = freezed,Object? description = freezed,Object? durationSec = freezed,Object? feedUrl = freezed,Object? genres = freezed,Object? id = null,Object? image = freezed,Object? itunesId = freezed,Object? listeners = freezed,Object? mbid = freezed,Object? name = null,Object? playbackId = freezed,Object? previewUrl = freezed,Object? tags = freezed,Object? trackCount = freezed,Object? type = null,Object? url = freezed,Object? additionalProperties = null,}) {
  return _then(DiscoverResult(
album: freezed == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,durationSec: freezed == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as num?,feedUrl: freezed == feedUrl ? _self.feedUrl : feedUrl // ignore: cast_nullable_to_non_nullable
as String?,genres: freezed == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>?,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,itunesId: freezed == itunesId ? _self.itunesId : itunesId // ignore: cast_nullable_to_non_nullable
as int?,listeners: freezed == listeners ? _self.listeners : listeners // ignore: cast_nullable_to_non_nullable
as int?,mbid: freezed == mbid ? _self.mbid : mbid // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,playbackId: freezed == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as String?,previewUrl: freezed == previewUrl ? _self.previewUrl : previewUrl // ignore: cast_nullable_to_non_nullable
as String?,tags: freezed == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>?,trackCount: freezed == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DiscoverResultType,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [DiscoverResult].
extension DiscoverResultPatterns on DiscoverResult {
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
