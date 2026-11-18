// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_controls.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MediaSessionState {

/// The item's title.
 String get title;/// The artist, or for an episode the podcast's title.
 String get artist;/// The album; empty for an episode.
 String get album;/// The position in the item when the state was made.
 Duration get position;/// The play intent.
 bool get playing;/// Whether playback waits for data.
 bool get buffering;/// The playback speed.
 double get speed;/// How far [MediaAction.skipForward] and [MediaAction.skipBackward]
/// move.
 Duration get skipInterval;/// The actions the surface offers.
 Set<MediaAction> get actions;/// The queue entry shown, null when nothing is current.
 String? get queueItemId;/// The item's duration once known.
 Duration? get duration;/// The artwork as a URI the OS can load without credentials: a local
/// file, or on web a URL carrying the access token.
 Uri? get artworkUri;/// Whether the current item is liked; what [MediaAction.like] shows.
 bool get liked;/// The user volume, 0.0–1.0, shown where the surface has a volume
/// (MPRIS).
 double get volume;
/// Create a copy of MediaSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaSessionStateCopyWith<MediaSessionState> get copyWith => _$MediaSessionStateCopyWithImpl<MediaSessionState>(this as MediaSessionState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MediaSessionState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaSessionState&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&(identical(other.album, _this.album) || other.album == _this.album)&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.playing, _this.playing) || other.playing == _this.playing)&&(identical(other.buffering, _this.buffering) || other.buffering == _this.buffering)&&(identical(other.speed, _this.speed) || other.speed == _this.speed)&&(identical(other.skipInterval, _this.skipInterval) || other.skipInterval == _this.skipInterval)&&const DeepCollectionEquality().equals(other.actions, _this.actions)&&(identical(other.queueItemId, _this.queueItemId) || other.queueItemId == _this.queueItemId)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.artworkUri, _this.artworkUri) || other.artworkUri == _this.artworkUri)&&(identical(other.liked, _this.liked) || other.liked == _this.liked)&&(identical(other.volume, _this.volume) || other.volume == _this.volume));
}


@override
int get hashCode {
  final _this = this as MediaSessionState;
  return Object.hash(runtimeType,_this.title,_this.artist,_this.album,_this.position,_this.playing,_this.buffering,_this.speed,_this.skipInterval,const DeepCollectionEquality().hash(_this.actions),_this.queueItemId,_this.duration,_this.artworkUri,_this.liked,_this.volume);
}

@override
String toString() {
  final _this = this as MediaSessionState;
  return 'MediaSessionState(title: ${_this.title}, artist: ${_this.artist}, album: ${_this.album}, position: ${_this.position}, playing: ${_this.playing}, buffering: ${_this.buffering}, speed: ${_this.speed}, skipInterval: ${_this.skipInterval}, actions: ${_this.actions}, queueItemId: ${_this.queueItemId}, duration: ${_this.duration}, artworkUri: ${_this.artworkUri}, liked: ${_this.liked}, volume: ${_this.volume})';
}


}

