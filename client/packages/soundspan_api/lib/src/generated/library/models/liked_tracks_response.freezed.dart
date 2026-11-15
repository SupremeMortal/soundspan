// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'liked_tracks_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LikedTracksResponse {


/// Create a copy of LikedTracksResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LikedTracksResponseCopyWith<LikedTracksResponse> get copyWith => _$LikedTracksResponseCopyWithImpl<LikedTracksResponse>(this as LikedTracksResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LikedTracksResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LikedTracksResponse&&(identical(other.pagination, _this.pagination) || other.pagination == _this.pagination)&&(identical(other.playlist, _this.playlist) || other.playlist == _this.playlist)&&(identical(other.total, _this.total) || other.total == _this.total)&&const DeepCollectionEquality().equals(other.tracks, _this.tracks)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as LikedTracksResponse;
  return Object.hash(runtimeType,_this.pagination,_this.playlist,_this.total,const DeepCollectionEquality().hash(_this.tracks),const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as LikedTracksResponse;
  return 'LikedTracksResponse(pagination: ${_this.pagination}, playlist: ${_this.playlist}, total: ${_this.total}, tracks: ${_this.tracks}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $LikedTracksResponseCopyWith<$Res>  {
  factory $LikedTracksResponseCopyWith(LikedTracksResponse value, $Res Function(LikedTracksResponse) _then) = _$LikedTracksResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) LikedTracksPagination pagination,@JsonKey(required: true, disallowNullValue: true) LikedPlaylistInfo playlist,@JsonKey(required: true, disallowNullValue: true, fromJson: LikedTracksResponse._read_total, toJson: LikedTracksResponse._write_total) int total,@JsonKey(required: true, disallowNullValue: true) List<LikedTrack> tracks,@JsonKey(readValue: LikedTracksResponse._extras, fromJson: LikedTracksResponse._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$LikedTracksPaginationCopyWith<$Res> get pagination;$LikedPlaylistInfoCopyWith<$Res> get playlist;

}
/// @nodoc
class _$LikedTracksResponseCopyWithImpl<$Res>
    implements $LikedTracksResponseCopyWith<$Res> {
  _$LikedTracksResponseCopyWithImpl(this._self, this._then);

  final LikedTracksResponse _self;
  final $Res Function(LikedTracksResponse) _then;

/// Create a copy of LikedTracksResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pagination = null,Object? playlist = null,Object? total = null,Object? tracks = null,Object? additionalProperties = null,}) {
  return _then(LikedTracksResponse(
pagination: null == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as LikedTracksPagination,playlist: null == playlist ? _self.playlist : playlist // ignore: cast_nullable_to_non_nullable
as LikedPlaylistInfo,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<LikedTrack>,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of LikedTracksResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LikedTracksPaginationCopyWith<$Res> get pagination {
  
  return $LikedTracksPaginationCopyWith<$Res>(_self.pagination, (value) {
    return _then(_self.copyWith(pagination: value));
  });
}/// Create a copy of LikedTracksResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LikedPlaylistInfoCopyWith<$Res> get playlist {
  
  return $LikedPlaylistInfoCopyWith<$Res>(_self.playlist, (value) {
    return _then(_self.copyWith(playlist: value));
  });
}
}


/// Adds pattern-matching-related methods to [LikedTracksResponse].
extension LikedTracksResponsePatterns on LikedTracksResponse {
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
