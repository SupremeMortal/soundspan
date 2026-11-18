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
mixin _$PlaybackStateEntry {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackStateEntry);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PlaybackStateEntry()';
}


}

/// @nodoc
class $PlaybackStateEntryCopyWith<$Res>  {
$PlaybackStateEntryCopyWith(PlaybackStateEntry _, $Res Function(PlaybackStateEntry) __);
}


/// Adds pattern-matching-related methods to [PlaybackStateEntry].
extension PlaybackStateEntryPatterns on PlaybackStateEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TrackStateEntry value)?  track,TResult Function( EpisodeStateEntry value)?  episode,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TrackStateEntry() when track != null:
return track(_that);case EpisodeStateEntry() when episode != null:
return episode(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TrackStateEntry value)  track,required TResult Function( EpisodeStateEntry value)  episode,}){
final _that = this;
switch (_that) {
case TrackStateEntry():
return track(_that);case EpisodeStateEntry():
return episode(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TrackStateEntry value)?  track,TResult? Function( EpisodeStateEntry value)?  episode,}){
final _that = this;
switch (_that) {
case TrackStateEntry() when track != null:
return track(_that);case EpisodeStateEntry() when episode != null:
return episode(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( PlaybackId? playbackId,  TrackMeta meta)?  track,TResult Function( String podcastId,  String episodeId,  String title,  String podcastTitle,  int durationSec,  String? coverUrl)?  episode,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TrackStateEntry() when track != null:
return track(_that.playbackId,_that.meta);case EpisodeStateEntry() when episode != null:
return episode(_that.podcastId,_that.episodeId,_that.title,_that.podcastTitle,_that.durationSec,_that.coverUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( PlaybackId? playbackId,  TrackMeta meta)  track,required TResult Function( String podcastId,  String episodeId,  String title,  String podcastTitle,  int durationSec,  String? coverUrl)  episode,}) {final _that = this;
switch (_that) {
case TrackStateEntry():
return track(_that.playbackId,_that.meta);case EpisodeStateEntry():
return episode(_that.podcastId,_that.episodeId,_that.title,_that.podcastTitle,_that.durationSec,_that.coverUrl);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( PlaybackId? playbackId,  TrackMeta meta)?  track,TResult? Function( String podcastId,  String episodeId,  String title,  String podcastTitle,  int durationSec,  String? coverUrl)?  episode,}) {final _that = this;
switch (_that) {
case TrackStateEntry() when track != null:
return track(_that.playbackId,_that.meta);case EpisodeStateEntry() when episode != null:
return episode(_that.podcastId,_that.episodeId,_that.title,_that.podcastTitle,_that.durationSec,_that.coverUrl);case _:
  return null;

}
}

}

/// @nodoc


class TrackStateEntry implements PlaybackStateEntry {
  const TrackStateEntry({required this.playbackId, required this.meta});
  

/// The track's playback id, if the server gave one.
 final  PlaybackId? playbackId;
/// What the client shows and sends as `metadata`.
 final  TrackMeta meta;

/// Create a copy of PlaybackStateEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackStateEntryCopyWith<TrackStateEntry> get copyWith => _$TrackStateEntryCopyWithImpl<TrackStateEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackStateEntry&&(identical(other.playbackId, playbackId) || other.playbackId == playbackId)&&(identical(other.meta, meta) || other.meta == meta));
}


@override
int get hashCode {
    return Object.hash(runtimeType,playbackId,meta);
}

@override
String toString() {
    return 'PlaybackStateEntry.track(playbackId: $playbackId, meta: $meta)';
}


}

/// @nodoc
abstract mixin class $TrackStateEntryCopyWith<$Res> implements $PlaybackStateEntryCopyWith<$Res> {
  factory $TrackStateEntryCopyWith(TrackStateEntry value, $Res Function(TrackStateEntry) _then) = _$TrackStateEntryCopyWithImpl;
@useResult
$Res call({
 PlaybackId? playbackId, TrackMeta meta
});


$TrackMetaCopyWith<$Res> get meta;

}
/// @nodoc
class _$TrackStateEntryCopyWithImpl<$Res>
    implements $TrackStateEntryCopyWith<$Res> {
  _$TrackStateEntryCopyWithImpl(this._self, this._then);

  final TrackStateEntry _self;
  final $Res Function(TrackStateEntry) _then;

/// Create a copy of PlaybackStateEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playbackId = freezed,Object? meta = null,}) {
  return _then(TrackStateEntry(
playbackId: freezed == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as PlaybackId?,meta: null == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as TrackMeta,
  ));
}

