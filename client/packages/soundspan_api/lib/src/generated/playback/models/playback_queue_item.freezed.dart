// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playback_queue_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaybackQueueItem {


/// Create a copy of PlaybackQueueItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackQueueItemCopyWith<PlaybackQueueItem> get copyWith => _$PlaybackQueueItemCopyWithImpl<PlaybackQueueItem>(this as PlaybackQueueItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlaybackQueueItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackQueueItem&&(identical(other.album, _this.album) || other.album == _this.album)&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&(identical(other.coverUrl, _this.coverUrl) || other.coverUrl == _this.coverUrl)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.episodeId, _this.episodeId) || other.episodeId == _this.episodeId)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.itemType, _this.itemType) || other.itemType == _this.itemType)&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&(identical(other.podcastId, _this.podcastId) || other.podcastId == _this.podcastId)&&(identical(other.podcastTitle, _this.podcastTitle) || other.podcastTitle == _this.podcastTitle)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as PlaybackQueueItem;
  return Object.hash(runtimeType,_this.album,_this.artist,_this.coverUrl,_this.duration,_this.episodeId,_this.id,_this.itemType,_this.playbackId,_this.podcastId,_this.podcastTitle,_this.title,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as PlaybackQueueItem;
  return 'PlaybackQueueItem(album: ${_this.album}, artist: ${_this.artist}, coverUrl: ${_this.coverUrl}, duration: ${_this.duration}, episodeId: ${_this.episodeId}, id: ${_this.id}, itemType: ${_this.itemType}, playbackId: ${_this.playbackId}, podcastId: ${_this.podcastId}, podcastTitle: ${_this.podcastTitle}, title: ${_this.title}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $PlaybackQueueItemCopyWith<$Res>  {
  factory $PlaybackQueueItemCopyWith(PlaybackQueueItem value, $Res Function(PlaybackQueueItem) _then) = _$PlaybackQueueItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) PlaybackQueueItemAlbum? album,@JsonKey(includeIfNull: false) PlaybackQueueItemArtist? artist,@JsonKey(includeIfNull: false) String? coverUrl,@JsonKey(required: true, disallowNullValue: true) num duration,@JsonKey(disallowNullValue: true, includeIfNull: false) String? episodeId,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: PlaybackQueueItem._read_itemType, toJson: PlaybackQueueItem._write_itemType) PlaybackQueueItemItemType? itemType,@JsonKey(disallowNullValue: true, includeIfNull: false) String? playbackId,@JsonKey(disallowNullValue: true, includeIfNull: false) String? podcastId,@JsonKey(disallowNullValue: true, includeIfNull: false) String? podcastTitle,@JsonKey(required: true, disallowNullValue: true) String title,@JsonKey(readValue: PlaybackQueueItem._extras, fromJson: PlaybackQueueItem._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$PlaybackQueueItemAlbumCopyWith<$Res>? get album;$PlaybackQueueItemArtistCopyWith<$Res>? get artist;

}
/// @nodoc
class _$PlaybackQueueItemCopyWithImpl<$Res>
    implements $PlaybackQueueItemCopyWith<$Res> {
  _$PlaybackQueueItemCopyWithImpl(this._self, this._then);

  final PlaybackQueueItem _self;
  final $Res Function(PlaybackQueueItem) _then;

/// Create a copy of PlaybackQueueItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? album = freezed,Object? artist = freezed,Object? coverUrl = freezed,Object? duration = null,Object? episodeId = freezed,Object? id = null,Object? itemType = freezed,Object? playbackId = freezed,Object? podcastId = freezed,Object? podcastTitle = freezed,Object? title = null,Object? additionalProperties = null,}) {
  return _then(PlaybackQueueItem(
album: freezed == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as PlaybackQueueItemAlbum?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as PlaybackQueueItemArtist?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as num,episodeId: freezed == episodeId ? _self.episodeId : episodeId // ignore: cast_nullable_to_non_nullable
as String?,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,itemType: freezed == itemType ? _self.itemType : itemType // ignore: cast_nullable_to_non_nullable
as PlaybackQueueItemItemType?,playbackId: freezed == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as String?,podcastId: freezed == podcastId ? _self.podcastId : podcastId // ignore: cast_nullable_to_non_nullable
as String?,podcastTitle: freezed == podcastTitle ? _self.podcastTitle : podcastTitle // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of PlaybackQueueItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaybackQueueItemAlbumCopyWith<$Res>? get album {
    if (_self.album == null) {
    return null;
  }

  return $PlaybackQueueItemAlbumCopyWith<$Res>(_self.album!, (value) {
    return _then(_self.copyWith(album: value));
  });
}/// Create a copy of PlaybackQueueItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaybackQueueItemArtistCopyWith<$Res>? get artist {
    if (_self.artist == null) {
    return null;
  }

  return $PlaybackQueueItemArtistCopyWith<$Res>(_self.artist!, (value) {
    return _then(_self.copyWith(artist: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlaybackQueueItem].
extension PlaybackQueueItemPatterns on PlaybackQueueItem {
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
