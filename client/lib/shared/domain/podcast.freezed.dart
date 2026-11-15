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
 String? get author;/// The podcast's description, if any.
 String? get description;/// The value to pass to the cover-art endpoint, if any.
 String? get artworkRef;/// How many episodes the podcast has, if known.
 int? get episodeCount;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Podcast&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.artworkRef, _this.artworkRef) || other.artworkRef == _this.artworkRef)&&(identical(other.episodeCount, _this.episodeCount) || other.episodeCount == _this.episodeCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Podcast;
  return Object.hash(runtimeType,_this.id,_this.title,_this.author,_this.description,_this.artworkRef,_this.episodeCount);
}

@override
String toString() {
  final _this = this as Podcast;
  return 'Podcast(id: ${_this.id}, title: ${_this.title}, author: ${_this.author}, description: ${_this.description}, artworkRef: ${_this.artworkRef}, episodeCount: ${_this.episodeCount})';
}


}

/// @nodoc
abstract mixin class $PodcastCopyWith<$Res>  {
  factory $PodcastCopyWith(Podcast value, $Res Function(Podcast) _then) = _$PodcastCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? author, String? description, String? artworkRef, int? episodeCount
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? author = freezed,Object? description = freezed,Object? artworkRef = freezed,Object? episodeCount = freezed,}) {
  return _then(Podcast(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,episodeCount: freezed == episodeCount ? _self.episodeCount : episodeCount // ignore: cast_nullable_to_non_nullable
as int?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? author,  String? description,  String? artworkRef,  int? episodeCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Podcast() when $default != null:
return $default(_that.id,_that.title,_that.author,_that.description,_that.artworkRef,_that.episodeCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? author,  String? description,  String? artworkRef,  int? episodeCount)  $default,) {final _that = this;
switch (_that) {
case _Podcast():
return $default(_that.id,_that.title,_that.author,_that.description,_that.artworkRef,_that.episodeCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? author,  String? description,  String? artworkRef,  int? episodeCount)?  $default,) {final _that = this;
switch (_that) {
case _Podcast() when $default != null:
return $default(_that.id,_that.title,_that.author,_that.description,_that.artworkRef,_that.episodeCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Podcast implements Podcast {
  const _Podcast({required this.id, required this.title, this.author, this.description, this.artworkRef, this.episodeCount});
  factory _Podcast.fromJson(Map<String, dynamic> json) => _$PodcastFromJson(json);

/// The server's podcast id.
@override final  String id;
/// The podcast title.
@override final  String title;
/// The author, if known.
@override final  String? author;
/// The podcast's description, if any.
@override final  String? description;
/// The value to pass to the cover-art endpoint, if any.
@override final  String? artworkRef;
/// How many episodes the podcast has, if known.
@override final  int? episodeCount;

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Podcast&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.description, description) || other.description == description)&&(identical(other.artworkRef, artworkRef) || other.artworkRef == artworkRef)&&(identical(other.episodeCount, episodeCount) || other.episodeCount == episodeCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,author,description,artworkRef,episodeCount);
}

@override
String toString() {
    return 'Podcast(id: $id, title: $title, author: $author, description: $description, artworkRef: $artworkRef, episodeCount: $episodeCount)';
}


}

/// @nodoc
abstract mixin class _$PodcastCopyWith<$Res> implements $PodcastCopyWith<$Res> {
  factory _$PodcastCopyWith(_Podcast value, $Res Function(_Podcast) _then) = __$PodcastCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? author, String? description, String? artworkRef, int? episodeCount
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? author = freezed,Object? description = freezed,Object? artworkRef = freezed,Object? episodeCount = freezed,}) {
  return _then(_Podcast(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,episodeCount: freezed == episodeCount ? _self.episodeCount : episodeCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$PodcastSummary {

/// The podcast id the server sent.
 String get id;/// The podcast title.
 String get title;/// The author, if known.
 String? get author;/// The value to pass to the cover-art endpoint, if any.
 String? get artworkRef;/// The podcast's RSS feed URL, if the server sent one.
 String? get feedUrl;/// The podcast's iTunes directory id, if the server sent one.
 String? get itunesId;
/// Create a copy of PodcastSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PodcastSummaryCopyWith<PodcastSummary> get copyWith => _$PodcastSummaryCopyWithImpl<PodcastSummary>(this as PodcastSummary, _$identity);

  /// Serializes this PodcastSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PodcastSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PodcastSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.artworkRef, _this.artworkRef) || other.artworkRef == _this.artworkRef)&&(identical(other.feedUrl, _this.feedUrl) || other.feedUrl == _this.feedUrl)&&(identical(other.itunesId, _this.itunesId) || other.itunesId == _this.itunesId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PodcastSummary;
  return Object.hash(runtimeType,_this.id,_this.title,_this.author,_this.artworkRef,_this.feedUrl,_this.itunesId);
}

@override
String toString() {
  final _this = this as PodcastSummary;
  return 'PodcastSummary(id: ${_this.id}, title: ${_this.title}, author: ${_this.author}, artworkRef: ${_this.artworkRef}, feedUrl: ${_this.feedUrl}, itunesId: ${_this.itunesId})';
}


}

/// @nodoc
abstract mixin class $PodcastSummaryCopyWith<$Res>  {
  factory $PodcastSummaryCopyWith(PodcastSummary value, $Res Function(PodcastSummary) _then) = _$PodcastSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? author, String? artworkRef, String? feedUrl, String? itunesId
});




}
/// @nodoc
class _$PodcastSummaryCopyWithImpl<$Res>
    implements $PodcastSummaryCopyWith<$Res> {
  _$PodcastSummaryCopyWithImpl(this._self, this._then);

  final PodcastSummary _self;
  final $Res Function(PodcastSummary) _then;

/// Create a copy of PodcastSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? author = freezed,Object? artworkRef = freezed,Object? feedUrl = freezed,Object? itunesId = freezed,}) {
  return _then(PodcastSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,feedUrl: freezed == feedUrl ? _self.feedUrl : feedUrl // ignore: cast_nullable_to_non_nullable
as String?,itunesId: freezed == itunesId ? _self.itunesId : itunesId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PodcastSummary].
extension PodcastSummaryPatterns on PodcastSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PodcastSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PodcastSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PodcastSummary value)  $default,){
final _that = this;
switch (_that) {
case _PodcastSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PodcastSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PodcastSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? author,  String? artworkRef,  String? feedUrl,  String? itunesId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PodcastSummary() when $default != null:
return $default(_that.id,_that.title,_that.author,_that.artworkRef,_that.feedUrl,_that.itunesId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? author,  String? artworkRef,  String? feedUrl,  String? itunesId)  $default,) {final _that = this;
switch (_that) {
case _PodcastSummary():
return $default(_that.id,_that.title,_that.author,_that.artworkRef,_that.feedUrl,_that.itunesId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? author,  String? artworkRef,  String? feedUrl,  String? itunesId)?  $default,) {final _that = this;
switch (_that) {
case _PodcastSummary() when $default != null:
return $default(_that.id,_that.title,_that.author,_that.artworkRef,_that.feedUrl,_that.itunesId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PodcastSummary implements PodcastSummary {
  const _PodcastSummary({required this.id, required this.title, this.author, this.artworkRef, this.feedUrl, this.itunesId});
  factory _PodcastSummary.fromJson(Map<String, dynamic> json) => _$PodcastSummaryFromJson(json);

/// The podcast id the server sent.
@override final  String id;
/// The podcast title.
@override final  String title;
/// The author, if known.
@override final  String? author;
/// The value to pass to the cover-art endpoint, if any.
@override final  String? artworkRef;
/// The podcast's RSS feed URL, if the server sent one.
@override final  String? feedUrl;
/// The podcast's iTunes directory id, if the server sent one.
@override final  String? itunesId;

/// Create a copy of PodcastSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PodcastSummaryCopyWith<_PodcastSummary> get copyWith => __$PodcastSummaryCopyWithImpl<_PodcastSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PodcastSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PodcastSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.artworkRef, artworkRef) || other.artworkRef == artworkRef)&&(identical(other.feedUrl, feedUrl) || other.feedUrl == feedUrl)&&(identical(other.itunesId, itunesId) || other.itunesId == itunesId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,author,artworkRef,feedUrl,itunesId);
}

@override
String toString() {
    return 'PodcastSummary(id: $id, title: $title, author: $author, artworkRef: $artworkRef, feedUrl: $feedUrl, itunesId: $itunesId)';
}


}

/// @nodoc
abstract mixin class _$PodcastSummaryCopyWith<$Res> implements $PodcastSummaryCopyWith<$Res> {
  factory _$PodcastSummaryCopyWith(_PodcastSummary value, $Res Function(_PodcastSummary) _then) = __$PodcastSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? author, String? artworkRef, String? feedUrl, String? itunesId
});




}
/// @nodoc
class __$PodcastSummaryCopyWithImpl<$Res>
    implements _$PodcastSummaryCopyWith<$Res> {
  __$PodcastSummaryCopyWithImpl(this._self, this._then);

  final _PodcastSummary _self;
  final $Res Function(_PodcastSummary) _then;

/// Create a copy of PodcastSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? author = freezed,Object? artworkRef = freezed,Object? feedUrl = freezed,Object? itunesId = freezed,}) {
  return _then(_PodcastSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,feedUrl: freezed == feedUrl ? _self.feedUrl : feedUrl // ignore: cast_nullable_to_non_nullable
as String?,itunesId: freezed == itunesId ? _self.itunesId : itunesId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Episode {

/// The server's episode id.
 String get id;/// The id of the podcast the episode belongs to.
 String get podcastId;/// The episode title.
 String get title;/// The episode's description, if any.
 String? get description;/// The duration in whole seconds, if known.
 int? get durationSec;/// When the episode was published, in UTC, if known.
 DateTime? get publishedAt;/// The value to pass to the cover-art endpoint, if any.
 String? get artworkRef;/// How far the user got, or null when they never played it.
 EpisodeProgress? get progress;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Episode&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.podcastId, _this.podcastId) || other.podcastId == _this.podcastId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.durationSec, _this.durationSec) || other.durationSec == _this.durationSec)&&(identical(other.publishedAt, _this.publishedAt) || other.publishedAt == _this.publishedAt)&&(identical(other.artworkRef, _this.artworkRef) || other.artworkRef == _this.artworkRef)&&(identical(other.progress, _this.progress) || other.progress == _this.progress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Episode;
  return Object.hash(runtimeType,_this.id,_this.podcastId,_this.title,_this.description,_this.durationSec,_this.publishedAt,_this.artworkRef,_this.progress);
}

@override
String toString() {
  final _this = this as Episode;
  return 'Episode(id: ${_this.id}, podcastId: ${_this.podcastId}, title: ${_this.title}, description: ${_this.description}, durationSec: ${_this.durationSec}, publishedAt: ${_this.publishedAt}, artworkRef: ${_this.artworkRef}, progress: ${_this.progress})';
}


}

/// @nodoc
abstract mixin class $EpisodeCopyWith<$Res>  {
  factory $EpisodeCopyWith(Episode value, $Res Function(Episode) _then) = _$EpisodeCopyWithImpl;
@useResult
$Res call({
 String id, String podcastId, String title, String? description, int? durationSec, DateTime? publishedAt, String? artworkRef, EpisodeProgress? progress
});


$EpisodeProgressCopyWith<$Res>? get progress;

}
/// @nodoc
class _$EpisodeCopyWithImpl<$Res>
    implements $EpisodeCopyWith<$Res> {
  _$EpisodeCopyWithImpl(this._self, this._then);

  final Episode _self;
  final $Res Function(Episode) _then;

/// Create a copy of Episode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? podcastId = null,Object? title = null,Object? description = freezed,Object? durationSec = freezed,Object? publishedAt = freezed,Object? artworkRef = freezed,Object? progress = freezed,}) {
  return _then(Episode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,podcastId: null == podcastId ? _self.podcastId : podcastId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,durationSec: freezed == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as EpisodeProgress?,
  ));
}
/// Create a copy of Episode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EpisodeProgressCopyWith<$Res>? get progress {
    if (_self.progress == null) {
    return null;
  }

  return $EpisodeProgressCopyWith<$Res>(_self.progress!, (value) {
    return _then(_self.copyWith(progress: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String podcastId,  String title,  String? description,  int? durationSec,  DateTime? publishedAt,  String? artworkRef,  EpisodeProgress? progress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Episode() when $default != null:
return $default(_that.id,_that.podcastId,_that.title,_that.description,_that.durationSec,_that.publishedAt,_that.artworkRef,_that.progress);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String podcastId,  String title,  String? description,  int? durationSec,  DateTime? publishedAt,  String? artworkRef,  EpisodeProgress? progress)  $default,) {final _that = this;
switch (_that) {
case _Episode():
return $default(_that.id,_that.podcastId,_that.title,_that.description,_that.durationSec,_that.publishedAt,_that.artworkRef,_that.progress);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String podcastId,  String title,  String? description,  int? durationSec,  DateTime? publishedAt,  String? artworkRef,  EpisodeProgress? progress)?  $default,) {final _that = this;
switch (_that) {
case _Episode() when $default != null:
return $default(_that.id,_that.podcastId,_that.title,_that.description,_that.durationSec,_that.publishedAt,_that.artworkRef,_that.progress);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Episode implements Episode {
  const _Episode({required this.id, required this.podcastId, required this.title, this.description, this.durationSec, this.publishedAt, this.artworkRef, this.progress});
  factory _Episode.fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);

/// The server's episode id.
@override final  String id;
/// The id of the podcast the episode belongs to.
@override final  String podcastId;
/// The episode title.
@override final  String title;
/// The episode's description, if any.
@override final  String? description;
/// The duration in whole seconds, if known.
@override final  int? durationSec;
/// When the episode was published, in UTC, if known.
@override final  DateTime? publishedAt;
/// The value to pass to the cover-art endpoint, if any.
@override final  String? artworkRef;
/// How far the user got, or null when they never played it.
@override final  EpisodeProgress? progress;

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Episode&&(identical(other.id, id) || other.id == id)&&(identical(other.podcastId, podcastId) || other.podcastId == podcastId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.artworkRef, artworkRef) || other.artworkRef == artworkRef)&&(identical(other.progress, progress) || other.progress == progress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,podcastId,title,description,durationSec,publishedAt,artworkRef,progress);
}

@override
String toString() {
    return 'Episode(id: $id, podcastId: $podcastId, title: $title, description: $description, durationSec: $durationSec, publishedAt: $publishedAt, artworkRef: $artworkRef, progress: $progress)';
}


}

/// @nodoc
abstract mixin class _$EpisodeCopyWith<$Res> implements $EpisodeCopyWith<$Res> {
  factory _$EpisodeCopyWith(_Episode value, $Res Function(_Episode) _then) = __$EpisodeCopyWithImpl;
@override @useResult
$Res call({
 String id, String podcastId, String title, String? description, int? durationSec, DateTime? publishedAt, String? artworkRef, EpisodeProgress? progress
});


@override $EpisodeProgressCopyWith<$Res>? get progress;

}
/// @nodoc
class __$EpisodeCopyWithImpl<$Res>
    implements _$EpisodeCopyWith<$Res> {
  __$EpisodeCopyWithImpl(this._self, this._then);

  final _Episode _self;
  final $Res Function(_Episode) _then;

/// Create a copy of Episode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? podcastId = null,Object? title = null,Object? description = freezed,Object? durationSec = freezed,Object? publishedAt = freezed,Object? artworkRef = freezed,Object? progress = freezed,}) {
  return _then(_Episode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,podcastId: null == podcastId ? _self.podcastId : podcastId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,durationSec: freezed == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,artworkRef: freezed == artworkRef ? _self.artworkRef : artworkRef // ignore: cast_nullable_to_non_nullable
as String?,progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as EpisodeProgress?,
  ));
}

/// Create a copy of Episode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EpisodeProgressCopyWith<$Res>? get progress {
    if (_self.progress == null) {
    return null;
  }

  return $EpisodeProgressCopyWith<$Res>(_self.progress!, (value) {
    return _then(_self.copyWith(progress: value));
  });
}
}


