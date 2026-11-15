// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_track_list_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LibraryTrackListResponse {


/// Create a copy of LibraryTrackListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryTrackListResponseCopyWith<LibraryTrackListResponse> get copyWith => _$LibraryTrackListResponseCopyWithImpl<LibraryTrackListResponse>(this as LibraryTrackListResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LibraryTrackListResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryTrackListResponse&&(identical(other.limit, _this.limit) || other.limit == _this.limit)&&(identical(other.offset, _this.offset) || other.offset == _this.offset)&&(identical(other.total, _this.total) || other.total == _this.total)&&const DeepCollectionEquality().equals(other.tracks, _this.tracks)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as LibraryTrackListResponse;
  return Object.hash(runtimeType,_this.limit,_this.offset,_this.total,const DeepCollectionEquality().hash(_this.tracks),const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as LibraryTrackListResponse;
  return 'LibraryTrackListResponse(limit: ${_this.limit}, offset: ${_this.offset}, total: ${_this.total}, tracks: ${_this.tracks}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $LibraryTrackListResponseCopyWith<$Res>  {
  factory $LibraryTrackListResponseCopyWith(LibraryTrackListResponse value, $Res Function(LibraryTrackListResponse) _then) = _$LibraryTrackListResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true, fromJson: LibraryTrackListResponse._read_limit, toJson: LibraryTrackListResponse._write_limit) int limit,@JsonKey(required: true, disallowNullValue: true, fromJson: LibraryTrackListResponse._read_offset, toJson: LibraryTrackListResponse._write_offset) int offset,@JsonKey(required: true, disallowNullValue: true, fromJson: LibraryTrackListResponse._read_total, toJson: LibraryTrackListResponse._write_total) int total,@JsonKey(required: true, disallowNullValue: true) List<LibraryTrack> tracks,@JsonKey(readValue: LibraryTrackListResponse._extras, fromJson: LibraryTrackListResponse._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$LibraryTrackListResponseCopyWithImpl<$Res>
    implements $LibraryTrackListResponseCopyWith<$Res> {
  _$LibraryTrackListResponseCopyWithImpl(this._self, this._then);

  final LibraryTrackListResponse _self;
  final $Res Function(LibraryTrackListResponse) _then;

/// Create a copy of LibraryTrackListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? limit = null,Object? offset = null,Object? total = null,Object? tracks = null,Object? additionalProperties = null,}) {
  return _then(LibraryTrackListResponse(
limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<LibraryTrack>,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [LibraryTrackListResponse].
extension LibraryTrackListResponsePatterns on LibraryTrackListResponse {
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
