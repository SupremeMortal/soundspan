// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_episode.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchEpisode {


/// Create a copy of SearchEpisode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchEpisodeCopyWith<SearchEpisode> get copyWith => _$SearchEpisodeCopyWithImpl<SearchEpisode>(this as SearchEpisode, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SearchEpisode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchEpisode&&(identical(other.audioUrl, _this.audioUrl) || other.audioUrl == _this.audioUrl)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.podcastId, _this.podcastId) || other.podcastId == _this.podcastId)&&(identical(other.podcastTitle, _this.podcastTitle) || other.podcastTitle == _this.podcastTitle)&&(identical(other.publishedAt, _this.publishedAt) || other.publishedAt == _this.publishedAt)&&(identical(other.rank, _this.rank) || other.rank == _this.rank)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as SearchEpisode;
  return Object.hash(runtimeType,_this.audioUrl,_this.description,_this.duration,_this.id,_this.podcastId,_this.podcastTitle,_this.publishedAt,_this.rank,_this.title,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as SearchEpisode;
  return 'SearchEpisode(audioUrl: ${_this.audioUrl}, description: ${_this.description}, duration: ${_this.duration}, id: ${_this.id}, podcastId: ${_this.podcastId}, podcastTitle: ${_this.podcastTitle}, publishedAt: ${_this.publishedAt}, rank: ${_this.rank}, title: ${_this.title}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $SearchEpisodeCopyWith<$Res>  {
  factory $SearchEpisodeCopyWith(SearchEpisode value, $Res Function(SearchEpisode) _then) = _$SearchEpisodeCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String audioUrl,@JsonKey(required: true) String? description,@JsonKey(required: true, disallowNullValue: true, fromJson: SearchEpisode._read_duration, toJson: SearchEpisode._write_duration) int duration,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true, disallowNullValue: true) String podcastId,@JsonKey(required: true, disallowNullValue: true) String podcastTitle,@JsonKey(required: true, disallowNullValue: true, fromJson: SearchEpisode._read_publishedAt, toJson: SearchEpisode._write_publishedAt) DateTime publishedAt,@JsonKey(required: true, disallowNullValue: true) num rank,@JsonKey(required: true, disallowNullValue: true) String title,@JsonKey(readValue: SearchEpisode._extras, fromJson: SearchEpisode._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$SearchEpisodeCopyWithImpl<$Res>
    implements $SearchEpisodeCopyWith<$Res> {
  _$SearchEpisodeCopyWithImpl(this._self, this._then);

  final SearchEpisode _self;
  final $Res Function(SearchEpisode) _then;

/// Create a copy of SearchEpisode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? audioUrl = null,Object? description = freezed,Object? duration = null,Object? id = null,Object? podcastId = null,Object? podcastTitle = null,Object? publishedAt = null,Object? rank = null,Object? title = null,Object? additionalProperties = null,}) {
  return _then(SearchEpisode(
audioUrl: null == audioUrl ? _self.audioUrl : audioUrl // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,podcastId: null == podcastId ? _self.podcastId : podcastId // ignore: cast_nullable_to_non_nullable
as String,podcastTitle: null == podcastTitle ? _self.podcastTitle : podcastTitle // ignore: cast_nullable_to_non_nullable
as String,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as num,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchEpisode].
extension SearchEpisodePatterns on SearchEpisode {
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