/// @nodoc
abstract mixin class $MediaSessionStateCopyWith<$Res>  {
  factory $MediaSessionStateCopyWith(MediaSessionState value, $Res Function(MediaSessionState) _then) = _$MediaSessionStateCopyWithImpl;
@useResult
$Res call({
 String title, String artist, String album, Duration position, bool playing, bool buffering, double speed, Duration skipInterval, Set<MediaAction> actions, String? queueItemId, Duration? duration, Uri? artworkUri, bool liked, double volume
});




}
/// @nodoc
class _$MediaSessionStateCopyWithImpl<$Res>
    implements $MediaSessionStateCopyWith<$Res> {
  _$MediaSessionStateCopyWithImpl(this._self, this._then);

  final MediaSessionState _self;
  final $Res Function(MediaSessionState) _then;

/// Create a copy of MediaSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? artist = null,Object? album = null,Object? position = null,Object? playing = null,Object? buffering = null,Object? speed = null,Object? skipInterval = null,Object? actions = null,Object? queueItemId = freezed,Object? duration = freezed,Object? artworkUri = freezed,Object? liked = null,Object? volume = null,}) {
  return _then(MediaSessionState(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,playing: null == playing ? _self.playing : playing // ignore: cast_nullable_to_non_nullable
as bool,buffering: null == buffering ? _self.buffering : buffering // ignore: cast_nullable_to_non_nullable
as bool,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,skipInterval: null == skipInterval ? _self.skipInterval : skipInterval // ignore: cast_nullable_to_non_nullable
as Duration,actions: null == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as Set<MediaAction>,queueItemId: freezed == queueItemId ? _self.queueItemId : queueItemId // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,artworkUri: freezed == artworkUri ? _self.artworkUri : artworkUri // ignore: cast_nullable_to_non_nullable
as Uri?,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaSessionState].
extension MediaSessionStatePatterns on MediaSessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaSessionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaSessionState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaSessionState value)  $default,){
final _that = this;
switch (_that) {
case _MediaSessionState():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaSessionState value)?  $default,){
final _that = this;
switch (_that) {
case _MediaSessionState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String artist,  String album,  Duration position,  bool playing,  bool buffering,  double speed,  Duration skipInterval,  Set<MediaAction> actions,  String? queueItemId,  Duration? duration,  Uri? artworkUri,  bool liked,  double volume)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaSessionState() when $default != null:
return $default(_that.title,_that.artist,_that.album,_that.position,_that.playing,_that.buffering,_that.speed,_that.skipInterval,_that.actions,_that.queueItemId,_that.duration,_that.artworkUri,_that.liked,_that.volume);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String artist,  String album,  Duration position,  bool playing,  bool buffering,  double speed,  Duration skipInterval,  Set<MediaAction> actions,  String? queueItemId,  Duration? duration,  Uri? artworkUri,  bool liked,  double volume)  $default,) {final _that = this;
switch (_that) {
case _MediaSessionState():
return $default(_that.title,_that.artist,_that.album,_that.position,_that.playing,_that.buffering,_that.speed,_that.skipInterval,_that.actions,_that.queueItemId,_that.duration,_that.artworkUri,_that.liked,_that.volume);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String artist,  String album,  Duration position,  bool playing,  bool buffering,  double speed,  Duration skipInterval,  Set<MediaAction> actions,  String? queueItemId,  Duration? duration,  Uri? artworkUri,  bool liked,  double volume)?  $default,) {final _that = this;
switch (_that) {
case _MediaSessionState() when $default != null:
return $default(_that.title,_that.artist,_that.album,_that.position,_that.playing,_that.buffering,_that.speed,_that.skipInterval,_that.actions,_that.queueItemId,_that.duration,_that.artworkUri,_that.liked,_that.volume);case _:
  return null;

}
}

}

/// @nodoc


class _MediaSessionState implements MediaSessionState {
  const _MediaSessionState({required this.title, required this.artist, required this.album, required this.position, required this.playing, required this.buffering, required this.speed, required this.skipInterval, required  Set<MediaAction> actions, this.queueItemId, this.duration, this.artworkUri, this.liked = false, this.volume = 1.0}): _actions = actions;
  

/// The item's title.
@override final  String title;
/// The artist, or for an episode the podcast's title.
@override final  String artist;
/// The album; empty for an episode.
@override final  String album;
/// The position in the item when the state was made.
@override final  Duration position;
/// The play intent.
@override final  bool playing;
/// Whether playback waits for data.
@override final  bool buffering;
/// The playback speed.
@override final  double speed;
/// How far [MediaAction.skipForward] and [MediaAction.skipBackward]
/// move.
@override final  Duration skipInterval;
/// The actions the surface offers.
 final  Set<MediaAction> _actions;
/// The actions the surface offers.
@override Set<MediaAction> get actions {
  if (_actions is EqualUnmodifiableSetView) return _actions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_actions);
}