/// @nodoc
mixin _$EpisodeProgress {

/// The position reached, in seconds.
 double get currentTimeSec;/// Whether the user finished the episode.
 bool get isFinished;
/// Create a copy of EpisodeProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EpisodeProgressCopyWith<EpisodeProgress> get copyWith => _$EpisodeProgressCopyWithImpl<EpisodeProgress>(this as EpisodeProgress, _$identity);

  /// Serializes this EpisodeProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EpisodeProgress;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EpisodeProgress&&(identical(other.currentTimeSec, _this.currentTimeSec) || other.currentTimeSec == _this.currentTimeSec)&&(identical(other.isFinished, _this.isFinished) || other.isFinished == _this.isFinished));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EpisodeProgress;
  return Object.hash(runtimeType,_this.currentTimeSec,_this.isFinished);
}

@override
String toString() {
  final _this = this as EpisodeProgress;
  return 'EpisodeProgress(currentTimeSec: ${_this.currentTimeSec}, isFinished: ${_this.isFinished})';
}


}

/// @nodoc
abstract mixin class $EpisodeProgressCopyWith<$Res>  {
  factory $EpisodeProgressCopyWith(EpisodeProgress value, $Res Function(EpisodeProgress) _then) = _$EpisodeProgressCopyWithImpl;
@useResult
$Res call({
 double currentTimeSec, bool isFinished
});




}
/// @nodoc
class _$EpisodeProgressCopyWithImpl<$Res>
    implements $EpisodeProgressCopyWith<$Res> {
  _$EpisodeProgressCopyWithImpl(this._self, this._then);

  final EpisodeProgress _self;
  final $Res Function(EpisodeProgress) _then;

/// Create a copy of EpisodeProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentTimeSec = null,Object? isFinished = null,}) {
  return _then(EpisodeProgress(
currentTimeSec: null == currentTimeSec ? _self.currentTimeSec : currentTimeSec // ignore: cast_nullable_to_non_nullable
as double,isFinished: null == isFinished ? _self.isFinished : isFinished // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [EpisodeProgress].
extension EpisodeProgressPatterns on EpisodeProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EpisodeProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EpisodeProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EpisodeProgress value)  $default,){
final _that = this;
switch (_that) {
case _EpisodeProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EpisodeProgress value)?  $default,){
final _that = this;
switch (_that) {
case _EpisodeProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double currentTimeSec,  bool isFinished)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EpisodeProgress() when $default != null:
return $default(_that.currentTimeSec,_that.isFinished);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double currentTimeSec,  bool isFinished)  $default,) {final _that = this;
switch (_that) {
case _EpisodeProgress():
return $default(_that.currentTimeSec,_that.isFinished);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double currentTimeSec,  bool isFinished)?  $default,) {final _that = this;
switch (_that) {
case _EpisodeProgress() when $default != null:
return $default(_that.currentTimeSec,_that.isFinished);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EpisodeProgress implements EpisodeProgress {
  const _EpisodeProgress({required this.currentTimeSec, required this.isFinished});
  factory _EpisodeProgress.fromJson(Map<String, dynamic> json) => _$EpisodeProgressFromJson(json);

/// The position reached, in seconds.
@override final  double currentTimeSec;
/// Whether the user finished the episode.
@override final  bool isFinished;

/// Create a copy of EpisodeProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EpisodeProgressCopyWith<_EpisodeProgress> get copyWith => __$EpisodeProgressCopyWithImpl<_EpisodeProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EpisodeProgressToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EpisodeProgress&&(identical(other.currentTimeSec, currentTimeSec) || other.currentTimeSec == currentTimeSec)&&(identical(other.isFinished, isFinished) || other.isFinished == isFinished));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,currentTimeSec,isFinished);
}

@override
String toString() {
    return 'EpisodeProgress(currentTimeSec: $currentTimeSec, isFinished: $isFinished)';
}


}

/// @nodoc
abstract mixin class _$EpisodeProgressCopyWith<$Res> implements $EpisodeProgressCopyWith<$Res> {
  factory _$EpisodeProgressCopyWith(_EpisodeProgress value, $Res Function(_EpisodeProgress) _then) = __$EpisodeProgressCopyWithImpl;
@override @useResult
$Res call({
 double currentTimeSec, bool isFinished
});




}
/// @nodoc
class __$EpisodeProgressCopyWithImpl<$Res>
    implements _$EpisodeProgressCopyWith<$Res> {
  __$EpisodeProgressCopyWithImpl(this._self, this._then);

  final _EpisodeProgress _self;
  final $Res Function(_EpisodeProgress) _then;

/// Create a copy of EpisodeProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentTimeSec = null,Object? isFinished = null,}) {
  return _then(_EpisodeProgress(
currentTimeSec: null == currentTimeSec ? _self.currentTimeSec : currentTimeSec // ignore: cast_nullable_to_non_nullable
as double,isFinished: null == isFinished ? _self.isFinished : isFinished // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
