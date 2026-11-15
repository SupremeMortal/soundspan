// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'save_playback_state_request_queue_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SavePlaybackStateRequestQueueItem {


/// Create a copy of SavePlaybackStateRequestQueueItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavePlaybackStateRequestQueueItemCopyWith<SavePlaybackStateRequestQueueItem> get copyWith => _$SavePlaybackStateRequestQueueItemCopyWithImpl<SavePlaybackStateRequestQueueItem>(this as SavePlaybackStateRequestQueueItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SavePlaybackStateRequestQueueItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavePlaybackStateRequestQueueItem&&(identical(other.coverUrl, _this.coverUrl) || other.coverUrl == _this.coverUrl)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.episodeId, _this.episodeId) || other.episodeId == _this.episodeId)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.itemType, _this.itemType) || other.itemType == _this.itemType)&&(identical(other.metadata, _this.metadata) || other.metadata == _this.metadata)&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&(identical(other.podcastId, _this.podcastId) || other.podcastId == _this.podcastId)&&(identical(other.podcastTitle, _this.podcastTitle) || other.podcastTitle == _this.podcastTitle)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as SavePlaybackStateRequestQueueItem;
  return Object.hash(runtimeType,_this.coverUrl,_this.duration,_this.episodeId,_this.id,_this.itemType,_this.metadata,_this.playbackId,_this.podcastId,_this.podcastTitle,_this.title,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as SavePlaybackStateRequestQueueItem;
  return 'SavePlaybackStateRequestQueueItem(coverUrl: ${_this.coverUrl}, duration: ${_this.duration}, episodeId: ${_this.episodeId}, id: ${_this.id}, itemType: ${_this.itemType}, metadata: ${_this.metadata}, playbackId: ${_this.playbackId}, podcastId: ${_this.podcastId}, podcastTitle: ${_this.podcastTitle}, title: ${_this.title}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $SavePlaybackStateRequestQueueItemCopyWith<$Res>  {
  factory $SavePlaybackStateRequestQueueItemCopyWith(SavePlaybackStateRequestQueueItem value, $Res Function(SavePlaybackStateRequestQueueItem) _then) = _$SavePlaybackStateRequestQueueItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(disallowNullValue: true, includeIfNull: false) String? coverUrl,@JsonKey(disallowNullValue: true, includeIfNull: false) num? duration,@JsonKey(disallowNullValue: true, includeIfNull: false) String? episodeId,@JsonKey(disallowNullValue: true, includeIfNull: false) String? id,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: SavePlaybackStateRequestQueueItem._read_itemType, toJson: SavePlaybackStateRequestQueueItem._write_itemType) SavePlaybackStateRequestQueueItemItemType? itemType,@JsonKey(disallowNullValue: true, includeIfNull: false) PlaybackMetadata? metadata,@JsonKey(disallowNullValue: true, includeIfNull: false) String? playbackId,@JsonKey(disallowNullValue: true, includeIfNull: false) String? podcastId,@JsonKey(disallowNullValue: true, includeIfNull: false) String? podcastTitle,@JsonKey(disallowNullValue: true, includeIfNull: false) String? title,@JsonKey(readValue: SavePlaybackStateRequestQueueItem._extras, fromJson: SavePlaybackStateRequestQueueItem._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$PlaybackMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class _$SavePlaybackStateRequestQueueItemCopyWithImpl<$Res>
    implements $SavePlaybackStateRequestQueueItemCopyWith<$Res> {
  _$SavePlaybackStateRequestQueueItemCopyWithImpl(this._self, this._then);

  final SavePlaybackStateRequestQueueItem _self;
  final $Res Function(SavePlaybackStateRequestQueueItem) _then;

/// Create a copy of SavePlaybackStateRequestQueueItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? coverUrl = freezed,Object? duration = freezed,Object? episodeId = freezed,Object? id = freezed,Object? itemType = freezed,Object? metadata = freezed,Object? playbackId = freezed,Object? podcastId = freezed,Object? podcastTitle = freezed,Object? title = freezed,Object? additionalProperties = null,}) {
  return _then(SavePlaybackStateRequestQueueItem(
coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as num?,episodeId: freezed == episodeId ? _self.episodeId : episodeId // ignore: cast_nullable_to_non_nullable
as String?,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,itemType: freezed == itemType ? _self.itemType : itemType // ignore: cast_nullable_to_non_nullable
as SavePlaybackStateRequestQueueItemItemType?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as PlaybackMetadata?,playbackId: freezed == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as String?,podcastId: freezed == podcastId ? _self.podcastId : podcastId // ignore: cast_nullable_to_non_nullable
as String?,podcastTitle: freezed == podcastTitle ? _self.podcastTitle : podcastTitle // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of SavePlaybackStateRequestQueueItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaybackMetadataCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $PlaybackMetadataCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [SavePlaybackStateRequestQueueItem].
extension SavePlaybackStateRequestQueueItemPatterns on SavePlaybackStateRequestQueueItem {
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
