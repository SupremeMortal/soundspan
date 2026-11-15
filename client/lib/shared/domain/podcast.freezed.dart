// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'podcast.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Podcast {

/// The server's podcast id.
 String get id;/// The podcast title.
 String get title;/// The author, if known.
 String? get author;/// The value to pass to the cover-art endpoint, if any.
 String? get artworkRef;
/// Create a copy of Podcast
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PodcastCopyWith<Podcast> get copyWith => _$PodcastCopyWithImpl<Podcast>(this as Podcast, _$identity);

  /// Serializes this Podcast to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Podcast;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Podcast&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.artworkRef, _this.artworkRef) || other.artworkRef == _this.artworkRef));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Podcast;
  return Object.hash(runtimeType,_this.id,_this.title,_this.author,_this.artworkRef);
}

@override
String toString() {
  final _this = this as Podcast;
  return 'Podcast(id: ${_this.id}, title: ${_this.title}, author: ${_this.author}, artworkRef: ${_this.artworkRef})';
}


}

/// @nodoc
abstract mixin class $PodcastCopyWith<$Res>  {
  factory $PodcastCopyWith(Podcast value, $Res Function(Podcast) _then) = _$PodcastCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? author, String? artworkRef
});




}
/// @nodoc
class _$PodcastCopyWithImpl<$Res>
    implements $PodcastCopyWith<$Res> {
  _$PodcastCopyWithImpl(this._self, this._then);

  final Podcast _self;
  final $Res Function(Podcast) _then;

/// Create a copy of Podcast
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? author = freezed,Object? artworkRef = freezed,}) {
  return _then(Podcast(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Podcast].
extension PodcastPatterns on Podcast {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Podcast value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Podcast() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Podcast value)  $default,){
final _that = this;
switch (_that) {
case _Podcast():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Podcast value)?  $default,){
final _that = this;
switch (_that) {
case _Podcast() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? author,  String? artworkRef)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Podcast() when $default != null:
return $default(_that.id,_that.title,_that.author,_that.artworkRef);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? author,  String? artworkRef)  $default,) {final _that = this;
switch (_that) {
case _Podcast():
return $default(_that.id,_that.title,_that.author,_that.artworkRef);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? author,  String? artworkRef)?  $default,) {final _that = this;
switch (_that) {
case _Podcast() when $default != null:
return $default(_that.id,_that.title,_that.author,_that.artworkRef);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Podcast implements Podcast {
  const _Podcast({required this.id, required this.title, this.author, this.artworkRef});
  factory _Podcast.fromJson(Map<String, dynamic> json) => _$PodcastFromJson(json);

/// The server's podcast id.
@override final  String id;
/// The podcast title.
@override final  String title;
/// The author, if known.
@override final  String? author;
/// The value to pass to the cover-art endpoint, if any.
@override final  String? artworkRef;

/// Create a copy of Podcast
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PodcastCopyWith<_Podcast> get copyWith => __$PodcastCopyWithImpl<_Podcast>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PodcastToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Podcast&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.artworkRef, artworkRef) || other.artworkRef == artworkRef));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,author,artworkRef);
}

@override
String toString() {
    return 'Podcast(id: $id, title: $title, author: $author, artworkRef: $artworkRef)';
}


}

