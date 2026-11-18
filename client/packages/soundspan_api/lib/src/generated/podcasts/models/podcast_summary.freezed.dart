// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'podcast_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PodcastSummary {


/// Create a copy of PodcastSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PodcastSummaryCopyWith<PodcastSummary> get copyWith => _$PodcastSummaryCopyWithImpl<PodcastSummary>(this as PodcastSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PodcastSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PodcastSummary&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.coverUrl, _this.coverUrl) || other.coverUrl == _this.coverUrl)&&(identical(other.episodeCount, _this.episodeCount) || other.episodeCount == _this.episodeCount)&&(identical(other.feedUrl, _this.feedUrl) || other.feedUrl == _this.feedUrl)&&const DeepCollectionEquality().equals(other.genres, _this.genres)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.isExternal, _this.isExternal) || other.isExternal == _this.isExternal)&&(identical(other.itunesId, _this.itunesId) || other.itunesId == _this.itunesId)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as PodcastSummary;
  return Object.hash(runtimeType,_this.author,_this.coverUrl,_this.episodeCount,_this.feedUrl,const DeepCollectionEquality().hash(_this.genres),_this.id,_this.isExternal,_this.itunesId,_this.title,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as PodcastSummary;
  return 'PodcastSummary(author: ${_this.author}, coverUrl: ${_this.coverUrl}, episodeCount: ${_this.episodeCount}, feedUrl: ${_this.feedUrl}, genres: ${_this.genres}, id: ${_this.id}, isExternal: ${_this.isExternal}, itunesId: ${_this.itunesId}, title: ${_this.title}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $PodcastSummaryCopyWith<$Res>  {
  factory $PodcastSummaryCopyWith(PodcastSummary value, $Res Function(PodcastSummary) _then) = _$PodcastSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String author,@JsonKey(disallowNullValue: true, includeIfNull: false) String? coverUrl,@JsonKey(required: true, disallowNullValue: true, fromJson: PodcastSummary._read_episodeCount, toJson: PodcastSummary._write_episodeCount) int episodeCount,@JsonKey(disallowNullValue: true, includeIfNull: false) String? feedUrl,@JsonKey(required: true, disallowNullValue: true) List<String> genres,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true, disallowNullValue: true) bool isExternal,@JsonKey(required: true, disallowNullValue: true, fromJson: PodcastSummary._read_itunesId, toJson: PodcastSummary._write_itunesId) int itunesId,@JsonKey(required: true, disallowNullValue: true) String title,@JsonKey(readValue: PodcastSummary._extras, fromJson: PodcastSummary._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
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
@pragma('vm:prefer-inline') @override $Res call({Object? author = null,Object? coverUrl = freezed,Object? episodeCount = null,Object? feedUrl = freezed,Object? genres = null,Object? id = null,Object? isExternal = null,Object? itunesId = null,Object? title = null,Object? additionalProperties = null,}) {
  return _then(PodcastSummary(
author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,episodeCount: null == episodeCount ? _self.episodeCount : episodeCount // ignore: cast_nullable_to_non_nullable
as int,feedUrl: freezed == feedUrl ? _self.feedUrl : feedUrl // ignore: cast_nullable_to_non_nullable
as String?,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,isExternal: null == isExternal ? _self.isExternal : isExternal // ignore: cast_nullable_to_non_nullable
as bool,itunesId: null == itunesId ? _self.itunesId : itunesId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
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
