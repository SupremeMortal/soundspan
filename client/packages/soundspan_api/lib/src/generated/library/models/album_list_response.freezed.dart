// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'album_list_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AlbumListResponse {


/// Create a copy of AlbumListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlbumListResponseCopyWith<AlbumListResponse> get copyWith => _$AlbumListResponseCopyWithImpl<AlbumListResponse>(this as AlbumListResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AlbumListResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlbumListResponse&&const DeepCollectionEquality().equals(other.albums, _this.albums)&&(identical(other.limit, _this.limit) || other.limit == _this.limit)&&(identical(other.offset, _this.offset) || other.offset == _this.offset)&&(identical(other.total, _this.total) || other.total == _this.total)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as AlbumListResponse;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.albums),_this.limit,_this.offset,_this.total,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as AlbumListResponse;
  return 'AlbumListResponse(albums: ${_this.albums}, limit: ${_this.limit}, offset: ${_this.offset}, total: ${_this.total}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $AlbumListResponseCopyWith<$Res>  {
  factory $AlbumListResponseCopyWith(AlbumListResponse value, $Res Function(AlbumListResponse) _then) = _$AlbumListResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) List<AlbumSummary> albums,@JsonKey(required: true, disallowNullValue: true, fromJson: AlbumListResponse._read_limit, toJson: AlbumListResponse._write_limit) int limit,@JsonKey(required: true, disallowNullValue: true, fromJson: AlbumListResponse._read_offset, toJson: AlbumListResponse._write_offset) int offset,@JsonKey(required: true, disallowNullValue: true, fromJson: AlbumListResponse._read_total, toJson: AlbumListResponse._write_total) int total,@JsonKey(readValue: AlbumListResponse._extras, fromJson: AlbumListResponse._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$AlbumListResponseCopyWithImpl<$Res>
    implements $AlbumListResponseCopyWith<$Res> {
  _$AlbumListResponseCopyWithImpl(this._self, this._then);

  final AlbumListResponse _self;
  final $Res Function(AlbumListResponse) _then;

/// Create a copy of AlbumListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? albums = null,Object? limit = null,Object? offset = null,Object? total = null,Object? additionalProperties = null,}) {
  return _then(AlbumListResponse(
albums: null == albums ? _self.albums : albums // ignore: cast_nullable_to_non_nullable
as List<AlbumSummary>,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [AlbumListResponse].
extension AlbumListResponsePatterns on AlbumListResponse {
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
