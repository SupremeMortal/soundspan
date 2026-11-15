// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'podcast_episode.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PodcastEpisode {


/// Create a copy of PodcastEpisode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PodcastEpisodeCopyWith<PodcastEpisode> get copyWith => _$PodcastEpisodeCopyWithImpl<PodcastEpisode>(this as PodcastEpisode, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PodcastEpisode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PodcastEpisode&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.episodeNumber, _this.episodeNumber) || other.episodeNumber == _this.episodeNumber)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl)&&(identical(other.isDownloaded, _this.isDownloaded) || other.isDownloaded == _this.isDownloaded)&&(identical(other.progress, _this.progress) || other.progress == _this.progress)&&(identical(other.publishedAt, _this.publishedAt) || other.publishedAt == _this.publishedAt)&&(identical(other.season, _this.season) || other.season == _this.season)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as PodcastEpisode;
  return Object.hash(runtimeType,_this.description,_this.duration,_this.episodeNumber,_this.id,_this.imageUrl,_this.isDownloaded,_this.progress,_this.publishedAt,_this.season,_this.title,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as PodcastEpisode;
  return 'PodcastEpisode(description: ${_this.description}, duration: ${_this.duration}, episodeNumber: ${_this.episodeNumber}, id: ${_this.id}, imageUrl: ${_this.imageUrl}, isDownloaded: ${_this.isDownloaded}, progress: ${_this.progress}, publishedAt: ${_this.publishedAt}, season: ${_this.season}, title: ${_this.title}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $PodcastEpisodeCopyWith<$Res>  {
  factory $PodcastEpisodeCopyWith(PodcastEpisode value, $Res Function(PodcastEpisode) _then) = _$PodcastEpisodeCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true) String? description,@JsonKey(required: true, disallowNullValue: true, fromJson: PodcastEpisode._read_duration, toJson: PodcastEpisode._write_duration) int duration,@JsonKey(required: true, fromJson: PodcastEpisode._read_episodeNumber, toJson: PodcastEpisode._write_episodeNumber) int? episodeNumber,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true) String? imageUrl,@JsonKey(required: true, disallowNullValue: true) bool isDownloaded,@JsonKey(required: true, disallowNullValue: true) EpisodeProgress progress,@JsonKey(required: true, disallowNullValue: true, fromJson: PodcastEpisode._read_publishedAt, toJson: PodcastEpisode._write_publishedAt) DateTime publishedAt,@JsonKey(required: true, fromJson: PodcastEpisode._read_season, toJson: PodcastEpisode._write_season) int? season,@JsonKey(required: true, disallowNullValue: true) String title,@JsonKey(readValue: PodcastEpisode._extras, fromJson: PodcastEpisode._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$EpisodeProgressCopyWith<$Res> get progress;

}
/// @nodoc
class _$PodcastEpisodeCopyWithImpl<$Res>
    implements $PodcastEpisodeCopyWith<$Res> {
  _$PodcastEpisodeCopyWithImpl(this._self, this._then);

  final PodcastEpisode _self;
  final $Res Function(PodcastEpisode) _then;

/// Create a copy of PodcastEpisode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? description = freezed,Object? duration = null,Object? episodeNumber = freezed,Object? id = null,Object? imageUrl = freezed,Object? isDownloaded = null,Object? progress = null,Object? publishedAt = null,Object? season = freezed,Object? title = null,Object? additionalProperties = null,}) {
  return _then(PodcastEpisode(
description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,episodeNumber: freezed == episodeNumber ? _self.episodeNumber : episodeNumber // ignore: cast_nullable_to_non_nullable
as int?,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,isDownloaded: null == isDownloaded ? _self.isDownloaded : isDownloaded // ignore: cast_nullable_to_non_nullable
as bool,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as EpisodeProgress,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,season: freezed == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as int?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of PodcastEpisode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EpisodeProgressCopyWith<$Res> get progress {
  
  return $EpisodeProgressCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}
}


/// Adds pattern-matching-related methods to [PodcastEpisode].
extension PodcastEpisodePatterns on PodcastEpisode {
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
