// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_podcast.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchPodcast {


/// Create a copy of SearchPodcast
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchPodcastCopyWith<SearchPodcast> get copyWith => _$SearchPodcastCopyWithImpl<SearchPodcast>(this as SearchPodcast, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SearchPodcast;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchPodcast&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.episodeCount, _this.episodeCount) || other.episodeCount == _this.episodeCount)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl)&&(identical(other.rank, _this.rank) || other.rank == _this.rank)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as SearchPodcast;
  return Object.hash(runtimeType,_this.author,_this.description,_this.episodeCount,_this.id,_this.imageUrl,_this.rank,_this.title,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as SearchPodcast;
  return 'SearchPodcast(author: ${_this.author}, description: ${_this.description}, episodeCount: ${_this.episodeCount}, id: ${_this.id}, imageUrl: ${_this.imageUrl}, rank: ${_this.rank}, title: ${_this.title}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $SearchPodcastCopyWith<$Res>  {
  factory $SearchPodcastCopyWith(SearchPodcast value, $Res Function(SearchPodcast) _then) = _$SearchPodcastCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true) String? author,@JsonKey(required: true) String? description,@JsonKey(required: true, disallowNullValue: true, fromJson: SearchPodcast._read_episodeCount, toJson: SearchPodcast._write_episodeCount) int episodeCount,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true) String? imageUrl,@JsonKey(disallowNullValue: true, includeIfNull: false) num? rank,@JsonKey(required: true, disallowNullValue: true) String title,@JsonKey(readValue: SearchPodcast._extras, fromJson: SearchPodcast._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$SearchPodcastCopyWithImpl<$Res>
    implements $SearchPodcastCopyWith<$Res> {
  _$SearchPodcastCopyWithImpl(this._self, this._then);

  final SearchPodcast _self;
  final $Res Function(SearchPodcast) _then;

/// Create a copy of SearchPodcast
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? author = freezed,Object? description = freezed,Object? episodeCount = null,Object? id = null,Object? imageUrl = freezed,Object? rank = freezed,Object? title = null,Object? additionalProperties = null,}) {
  return _then(SearchPodcast(
author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,episodeCount: null == episodeCount ? _self.episodeCount : episodeCount // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,rank: freezed == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as num?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchPodcast].
extension SearchPodcastPatterns on SearchPodcast {
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
