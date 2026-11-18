// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'save_playback_state_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SavePlaybackStateRequest {


/// Create a copy of SavePlaybackStateRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavePlaybackStateRequestCopyWith<SavePlaybackStateRequest> get copyWith => _$SavePlaybackStateRequestCopyWithImpl<SavePlaybackStateRequest>(this as SavePlaybackStateRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SavePlaybackStateRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavePlaybackStateRequest&&(identical(other.currentIndex, _this.currentIndex) || other.currentIndex == _this.currentIndex)&&(identical(other.currentTime, _this.currentTime) || other.currentTime == _this.currentTime)&&(identical(other.isPlaying, _this.isPlaying) || other.isPlaying == _this.isPlaying)&&(identical(other.isShuffle, _this.isShuffle) || other.isShuffle == _this.isShuffle)&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&(identical(other.playbackType, _this.playbackType) || other.playbackType == _this.playbackType)&&(identical(other.podcastId, _this.podcastId) || other.podcastId == _this.podcastId)&&const DeepCollectionEquality().equals(other.queue, _this.queue)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as SavePlaybackStateRequest;
  return Object.hash(runtimeType,_this.currentIndex,_this.currentTime,_this.isPlaying,_this.isShuffle,_this.playbackId,_this.playbackType,_this.podcastId,const DeepCollectionEquality().hash(_this.queue),const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as SavePlaybackStateRequest;
  return 'SavePlaybackStateRequest(currentIndex: ${_this.currentIndex}, currentTime: ${_this.currentTime}, isPlaying: ${_this.isPlaying}, isShuffle: ${_this.isShuffle}, playbackId: ${_this.playbackId}, playbackType: ${_this.playbackType}, podcastId: ${_this.podcastId}, queue: ${_this.queue}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $SavePlaybackStateRequestCopyWith<$Res>  {
  factory $SavePlaybackStateRequestCopyWith(SavePlaybackStateRequest value, $Res Function(SavePlaybackStateRequest) _then) = _$SavePlaybackStateRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: SavePlaybackStateRequest._read_currentIndex, toJson: SavePlaybackStateRequest._write_currentIndex) int? currentIndex,@JsonKey(disallowNullValue: true, includeIfNull: false) num? currentTime,@JsonKey(disallowNullValue: true, includeIfNull: false) bool? isPlaying,@JsonKey(disallowNullValue: true, includeIfNull: false) bool? isShuffle,@JsonKey(disallowNullValue: true, includeIfNull: false) String? playbackId,@JsonKey(required: true, disallowNullValue: true, fromJson: SavePlaybackStateRequest._read_playbackType, toJson: SavePlaybackStateRequest._write_playbackType) SavePlaybackStateRequestPlaybackType playbackType,@JsonKey(disallowNullValue: true, includeIfNull: false) String? podcastId,@JsonKey(disallowNullValue: true, includeIfNull: false) List<SavePlaybackStateRequestQueueItem>? queue,@JsonKey(readValue: SavePlaybackStateRequest._extras, fromJson: SavePlaybackStateRequest._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$SavePlaybackStateRequestCopyWithImpl<$Res>
    implements $SavePlaybackStateRequestCopyWith<$Res> {
  _$SavePlaybackStateRequestCopyWithImpl(this._self, this._then);

  final SavePlaybackStateRequest _self;
  final $Res Function(SavePlaybackStateRequest) _then;

/// Create a copy of SavePlaybackStateRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentIndex = freezed,Object? currentTime = freezed,Object? isPlaying = freezed,Object? isShuffle = freezed,Object? playbackId = freezed,Object? playbackType = null,Object? podcastId = freezed,Object? queue = freezed,Object? additionalProperties = null,}) {
  return _then(SavePlaybackStateRequest(
currentIndex: freezed == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int?,currentTime: freezed == currentTime ? _self.currentTime : currentTime // ignore: cast_nullable_to_non_nullable
as num?,isPlaying: freezed == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool?,isShuffle: freezed == isShuffle ? _self.isShuffle : isShuffle // ignore: cast_nullable_to_non_nullable
as bool?,playbackId: freezed == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as String?,playbackType: null == playbackType ? _self.playbackType : playbackType // ignore: cast_nullable_to_non_nullable
as SavePlaybackStateRequestPlaybackType,podcastId: freezed == podcastId ? _self.podcastId : podcastId // ignore: cast_nullable_to_non_nullable
as String?,queue: freezed == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as List<SavePlaybackStateRequestQueueItem>?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [SavePlaybackStateRequest].
extension SavePlaybackStateRequestPatterns on SavePlaybackStateRequest {
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