/// The queue entry shown, null when nothing is current.
@override final  String? queueItemId;
/// The item's duration once known.
@override final  Duration? duration;
/// The artwork as a URI the OS can load without credentials: a local
/// file, or on web a URL carrying the access token.
@override final  Uri? artworkUri;
/// Whether the current item is liked; what [MediaAction.like] shows.
@override@JsonKey() final  bool liked;
/// The user volume, 0.0–1.0, shown where the surface has a volume
/// (MPRIS).
@override@JsonKey() final  double volume;

/// Create a copy of MediaSessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaSessionStateCopyWith<_MediaSessionState> get copyWith => __$MediaSessionStateCopyWithImpl<_MediaSessionState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaSessionState&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.album, album) || other.album == album)&&(identical(other.position, position) || other.position == position)&&(identical(other.playing, playing) || other.playing == playing)&&(identical(other.buffering, buffering) || other.buffering == buffering)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.skipInterval, skipInterval) || other.skipInterval == skipInterval)&&const DeepCollectionEquality().equals(other.actions, _actions)&&(identical(other.queueItemId, queueItemId) || other.queueItemId == queueItemId)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.artworkUri, artworkUri) || other.artworkUri == artworkUri)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.volume, volume) || other.volume == volume));
}


@override
int get hashCode {
    return Object.hash(runtimeType,title,artist,album,position,playing,buffering,speed,skipInterval,const DeepCollectionEquality().hash(_actions),queueItemId,duration,artworkUri,liked,volume);
}

@override
String toString() {
    return 'MediaSessionState(title: $title, artist: $artist, album: $album, position: $position, playing: $playing, buffering: $buffering, speed: $speed, skipInterval: $skipInterval, actions: $actions, queueItemId: $queueItemId, duration: $duration, artworkUri: $artworkUri, liked: $liked, volume: $volume)';
}


}

/// @nodoc
abstract mixin class _$MediaSessionStateCopyWith<$Res> implements $MediaSessionStateCopyWith<$Res> {
  factory _$MediaSessionStateCopyWith(_MediaSessionState value, $Res Function(_MediaSessionState) _then) = __$MediaSessionStateCopyWithImpl;
@override @useResult
$Res call({
 String title, String artist, String album, Duration position, bool playing, bool buffering, double speed, Duration skipInterval, Set<MediaAction> actions, String? queueItemId, Duration? duration, Uri? artworkUri, bool liked, double volume
});




}
/// @nodoc
class __$MediaSessionStateCopyWithImpl<$Res>
    implements _$MediaSessionStateCopyWith<$Res> {
  __$MediaSessionStateCopyWithImpl(this._self, this._then);

  final _MediaSessionState _self;
  final $Res Function(_MediaSessionState) _then;

/// Create a copy of MediaSessionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? artist = null,Object? album = null,Object? position = null,Object? playing = null,Object? buffering = null,Object? speed = null,Object? skipInterval = null,Object? actions = null,Object? queueItemId = freezed,Object? duration = freezed,Object? artworkUri = freezed,Object? liked = null,Object? volume = null,}) {
  return _then(_MediaSessionState(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as Duration,playing: null == playing ? _self.playing : playing // ignore: cast_nullable_to_non_nullable
as bool,buffering: null == buffering ? _self.buffering : buffering // ignore: cast_nullable_to_non_nullable
as bool,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,skipInterval: null == skipInterval ? _self.skipInterval : skipInterval // ignore: cast_nullable_to_non_nullable
as Duration,actions: null == actions ? _self._actions : actions // ignore: cast_nullable_to_non_nullable
as Set<MediaAction>,queueItemId: freezed == queueItemId ? _self.queueItemId : queueItemId // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,artworkUri: freezed == artworkUri ? _self.artworkUri : artworkUri // ignore: cast_nullable_to_non_nullable
as Uri?,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