/// Create a copy of PlaybackStateEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackMetaCopyWith<$Res> get meta {
  
  return $TrackMetaCopyWith<$Res>(_self.meta, (value) {
    return _then(_self.copyWith(meta: value));
  });
}
}

/// @nodoc


class EpisodeStateEntry implements PlaybackStateEntry {
  const EpisodeStateEntry({required this.podcastId, required this.episodeId, required this.title, required this.podcastTitle, required this.durationSec, this.coverUrl});
  

/// The podcast.
 final  String podcastId;
/// The episode.
 final  String episodeId;
/// The episode title.
 final  String title;
/// The podcast title.
 final  String podcastTitle;
/// The duration in whole seconds.
 final  int durationSec;
/// The episode's cover URL, if any.
 final  String? coverUrl;

/// Create a copy of PlaybackStateEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EpisodeStateEntryCopyWith<EpisodeStateEntry> get copyWith => _$EpisodeStateEntryCopyWithImpl<EpisodeStateEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EpisodeStateEntry&&(identical(other.podcastId, podcastId) || other.podcastId == podcastId)&&(identical(other.episodeId, episodeId) || other.episodeId == episodeId)&&(identical(other.title, title) || other.title == title)&&(identical(other.podcastTitle, podcastTitle) || other.podcastTitle == podcastTitle)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,podcastId,episodeId,title,podcastTitle,durationSec,coverUrl);
}

@override
String toString() {
    return 'PlaybackStateEntry.episode(podcastId: $podcastId, episodeId: $episodeId, title: $title, podcastTitle: $podcastTitle, durationSec: $durationSec, coverUrl: $coverUrl)';
}


}

