// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchResponse {


/// Create a copy of SearchResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResponseCopyWith<SearchResponse> get copyWith => _$SearchResponseCopyWithImpl<SearchResponse>(this as SearchResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SearchResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResponse&&const DeepCollectionEquality().equals(other.albums, _this.albums)&&const DeepCollectionEquality().equals(other.artists, _this.artists)&&const DeepCollectionEquality().equals(other.episodes, _this.episodes)&&const DeepCollectionEquality().equals(other.podcasts, _this.podcasts)&&const DeepCollectionEquality().equals(other.remoteAlbums, _this.remoteAlbums)&&const DeepCollectionEquality().equals(other.remoteTracks, _this.remoteTracks)&&const DeepCollectionEquality().equals(other.tracks, _this.tracks)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as SearchResponse;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.albums),const DeepCollectionEquality().hash(_this.artists),const DeepCollectionEquality().hash(_this.episodes),const DeepCollectionEquality().hash(_this.podcasts),const DeepCollectionEquality().hash(_this.remoteAlbums),const DeepCollectionEquality().hash(_this.remoteTracks),const DeepCollectionEquality().hash(_this.tracks),const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as SearchResponse;
  return 'SearchResponse(albums: ${_this.albums}, artists: ${_this.artists}, episodes: ${_this.episodes}, podcasts: ${_this.podcasts}, remoteAlbums: ${_this.remoteAlbums}, remoteTracks: ${_this.remoteTracks}, tracks: ${_this.tracks}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $SearchResponseCopyWith<$Res>  {
  factory $SearchResponseCopyWith(SearchResponse value, $Res Function(SearchResponse) _then) = _$SearchResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) List<SearchAlbum> albums,@JsonKey(required: true, disallowNullValue: true) List<SearchArtist> artists,@JsonKey(required: true, disallowNullValue: true) List<SearchEpisode> episodes,@JsonKey(required: true, disallowNullValue: true) List<SearchPodcast> podcasts,@JsonKey(required: true, disallowNullValue: true) List<SearchRemoteAlbum> remoteAlbums,@JsonKey(required: true, disallowNullValue: true) List<SearchRemoteTrack> remoteTracks,@JsonKey(required: true, disallowNullValue: true) List<SearchTrack> tracks,@JsonKey(readValue: SearchResponse._extras, fromJson: SearchResponse._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$SearchResponseCopyWithImpl<$Res>
    implements $SearchResponseCopyWith<$Res> {
  _$SearchResponseCopyWithImpl(this._self, this._then);

  final SearchResponse _self;
  final $Res Function(SearchResponse) _then;

/// Create a copy of SearchResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? albums = null,Object? artists = null,Object? episodes = null,Object? podcasts = null,Object? remoteAlbums = null,Object? remoteTracks = null,Object? tracks = null,Object? additionalProperties = null,}) {
  return _then(SearchResponse(
albums: null == albums ? _self.albums : albums // ignore: cast_nullable_to_non_nullable
as List<SearchAlbum>,artists: null == artists ? _self.artists : artists // ignore: cast_nullable_to_non_nullable
as List<SearchArtist>,episodes: null == episodes ? _self.episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<SearchEpisode>,podcasts: null == podcasts ? _self.podcasts : podcasts // ignore: cast_nullable_to_non_nullable
as List<SearchPodcast>,remoteAlbums: null == remoteAlbums ? _self.remoteAlbums : remoteAlbums // ignore: cast_nullable_to_non_nullable
as List<SearchRemoteAlbum>,remoteTracks: null == remoteTracks ? _self.remoteTracks : remoteTracks // ignore: cast_nullable_to_non_nullable
as List<SearchRemoteTrack>,tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<SearchTrack>,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchResponse].
extension SearchResponsePatterns on SearchResponse {
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
