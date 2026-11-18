// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'queue_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QueueContext {

/// What kind of list the item came from.
 QueueContextKind get kind;/// The id of that list (album, playlist, artist, mix), if it has one.
 String? get id;/// The title of that list, for display.
 String? get title;
/// Create a copy of QueueContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueContextCopyWith<QueueContext> get copyWith => _$QueueContextCopyWithImpl<QueueContext>(this as QueueContext, _$identity);

  /// Serializes this QueueContext to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as QueueContext;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueContext&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as QueueContext;
  return Object.hash(runtimeType,_this.kind,_this.id,_this.title);
}

@override
String toString() {
  final _this = this as QueueContext;
  return 'QueueContext(kind: ${_this.kind}, id: ${_this.id}, title: ${_this.title})';
}


}

/// @nodoc
abstract mixin class $QueueContextCopyWith<$Res>  {
  factory $QueueContextCopyWith(QueueContext value, $Res Function(QueueContext) _then) = _$QueueContextCopyWithImpl;
@useResult
$Res call({
 QueueContextKind kind, String? id, String? title
});




}
/// @nodoc
class _$QueueContextCopyWithImpl<$Res>
    implements $QueueContextCopyWith<$Res> {
  _$QueueContextCopyWithImpl(this._self, this._then);

  final QueueContext _self;
  final $Res Function(QueueContext) _then;

/// Create a copy of QueueContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? id = freezed,Object? title = freezed,}) {
  return _then(QueueContext(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as QueueContextKind,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [QueueContext].
extension QueueContextPatterns on QueueContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueueContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueueContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueueContext value)  $default,){
final _that = this;
switch (_that) {
case _QueueContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueueContext value)?  $default,){
final _that = this;
switch (_that) {
case _QueueContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( QueueContextKind kind,  String? id,  String? title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueueContext() when $default != null:
return $default(_that.kind,_that.id,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( QueueContextKind kind,  String? id,  String? title)  $default,) {final _that = this;
switch (_that) {
case _QueueContext():
return $default(_that.kind,_that.id,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( QueueContextKind kind,  String? id,  String? title)?  $default,) {final _that = this;
switch (_that) {
case _QueueContext() when $default != null:
return $default(_that.kind,_that.id,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QueueContext implements QueueContext {
  const _QueueContext({required this.kind, this.id, this.title});
  factory _QueueContext.fromJson(Map<String, dynamic> json) => _$QueueContextFromJson(json);

/// What kind of list the item came from.
@override final  QueueContextKind kind;
/// The id of that list (album, playlist, artist, mix), if it has one.
@override final  String? id;
/// The title of that list, for display.
@override final  String? title;

/// Create a copy of QueueContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueContextCopyWith<_QueueContext> get copyWith => __$QueueContextCopyWithImpl<_QueueContext>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QueueContextToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueueContext&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,id,title);
}

@override
String toString() {
    return 'QueueContext(kind: $kind, id: $id, title: $title)';
}


}

/// @nodoc
abstract mixin class _$QueueContextCopyWith<$Res> implements $QueueContextCopyWith<$Res> {
  factory _$QueueContextCopyWith(_QueueContext value, $Res Function(_QueueContext) _then) = __$QueueContextCopyWithImpl;
@override @useResult
$Res call({
 QueueContextKind kind, String? id, String? title
});




}
/// @nodoc
class __$QueueContextCopyWithImpl<$Res>
    implements _$QueueContextCopyWith<$Res> {
  __$QueueContextCopyWithImpl(this._self, this._then);

  final _QueueContext _self;
  final $Res Function(_QueueContext) _then;

/// Create a copy of QueueContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? id = freezed,Object? title = freezed,}) {
  return _then(_QueueContext(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as QueueContextKind,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

QueueItem _$QueueItemFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'track':
          return TrackQueueItem.fromJson(
            json
          );
                case 'episode':
          return EpisodeQueueItem.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'QueueItem',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$QueueItem {

/// Client-generated UUID, unique per queue entry.
 String get queueItemId;
/// Create a copy of QueueItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueItemCopyWith<QueueItem> get copyWith => _$QueueItemCopyWithImpl<QueueItem>(this as QueueItem, _$identity);

  /// Serializes this QueueItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as QueueItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueItem&&(identical(other.queueItemId, _this.queueItemId) || other.queueItemId == _this.queueItemId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as QueueItem;
  return Object.hash(runtimeType,_this.queueItemId);
}

@override
String toString() {
  final _this = this as QueueItem;
  return 'QueueItem(queueItemId: ${_this.queueItemId})';
}


}

/// @nodoc
abstract mixin class $QueueItemCopyWith<$Res>  {
  factory $QueueItemCopyWith(QueueItem value, $Res Function(QueueItem) _then) = _$QueueItemCopyWithImpl;
@useResult
$Res call({
 String queueItemId
});




}
/// @nodoc
class _$QueueItemCopyWithImpl<$Res>
    implements $QueueItemCopyWith<$Res> {
  _$QueueItemCopyWithImpl(this._self, this._then);

  final QueueItem _self;
  final $Res Function(QueueItem) _then;

/// Create a copy of QueueItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? queueItemId = null,}) {
  return _then(_self.copyWith(
queueItemId: null == queueItemId ? _self.queueItemId : queueItemId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [QueueItem].
extension QueueItemPatterns on QueueItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TrackQueueItem value)?  track,TResult Function( EpisodeQueueItem value)?  episode,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TrackQueueItem() when track != null:
return track(_that);case EpisodeQueueItem() when episode != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TrackQueueItem value)  track,required TResult Function( EpisodeQueueItem value)  episode,}){
final _that = this;
switch (_that) {
case TrackQueueItem():
return track(_that);case EpisodeQueueItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TrackQueueItem value)?  track,TResult? Function( EpisodeQueueItem value)?  episode,}){
final _that = this;
switch (_that) {
case TrackQueueItem() when track != null:
return track(_that);case EpisodeQueueItem() when episode != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String queueItemId,  Track track,  QueueContext context)?  track,TResult Function( String queueItemId,  Episode episode,  Podcast podcast)?  episode,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TrackQueueItem() when track != null:
return track(_that.queueItemId,_that.track,_that.context);case EpisodeQueueItem() when episode != null:
return episode(_that.queueItemId,_that.episode,_that.podcast);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String queueItemId,  Track track,  QueueContext context)  track,required TResult Function( String queueItemId,  Episode episode,  Podcast podcast)  episode,}) {final _that = this;
switch (_that) {
case TrackQueueItem():
return track(_that.queueItemId,_that.track,_that.context);case EpisodeQueueItem():
return episode(_that.queueItemId,_that.episode,_that.podcast);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String queueItemId,  Track track,  QueueContext context)?  track,TResult? Function( String queueItemId,  Episode episode,  Podcast podcast)?  episode,}) {final _that = this;
switch (_that) {
case TrackQueueItem() when track != null:
return track(_that.queueItemId,_that.track,_that.context);case EpisodeQueueItem() when episode != null:
return episode(_that.queueItemId,_that.episode,_that.podcast);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class TrackQueueItem implements QueueItem {
  const TrackQueueItem({required this.queueItemId, required this.track, required this.context,  String? $type}): $type = $type ?? 'track';
  factory TrackQueueItem.fromJson(Map<String, dynamic> json) => _$TrackQueueItemFromJson(json);

/// Client-generated UUID, unique per queue entry.
@override final  String queueItemId;
/// The track.
 final  Track track;
/// Where the track was queued from.
 final  QueueContext context;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of QueueItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackQueueItemCopyWith<TrackQueueItem> get copyWith => _$TrackQueueItemCopyWithImpl<TrackQueueItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackQueueItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackQueueItem&&(identical(other.queueItemId, queueItemId) || other.queueItemId == queueItemId)&&(identical(other.track, track) || other.track == track)&&(identical(other.context, context) || other.context == context));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,queueItemId,track,context);
}

@override
String toString() {
    return 'QueueItem.track(queueItemId: $queueItemId, track: $track, context: $context)';
}


}

/// @nodoc
abstract mixin class $TrackQueueItemCopyWith<$Res> implements $QueueItemCopyWith<$Res> {
  factory $TrackQueueItemCopyWith(TrackQueueItem value, $Res Function(TrackQueueItem) _then) = _$TrackQueueItemCopyWithImpl;
@override @useResult
$Res call({
 String queueItemId, Track track, QueueContext context
});


$TrackCopyWith<$Res> get track;$QueueContextCopyWith<$Res> get context;

}
/// @nodoc
class _$TrackQueueItemCopyWithImpl<$Res>
    implements $TrackQueueItemCopyWith<$Res> {
  _$TrackQueueItemCopyWithImpl(this._self, this._then);

  final TrackQueueItem _self;
  final $Res Function(TrackQueueItem) _then;

/// Create a copy of QueueItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? queueItemId = null,Object? track = null,Object? context = null,}) {
  return _then(TrackQueueItem(
queueItemId: null == queueItemId ? _self.queueItemId : queueItemId // ignore: cast_nullable_to_non_nullable
as String,track: null == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as Track,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as QueueContext,
  ));
}

/// Create a copy of QueueItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackCopyWith<$Res> get track {
  
  return $TrackCopyWith<$Res>(_self.track, (value) {
    return _then(_self.copyWith(track: value));
  });
}/// Create a copy of QueueItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QueueContextCopyWith<$Res> get context {
  
  return $QueueContextCopyWith<$Res>(_self.context, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class EpisodeQueueItem implements QueueItem {
  const EpisodeQueueItem({required this.queueItemId, required this.episode, required this.podcast,  String? $type}): $type = $type ?? 'episode';
  factory EpisodeQueueItem.fromJson(Map<String, dynamic> json) => _$EpisodeQueueItemFromJson(json);

/// Client-generated UUID, unique per queue entry.
@override final  String queueItemId;
/// The episode.
 final  Episode episode;
/// The podcast the episode belongs to.
 final  Podcast podcast;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of QueueItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EpisodeQueueItemCopyWith<EpisodeQueueItem> get copyWith => _$EpisodeQueueItemCopyWithImpl<EpisodeQueueItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EpisodeQueueItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EpisodeQueueItem&&(identical(other.queueItemId, queueItemId) || other.queueItemId == queueItemId)&&(identical(other.episode, episode) || other.episode == episode)&&(identical(other.podcast, podcast) || other.podcast == podcast));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,queueItemId,episode,podcast);
}

@override
String toString() {
    return 'QueueItem.episode(queueItemId: $queueItemId, episode: $episode, podcast: $podcast)';
}


}

/// @nodoc
abstract mixin class $EpisodeQueueItemCopyWith<$Res> implements $QueueItemCopyWith<$Res> {
  factory $EpisodeQueueItemCopyWith(EpisodeQueueItem value, $Res Function(EpisodeQueueItem) _then) = _$EpisodeQueueItemCopyWithImpl;
@override @useResult
$Res call({
 String queueItemId, Episode episode, Podcast podcast
});


$EpisodeCopyWith<$Res> get episode;$PodcastCopyWith<$Res> get podcast;

}
/// @nodoc
class _$EpisodeQueueItemCopyWithImpl<$Res>
    implements $EpisodeQueueItemCopyWith<$Res> {
  _$EpisodeQueueItemCopyWithImpl(this._self, this._then);

  final EpisodeQueueItem _self;
  final $Res Function(EpisodeQueueItem) _then;

/// Create a copy of QueueItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? queueItemId = null,Object? episode = null,Object? podcast = null,}) {
  return _then(EpisodeQueueItem(
queueItemId: null == queueItemId ? _self.queueItemId : queueItemId // ignore: cast_nullable_to_non_nullable
as String,episode: null == episode ? _self.episode : episode // ignore: cast_nullable_to_non_nullable
as Episode,podcast: null == podcast ? _self.podcast : podcast // ignore: cast_nullable_to_non_nullable
as Podcast,
  ));
}

/// Create a copy of QueueItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EpisodeCopyWith<$Res> get episode {
  
  return $EpisodeCopyWith<$Res>(_self.episode, (value) {
    return _then(_self.copyWith(episode: value));
  });
}/// Create a copy of QueueItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PodcastCopyWith<$Res> get podcast {
  
  return $PodcastCopyWith<$Res>(_self.podcast, (value) {
    return _then(_self.copyWith(podcast: value));
  });
}
}

// dart format on
