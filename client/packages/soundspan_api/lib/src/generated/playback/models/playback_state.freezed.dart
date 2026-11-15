// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playback_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaybackState {


/// Create a copy of PlaybackState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackStateCopyWith<PlaybackState> get copyWith => _$PlaybackStateCopyWithImpl<PlaybackState>(this as PlaybackState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlaybackState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackState&&(identical(other.audiobookId, _this.audiobookId) || other.audiobookId == _this.audiobookId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.currentIndex, _this.currentIndex) || other.currentIndex == _this.currentIndex)&&(identical(other.currentTime, _this.currentTime) || other.currentTime == _this.currentTime)&&(identical(other.deviceId, _this.deviceId) || other.deviceId == _this.deviceId)&&(identical(other.isPlaying, _this.isPlaying) || other.isPlaying == _this.isPlaying)&&(identical(other.isShuffle, _this.isShuffle) || other.isShuffle == _this.isShuffle)&&(identical(other.playbackType, _this.playbackType) || other.playbackType == _this.playbackType)&&(identical(other.podcastId, _this.podcastId) || other.podcastId == _this.podcastId)&&const DeepCollectionEquality().equals(other.queue, _this.queue)&&(identical(other.trackId, _this.trackId) || other.trackId == _this.trackId)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as PlaybackState;
  return Object.hash(runtimeType,_this.audiobookId,_this.createdAt,_this.currentIndex,_this.currentTime,_this.deviceId,_this.isPlaying,_this.isShuffle,_this.playbackType,_this.podcastId,const DeepCollectionEquality().hash(_this.queue),_this.trackId,_this.updatedAt,_this.userId,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as PlaybackState;
  return 'PlaybackState(audiobookId: ${_this.audiobookId}, createdAt: ${_this.createdAt}, currentIndex: ${_this.currentIndex}, currentTime: ${_this.currentTime}, deviceId: ${_this.deviceId}, isPlaying: ${_this.isPlaying}, isShuffle: ${_this.isShuffle}, playbackType: ${_this.playbackType}, podcastId: ${_this.podcastId}, queue: ${_this.queue}, trackId: ${_this.trackId}, updatedAt: ${_this.updatedAt}, userId: ${_this.userId}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $PlaybackStateCopyWith<$Res>  {
  factory $PlaybackStateCopyWith(PlaybackState value, $Res Function(PlaybackState) _then) = _$PlaybackStateCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true) String? audiobookId,@JsonKey(required: true, disallowNullValue: true, fromJson: PlaybackState._read_createdAt, toJson: PlaybackState._write_createdAt) DateTime createdAt,@JsonKey(required: true, disallowNullValue: true, fromJson: PlaybackState._read_currentIndex, toJson: PlaybackState._write_currentIndex) int currentIndex,@JsonKey(required: true, disallowNullValue: true) num currentTime,@JsonKey(required: true, disallowNullValue: true) String deviceId,@JsonKey(required: true, disallowNullValue: true) bool isPlaying,@JsonKey(required: true, disallowNullValue: true) bool isShuffle,@JsonKey(required: true, disallowNullValue: true, fromJson: PlaybackState._read_playbackType, toJson: PlaybackState._write_playbackType) PlaybackStatePlaybackType playbackType,@JsonKey(required: true) String? podcastId,@JsonKey(required: true) List<PlaybackQueueItem>? queue,@JsonKey(required: true) String? trackId,@JsonKey(required: true, disallowNullValue: true, fromJson: PlaybackState._read_updatedAt, toJson: PlaybackState._write_updatedAt) DateTime updatedAt,@JsonKey(required: true, disallowNullValue: true) String userId,@JsonKey(readValue: PlaybackState._extras, fromJson: PlaybackState._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$PlaybackStateCopyWithImpl<$Res>
    implements $PlaybackStateCopyWith<$Res> {
  _$PlaybackStateCopyWithImpl(this._self, this._then);

  final PlaybackState _self;
  final $Res Function(PlaybackState) _then;

/// Create a copy of PlaybackState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? audiobookId = freezed,Object? createdAt = null,Object? currentIndex = null,Object? currentTime = null,Object? deviceId = null,Object? isPlaying = null,Object? isShuffle = null,Object? playbackType = null,Object? podcastId = freezed,Object? queue = freezed,Object? trackId = freezed,Object? updatedAt = null,Object? userId = null,Object? additionalProperties = null,}) {
  return _then(PlaybackState(
audiobookId: freezed == audiobookId ? _self.audiobookId : audiobookId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,currentTime: null == currentTime ? _self.currentTime : currentTime // ignore: cast_nullable_to_non_nullable
as num,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,isShuffle: null == isShuffle ? _self.isShuffle : isShuffle // ignore: cast_nullable_to_non_nullable
as bool,playbackType: null == playbackType ? _self.playbackType : playbackType // ignore: cast_nullable_to_non_nullable
as PlaybackStatePlaybackType,podcastId: freezed == podcastId ? _self.podcastId : podcastId // ignore: cast_nullable_to_non_nullable
as String?,queue: freezed == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as List<PlaybackQueueItem>?,trackId: freezed == trackId ? _self.trackId : trackId // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaybackState].
extension PlaybackStatePatterns on PlaybackState {
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
