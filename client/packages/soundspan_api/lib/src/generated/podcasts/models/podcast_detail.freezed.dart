// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'podcast_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PodcastDetail {


/// Create a copy of PodcastDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PodcastDetailCopyWith<PodcastDetail> get copyWith => _$PodcastDetailCopyWithImpl<PodcastDetail>(this as PodcastDetail, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PodcastDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PodcastDetail&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.autoDownloadEpisodes, _this.autoDownloadEpisodes) || other.autoDownloadEpisodes == _this.autoDownloadEpisodes)&&(identical(other.coverUrl, _this.coverUrl) || other.coverUrl == _this.coverUrl)&&(identical(other.description, _this.description) || other.description == _this.description)&&const DeepCollectionEquality().equals(other.episodes, _this.episodes)&&(identical(other.feedUrl, _this.feedUrl) || other.feedUrl == _this.feedUrl)&&const DeepCollectionEquality().equals(other.genres, _this.genres)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.isSubscribed, _this.isSubscribed) || other.isSubscribed == _this.isSubscribed)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as PodcastDetail;
  return Object.hash(runtimeType,_this.author,_this.autoDownloadEpisodes,_this.coverUrl,_this.description,const DeepCollectionEquality().hash(_this.episodes),_this.feedUrl,const DeepCollectionEquality().hash(_this.genres),_this.id,_this.isSubscribed,_this.title,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as PodcastDetail;
  return 'PodcastDetail(author: ${_this.author}, autoDownloadEpisodes: ${_this.autoDownloadEpisodes}, coverUrl: ${_this.coverUrl}, description: ${_this.description}, episodes: ${_this.episodes}, feedUrl: ${_this.feedUrl}, genres: ${_this.genres}, id: ${_this.id}, isSubscribed: ${_this.isSubscribed}, title: ${_this.title}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $PodcastDetailCopyWith<$Res>  {
  factory $PodcastDetailCopyWith(PodcastDetail value, $Res Function(PodcastDetail) _then) = _$PodcastDetailCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true) String? author,@JsonKey(required: true, disallowNullValue: true) bool autoDownloadEpisodes,@JsonKey(required: true) String? coverUrl,@JsonKey(required: true) String? description,@JsonKey(required: true, disallowNullValue: true) List<PodcastEpisode> episodes,@JsonKey(required: true, disallowNullValue: true) String feedUrl,@JsonKey(required: true, disallowNullValue: true) List<String> genres,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true, disallowNullValue: true) bool isSubscribed,@JsonKey(required: true, disallowNullValue: true) String title,@JsonKey(readValue: PodcastDetail._extras, fromJson: PodcastDetail._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$PodcastDetailCopyWithImpl<$Res>
    implements $PodcastDetailCopyWith<$Res> {
  _$PodcastDetailCopyWithImpl(this._self, this._then);

  final PodcastDetail _self;
  final $Res Function(PodcastDetail) _then;

/// Create a copy of PodcastDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? author = freezed,Object? autoDownloadEpisodes = null,Object? coverUrl = freezed,Object? description = freezed,Object? episodes = null,Object? feedUrl = null,Object? genres = null,Object? id = null,Object? isSubscribed = null,Object? title = null,Object? additionalProperties = null,}) {
  return _then(PodcastDetail(
author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,autoDownloadEpisodes: null == autoDownloadEpisodes ? _self.autoDownloadEpisodes : autoDownloadEpisodes // ignore: cast_nullable_to_non_nullable
as bool,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,episodes: null == episodes ? _self.episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<PodcastEpisode>,feedUrl: null == feedUrl ? _self.feedUrl : feedUrl // ignore: cast_nullable_to_non_nullable
as String,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,isSubscribed: null == isSubscribed ? _self.isSubscribed : isSubscribed // ignore: cast_nullable_to_non_nullable
as bool,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [PodcastDetail].
extension PodcastDetailPatterns on PodcastDetail {
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