/// @nodoc
abstract mixin class $EpisodeStateEntryCopyWith<$Res> implements $PlaybackStateEntryCopyWith<$Res> {
  factory $EpisodeStateEntryCopyWith(EpisodeStateEntry value, $Res Function(EpisodeStateEntry) _then) = _$EpisodeStateEntryCopyWithImpl;
@useResult
$Res call({
 String podcastId, String episodeId, String title, String podcastTitle, int durationSec, String? coverUrl
});




}
/// @nodoc
class _$EpisodeStateEntryCopyWithImpl<$Res>
    implements $EpisodeStateEntryCopyWith<$Res> {
  _$EpisodeStateEntryCopyWithImpl(this._self, this._then);

  final EpisodeStateEntry _self;
  final $Res Function(EpisodeStateEntry) _then;

/// Create a copy of PlaybackStateEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? podcastId = null,Object? episodeId = null,Object? title = null,Object? podcastTitle = null,Object? durationSec = null,Object? coverUrl = freezed,}) {
  return _then(EpisodeStateEntry(
podcastId: null == podcastId ? _self.podcastId : podcastId // ignore: cast_nullable_to_non_nullable
as String,episodeId: null == episodeId ? _self.episodeId : episodeId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,podcastTitle: null == podcastTitle ? _self.podcastTitle : podcastTitle // ignore: cast_nullable_to_non_nullable
as String,durationSec: null == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$PlaybackStateDraft {

/// What is playing.
 PlaybackStateType get playbackType;/// The index of the current entry in [queue].
 int get currentIndex;/// The position in the current entry, in seconds.
 double get currentTime;/// Whether shuffle is on.
 bool get isShuffle;/// Whether playback is running.
 bool get isPlaying;/// The window of the play order the server stores.
 List<PlaybackStateEntry> get queue;/// The current track, for a track state.
 PlaybackId? get playbackId;/// The current podcast, for a podcast state.
 String? get podcastId;
/// Create a copy of PlaybackStateDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackStateDraftCopyWith<PlaybackStateDraft> get copyWith => _$PlaybackStateDraftCopyWithImpl<PlaybackStateDraft>(this as PlaybackStateDraft, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlaybackStateDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackStateDraft&&(identical(other.playbackType, _this.playbackType) || other.playbackType == _this.playbackType)&&(identical(other.currentIndex, _this.currentIndex) || other.currentIndex == _this.currentIndex)&&(identical(other.currentTime, _this.currentTime) || other.currentTime == _this.currentTime)&&(identical(other.isShuffle, _this.isShuffle) || other.isShuffle == _this.isShuffle)&&(identical(other.isPlaying, _this.isPlaying) || other.isPlaying == _this.isPlaying)&&const DeepCollectionEquality().equals(other.queue, _this.queue)&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&(identical(other.podcastId, _this.podcastId) || other.podcastId == _this.podcastId));
}


@override
int get hashCode {
  final _this = this as PlaybackStateDraft;
  return Object.hash(runtimeType,_this.playbackType,_this.currentIndex,_this.currentTime,_this.isShuffle,_this.isPlaying,const DeepCollectionEquality().hash(_this.queue),_this.playbackId,_this.podcastId);
}

@override
String toString() {
  final _this = this as PlaybackStateDraft;
  return 'PlaybackStateDraft(playbackType: ${_this.playbackType}, currentIndex: ${_this.currentIndex}, currentTime: ${_this.currentTime}, isShuffle: ${_this.isShuffle}, isPlaying: ${_this.isPlaying}, queue: ${_this.queue}, playbackId: ${_this.playbackId}, podcastId: ${_this.podcastId})';
}


}

/// @nodoc
abstract mixin class $PlaybackStateDraftCopyWith<$Res>  {
  factory $PlaybackStateDraftCopyWith(PlaybackStateDraft value, $Res Function(PlaybackStateDraft) _then) = _$PlaybackStateDraftCopyWithImpl;
@useResult
$Res call({
 PlaybackStateType playbackType, int currentIndex, double currentTime, bool isShuffle, bool isPlaying, List<PlaybackStateEntry> queue, PlaybackId? playbackId, String? podcastId
});




}
/// @nodoc
class _$PlaybackStateDraftCopyWithImpl<$Res>
    implements $PlaybackStateDraftCopyWith<$Res> {
  _$PlaybackStateDraftCopyWithImpl(this._self, this._then);

  final PlaybackStateDraft _self;
  final $Res Function(PlaybackStateDraft) _then;

/// Create a copy of PlaybackStateDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playbackType = null,Object? currentIndex = null,Object? currentTime = null,Object? isShuffle = null,Object? isPlaying = null,Object? queue = null,Object? playbackId = freezed,Object? podcastId = freezed,}) {
  return _then(PlaybackStateDraft(
playbackType: null == playbackType ? _self.playbackType : playbackType // ignore: cast_nullable_to_non_nullable
as PlaybackStateType,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,currentTime: null == currentTime ? _self.currentTime : currentTime // ignore: cast_nullable_to_non_nullable
as double,isShuffle: null == isShuffle ? _self.isShuffle : isShuffle // ignore: cast_nullable_to_non_nullable
as bool,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as List<PlaybackStateEntry>,playbackId: freezed == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as PlaybackId?,podcastId: freezed == podcastId ? _self.podcastId : podcastId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaybackStateDraft].
extension PlaybackStateDraftPatterns on PlaybackStateDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaybackStateDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaybackStateDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaybackStateDraft value)  $default,){
final _that = this;
switch (_that) {
case _PlaybackStateDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaybackStateDraft value)?  $default,){
final _that = this;
switch (_that) {
case _PlaybackStateDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlaybackStateType playbackType,  int currentIndex,  double currentTime,  bool isShuffle,  bool isPlaying,  List<PlaybackStateEntry> queue,  PlaybackId? playbackId,  String? podcastId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaybackStateDraft() when $default != null:
return $default(_that.playbackType,_that.currentIndex,_that.currentTime,_that.isShuffle,_that.isPlaying,_that.queue,_that.playbackId,_that.podcastId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlaybackStateType playbackType,  int currentIndex,  double currentTime,  bool isShuffle,  bool isPlaying,  List<PlaybackStateEntry> queue,  PlaybackId? playbackId,  String? podcastId)  $default,) {final _that = this;
switch (_that) {
case _PlaybackStateDraft():
return $default(_that.playbackType,_that.currentIndex,_that.currentTime,_that.isShuffle,_that.isPlaying,_that.queue,_that.playbackId,_that.podcastId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlaybackStateType playbackType,  int currentIndex,  double currentTime,  bool isShuffle,  bool isPlaying,  List<PlaybackStateEntry> queue,  PlaybackId? playbackId,  String? podcastId)?  $default,) {final _that = this;
switch (_that) {
case _PlaybackStateDraft() when $default != null:
return $default(_that.playbackType,_that.currentIndex,_that.currentTime,_that.isShuffle,_that.isPlaying,_that.queue,_that.playbackId,_that.podcastId);case _:
  return null;

}
}

}

/// @nodoc


class _PlaybackStateDraft implements PlaybackStateDraft {
  const _PlaybackStateDraft({required this.playbackType, required this.currentIndex, required this.currentTime, required this.isShuffle, required this.isPlaying, required  List<PlaybackStateEntry> queue, this.playbackId, this.podcastId}): _queue = queue;
  

/// What is playing.
@override final  PlaybackStateType playbackType;
/// The index of the current entry in [queue].
@override final  int currentIndex;
/// The position in the current entry, in seconds.
@override final  double currentTime;
/// Whether shuffle is on.
@override final  bool isShuffle;
/// Whether playback is running.
@override final  bool isPlaying;
/// The window of the play order the server stores.
 final  List<PlaybackStateEntry> _queue;
/// The window of the play order the server stores.
@override List<PlaybackStateEntry> get queue {
  if (_queue is EqualUnmodifiableListView) return _queue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_queue);
}

/// The current track, for a track state.
@override final  PlaybackId? playbackId;
/// The current podcast, for a podcast state.
@override final  String? podcastId;

/// Create a copy of PlaybackStateDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaybackStateDraftCopyWith<_PlaybackStateDraft> get copyWith => __$PlaybackStateDraftCopyWithImpl<_PlaybackStateDraft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaybackStateDraft&&(identical(other.playbackType, playbackType) || other.playbackType == playbackType)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.currentTime, currentTime) || other.currentTime == currentTime)&&(identical(other.isShuffle, isShuffle) || other.isShuffle == isShuffle)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&const DeepCollectionEquality().equals(other.queue, _queue)&&(identical(other.playbackId, playbackId) || other.playbackId == playbackId)&&(identical(other.podcastId, podcastId) || other.podcastId == podcastId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,playbackType,currentIndex,currentTime,isShuffle,isPlaying,const DeepCollectionEquality().hash(_queue),playbackId,podcastId);
}

@override
String toString() {
    return 'PlaybackStateDraft(playbackType: $playbackType, currentIndex: $currentIndex, currentTime: $currentTime, isShuffle: $isShuffle, isPlaying: $isPlaying, queue: $queue, playbackId: $playbackId, podcastId: $podcastId)';
}


}

/// @nodoc
abstract mixin class _$PlaybackStateDraftCopyWith<$Res> implements $PlaybackStateDraftCopyWith<$Res> {
  factory _$PlaybackStateDraftCopyWith(_PlaybackStateDraft value, $Res Function(_PlaybackStateDraft) _then) = __$PlaybackStateDraftCopyWithImpl;
@override @useResult
$Res call({
 PlaybackStateType playbackType, int currentIndex, double currentTime, bool isShuffle, bool isPlaying, List<PlaybackStateEntry> queue, PlaybackId? playbackId, String? podcastId
});




}
/// @nodoc
class __$PlaybackStateDraftCopyWithImpl<$Res>
    implements _$PlaybackStateDraftCopyWith<$Res> {
  __$PlaybackStateDraftCopyWithImpl(this._self, this._then);

  final _PlaybackStateDraft _self;
  final $Res Function(_PlaybackStateDraft) _then;

/// Create a copy of PlaybackStateDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playbackType = null,Object? currentIndex = null,Object? currentTime = null,Object? isShuffle = null,Object? isPlaying = null,Object? queue = null,Object? playbackId = freezed,Object? podcastId = freezed,}) {
  return _then(_PlaybackStateDraft(
playbackType: null == playbackType ? _self.playbackType : playbackType // ignore: cast_nullable_to_non_nullable
as PlaybackStateType,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,currentTime: null == currentTime ? _self.currentTime : currentTime // ignore: cast_nullable_to_non_nullable
as double,isShuffle: null == isShuffle ? _self.isShuffle : isShuffle // ignore: cast_nullable_to_non_nullable
as bool,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,queue: null == queue ? _self._queue : queue // ignore: cast_nullable_to_non_nullable
as List<PlaybackStateEntry>,playbackId: freezed == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as PlaybackId?,podcastId: freezed == podcastId ? _self.podcastId : podcastId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$RemotePlaybackState {

/// What was playing.
 PlaybackStateType get playbackType;/// The index of the current entry in [queue].
 int get currentIndex;/// The position in the current entry, in seconds.
 double get currentTime;/// Whether shuffle was on.
 bool get isShuffle;/// Whether playback was running.
 bool get isPlaying;/// The stored queue, at most 100 entries.
 List<PlaybackStateEntry> get queue;/// When the server stored the state, in UTC.
 DateTime get updatedAt;/// The current podcast, for a podcast state.
 String? get podcastId;
/// Create a copy of RemotePlaybackState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RemotePlaybackStateCopyWith<RemotePlaybackState> get copyWith => _$RemotePlaybackStateCopyWithImpl<RemotePlaybackState>(this as RemotePlaybackState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RemotePlaybackState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RemotePlaybackState&&(identical(other.playbackType, _this.playbackType) || other.playbackType == _this.playbackType)&&(identical(other.currentIndex, _this.currentIndex) || other.currentIndex == _this.currentIndex)&&(identical(other.currentTime, _this.currentTime) || other.currentTime == _this.currentTime)&&(identical(other.isShuffle, _this.isShuffle) || other.isShuffle == _this.isShuffle)&&(identical(other.isPlaying, _this.isPlaying) || other.isPlaying == _this.isPlaying)&&const DeepCollectionEquality().equals(other.queue, _this.queue)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.podcastId, _this.podcastId) || other.podcastId == _this.podcastId));
}


@override
int get hashCode {
  final _this = this as RemotePlaybackState;
  return Object.hash(runtimeType,_this.playbackType,_this.currentIndex,_this.currentTime,_this.isShuffle,_this.isPlaying,const DeepCollectionEquality().hash(_this.queue),_this.updatedAt,_this.podcastId);
}

@override
String toString() {
  final _this = this as RemotePlaybackState;
  return 'RemotePlaybackState(playbackType: ${_this.playbackType}, currentIndex: ${_this.currentIndex}, currentTime: ${_this.currentTime}, isShuffle: ${_this.isShuffle}, isPlaying: ${_this.isPlaying}, queue: ${_this.queue}, updatedAt: ${_this.updatedAt}, podcastId: ${_this.podcastId})';
}


}

/// @nodoc
abstract mixin class $RemotePlaybackStateCopyWith<$Res>  {
  factory $RemotePlaybackStateCopyWith(RemotePlaybackState value, $Res Function(RemotePlaybackState) _then) = _$RemotePlaybackStateCopyWithImpl;
@useResult
$Res call({
 PlaybackStateType playbackType, int currentIndex, double currentTime, bool isShuffle, bool isPlaying, List<PlaybackStateEntry> queue, DateTime updatedAt, String? podcastId
});




}
/// @nodoc
class _$RemotePlaybackStateCopyWithImpl<$Res>
    implements $RemotePlaybackStateCopyWith<$Res> {
  _$RemotePlaybackStateCopyWithImpl(this._self, this._then);

  final RemotePlaybackState _self;
  final $Res Function(RemotePlaybackState) _then;

/// Create a copy of RemotePlaybackState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playbackType = null,Object? currentIndex = null,Object? currentTime = null,Object? isShuffle = null,Object? isPlaying = null,Object? queue = null,Object? updatedAt = null,Object? podcastId = freezed,}) {
  return _then(RemotePlaybackState(
playbackType: null == playbackType ? _self.playbackType : playbackType // ignore: cast_nullable_to_non_nullable
as PlaybackStateType,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,currentTime: null == currentTime ? _self.currentTime : currentTime // ignore: cast_nullable_to_non_nullable
as double,isShuffle: null == isShuffle ? _self.isShuffle : isShuffle // ignore: cast_nullable_to_non_nullable
as bool,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as List<PlaybackStateEntry>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,podcastId: freezed == podcastId ? _self.podcastId : podcastId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RemotePlaybackState].
extension RemotePlaybackStatePatterns on RemotePlaybackState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RemotePlaybackState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RemotePlaybackState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RemotePlaybackState value)  $default,){
final _that = this;
switch (_that) {
case _RemotePlaybackState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RemotePlaybackState value)?  $default,){
final _that = this;
switch (_that) {
case _RemotePlaybackState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlaybackStateType playbackType,  int currentIndex,  double currentTime,  bool isShuffle,  bool isPlaying,  List<PlaybackStateEntry> queue,  DateTime updatedAt,  String? podcastId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RemotePlaybackState() when $default != null:
return $default(_that.playbackType,_that.currentIndex,_that.currentTime,_that.isShuffle,_that.isPlaying,_that.queue,_that.updatedAt,_that.podcastId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlaybackStateType playbackType,  int currentIndex,  double currentTime,  bool isShuffle,  bool isPlaying,  List<PlaybackStateEntry> queue,  DateTime updatedAt,  String? podcastId)  $default,) {final _that = this;
switch (_that) {
case _RemotePlaybackState():
return $default(_that.playbackType,_that.currentIndex,_that.currentTime,_that.isShuffle,_that.isPlaying,_that.queue,_that.updatedAt,_that.podcastId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlaybackStateType playbackType,  int currentIndex,  double currentTime,  bool isShuffle,  bool isPlaying,  List<PlaybackStateEntry> queue,  DateTime updatedAt,  String? podcastId)?  $default,) {final _that = this;
switch (_that) {
case _RemotePlaybackState() when $default != null:
return $default(_that.playbackType,_that.currentIndex,_that.currentTime,_that.isShuffle,_that.isPlaying,_that.queue,_that.updatedAt,_that.podcastId);case _:
  return null;

}
}

}

/// @nodoc


class _RemotePlaybackState implements RemotePlaybackState {
  const _RemotePlaybackState({required this.playbackType, required this.currentIndex, required this.currentTime, required this.isShuffle, required this.isPlaying, required  List<PlaybackStateEntry> queue, required this.updatedAt, this.podcastId}): _queue = queue;
  

/// What was playing.
@override final  PlaybackStateType playbackType;
/// The index of the current entry in [queue].
@override final  int currentIndex;
/// The position in the current entry, in seconds.
@override final  double currentTime;
/// Whether shuffle was on.
@override final  bool isShuffle;
/// Whether playback was running.
@override final  bool isPlaying;
/// The stored queue, at most 100 entries.
 final  List<PlaybackStateEntry> _queue;
/// The stored queue, at most 100 entries.
@override List<PlaybackStateEntry> get queue {
  if (_queue is EqualUnmodifiableListView) return _queue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_queue);
}

/// When the server stored the state, in UTC.
@override final  DateTime updatedAt;
/// The current podcast, for a podcast state.
@override final  String? podcastId;

/// Create a copy of RemotePlaybackState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RemotePlaybackStateCopyWith<_RemotePlaybackState> get copyWith => __$RemotePlaybackStateCopyWithImpl<_RemotePlaybackState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RemotePlaybackState&&(identical(other.playbackType, playbackType) || other.playbackType == playbackType)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.currentTime, currentTime) || other.currentTime == currentTime)&&(identical(other.isShuffle, isShuffle) || other.isShuffle == isShuffle)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&const DeepCollectionEquality().equals(other.queue, _queue)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.podcastId, podcastId) || other.podcastId == podcastId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,playbackType,currentIndex,currentTime,isShuffle,isPlaying,const DeepCollectionEquality().hash(_queue),updatedAt,podcastId);
}

@override
String toString() {
    return 'RemotePlaybackState(playbackType: $playbackType, currentIndex: $currentIndex, currentTime: $currentTime, isShuffle: $isShuffle, isPlaying: $isPlaying, queue: $queue, updatedAt: $updatedAt, podcastId: $podcastId)';
}


}

/// @nodoc
abstract mixin class _$RemotePlaybackStateCopyWith<$Res> implements $RemotePlaybackStateCopyWith<$Res> {
  factory _$RemotePlaybackStateCopyWith(_RemotePlaybackState value, $Res Function(_RemotePlaybackState) _then) = __$RemotePlaybackStateCopyWithImpl;
@override @useResult
$Res call({
 PlaybackStateType playbackType, int currentIndex, double currentTime, bool isShuffle, bool isPlaying, List<PlaybackStateEntry> queue, DateTime updatedAt, String? podcastId
});




}
/// @nodoc
class __$RemotePlaybackStateCopyWithImpl<$Res>
    implements _$RemotePlaybackStateCopyWith<$Res> {
  __$RemotePlaybackStateCopyWithImpl(this._self, this._then);

  final _RemotePlaybackState _self;
  final $Res Function(_RemotePlaybackState) _then;

/// Create a copy of RemotePlaybackState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playbackType = null,Object? currentIndex = null,Object? currentTime = null,Object? isShuffle = null,Object? isPlaying = null,Object? queue = null,Object? updatedAt = null,Object? podcastId = freezed,}) {
  return _then(_RemotePlaybackState(
playbackType: null == playbackType ? _self.playbackType : playbackType // ignore: cast_nullable_to_non_nullable
as PlaybackStateType,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,currentTime: null == currentTime ? _self.currentTime : currentTime // ignore: cast_nullable_to_non_nullable
as double,isShuffle: null == isShuffle ? _self.isShuffle : isShuffle // ignore: cast_nullable_to_non_nullable
as bool,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,queue: null == queue ? _self._queue : queue // ignore: cast_nullable_to_non_nullable
as List<PlaybackStateEntry>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,podcastId: freezed == podcastId ? _self.podcastId : podcastId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