/// @nodoc
abstract mixin class _$PodcastCopyWith<$Res> implements $PodcastCopyWith<$Res> {
  factory _$PodcastCopyWith(_Podcast value, $Res Function(_Podcast) _then) = __$PodcastCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? author, String? artworkRef
});




}
/// @nodoc
class __$PodcastCopyWithImpl<$Res>
    implements _$PodcastCopyWith<$Res> {
  __$PodcastCopyWithImpl(this._self, this._then);

  final _Podcast _self;
  final $Res Function(_Podcast) _then;

/// Create a copy of Podcast
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? author = freezed,Object? artworkRef = freezed,}) {
  return _then(_Podcast(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Episode {

/// The server's episode id.
 String get id;/// The id of the podcast the episode belongs to.
 String get podcastId;/// The episode title.
 String get title;/// The duration in whole seconds, if known.
 int? get durationSec;/// When the episode was published, in UTC, if known.
 DateTime? get publishedAt;/// The value to pass to the cover-art endpoint, if any.
 String? get artworkRef;
/// Create a copy of Episode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EpisodeCopyWith<Episode> get copyWith => _$EpisodeCopyWithImpl<Episode>(this as Episode, _$identity);

  /// Serializes this Episode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Episode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Episode&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.podcastId, _this.podcastId) || other.podcastId == _this.podcastId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.durationSec, _this.durationSec) || other.durationSec == _this.durationSec)&&(identical(other.publishedAt, _this.publishedAt) || other.publishedAt == _this.publishedAt)&&(identical(other.artworkRef, _this.artworkRef) || other.artworkRef == _this.artworkRef));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Episode;
  return Object.hash(runtimeType,_this.id,_this.podcastId,_this.title,_this.durationSec,_this.publishedAt,_this.artworkRef);
}

@override
String toString() {
  final _this = this as Episode;
  return 'Episode(id: ${_this.id}, podcastId: ${_this.podcastId}, title: ${_this.title}, durationSec: ${_this.durationSec}, publishedAt: ${_this.publishedAt}, artworkRef: ${_this.artworkRef})';
}


}

/// @nodoc
abstract mixin class $EpisodeCopyWith<$Res>  {
  factory $EpisodeCopyWith(Episode value, $Res Function(Episode) _then) = _$EpisodeCopyWithImpl;
@useResult
$Res call({
 String id, String podcastId, String title, int? durationSec, DateTime? publishedAt, String? artworkRef
});




}
/// @nodoc
class _$EpisodeCopyWithImpl<$Res>
    implements $EpisodeCopyWith<$Res> {
  _$EpisodeCopyWithImpl(this._self, this._then);

  final Episode _self;
  final $Res Function(Episode) _then;

/// Create a copy of Episode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? podcastId = null,Object? title = null,Object? durationSec = freezed,Object? publishedAt = freezed,Object? artworkRef = freezed,}) {
  return _then(Episode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,podcastId: null == podcastId ? _self.podcastId : podcastId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,durationSec: freezed == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Episode].
extension EpisodePatterns on Episode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Episode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Episode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Episode value)  $default,){
final _that = this;
switch (_that) {
case _Episode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Episode value)?  $default,){
final _that = this;
switch (_that) {
case _Episode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String podcastId,  String title,  int? durationSec,  DateTime? publishedAt,  String? artworkRef)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Episode() when $default != null:
return $default(_that.id,_that.podcastId,_that.title,_that.durationSec,_that.publishedAt,_that.artworkRef);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String podcastId,  String title,  int? durationSec,  DateTime? publishedAt,  String? artworkRef)  $default,) {final _that = this;
switch (_that) {
case _Episode():
return $default(_that.id,_that.podcastId,_that.title,_that.durationSec,_that.publishedAt,_that.artworkRef);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String podcastId,  String title,  int? durationSec,  DateTime? publishedAt,  String? artworkRef)?  $default,) {final _that = this;
switch (_that) {
case _Episode() when $default != null:
return $default(_that.id,_that.podcastId,_that.title,_that.durationSec,_that.publishedAt,_that.artworkRef);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Episode implements Episode {
  const _Episode({required this.id, required this.podcastId, required this.title, this.durationSec, this.publishedAt, this.artworkRef});
  factory _Episode.fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);

/// The server's episode id.
@override final  String id;
/// The id of the podcast the episode belongs to.
@override final  String podcastId;
/// The episode title.
@override final  String title;
/// The duration in whole seconds, if known.
@override final  int? durationSec;
/// When the episode was published, in UTC, if known.
@override final  DateTime? publishedAt;
/// The value to pass to the cover-art endpoint, if any.
@override final  String? artworkRef;

/// Create a copy of Episode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EpisodeCopyWith<_Episode> get copyWith => __$EpisodeCopyWithImpl<_Episode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EpisodeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Episode&&(identical(other.id, id) || other.id == id)&&(identical(other.podcastId, podcastId) || other.podcastId == podcastId)&&(identical(other.title, title) || other.title == title)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.artworkRef, artworkRef) || other.artworkRef == artworkRef));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,podcastId,title,durationSec,publishedAt,artworkRef);
}

@override
String toString() {
    return 'Episode(id: $id, podcastId: $podcastId, title: $title, durationSec: $durationSec, publishedAt: $publishedAt, artworkRef: $artworkRef)';
}


}

/// @nodoc
abstract mixin class _$EpisodeCopyWith<$Res> implements $EpisodeCopyWith<$Res> {
  factory _$EpisodeCopyWith(_Episode value, $Res Function(_Episode) _then) = __$EpisodeCopyWithImpl;
@override @useResult
$Res call({
 String id, String podcastId, String title, int? durationSec, DateTime? publishedAt, String? artworkRef
});




}
/// @nodoc
class __$EpisodeCopyWithImpl<$Res>
    implements _$EpisodeCopyWith<$Res> {
  __$EpisodeCopyWithImpl(this._self, this._then);

  final _Episode _self;
  final $Res Function(_Episode) _then;

/// Create a copy of Episode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? podcastId = null,Object? title = null,Object? durationSec = freezed,Object? publishedAt = freezed,Object? artworkRef = freezed,}) {
  return _then(_Episode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,podcastId: null == podcastId ? _self.podcastId : podcastId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,durationSec: freezed == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
