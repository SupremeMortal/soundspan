// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist_list_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ArtistListResponse {


/// Create a copy of ArtistListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistListResponseCopyWith<ArtistListResponse> get copyWith => _$ArtistListResponseCopyWithImpl<ArtistListResponse>(this as ArtistListResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ArtistListResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistListResponse&&const DeepCollectionEquality().equals(other.artists, _this.artists)&&(identical(other.limit, _this.limit) || other.limit == _this.limit)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor)&&(identical(other.offset, _this.offset) || other.offset == _this.offset)&&(identical(other.total, _this.total) || other.total == _this.total)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as ArtistListResponse;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.artists),_this.limit,_this.nextCursor,_this.offset,_this.total,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as ArtistListResponse;
  return 'ArtistListResponse(artists: ${_this.artists}, limit: ${_this.limit}, nextCursor: ${_this.nextCursor}, offset: ${_this.offset}, total: ${_this.total}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $ArtistListResponseCopyWith<$Res>  {
  factory $ArtistListResponseCopyWith(ArtistListResponse value, $Res Function(ArtistListResponse) _then) = _$ArtistListResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) List<ArtistSummary> artists,@JsonKey(required: true, disallowNullValue: true, fromJson: ArtistListResponse._read_limit, toJson: ArtistListResponse._write_limit) int limit,@JsonKey(required: true) String? nextCursor,@JsonKey(required: true, disallowNullValue: true, fromJson: ArtistListResponse._read_offset, toJson: ArtistListResponse._write_offset) int offset,@JsonKey(required: true, disallowNullValue: true, fromJson: ArtistListResponse._read_total, toJson: ArtistListResponse._write_total) int total,@JsonKey(readValue: ArtistListResponse._extras, fromJson: ArtistListResponse._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$ArtistListResponseCopyWithImpl<$Res>
    implements $ArtistListResponseCopyWith<$Res> {
  _$ArtistListResponseCopyWithImpl(this._self, this._then);

  final ArtistListResponse _self;
  final $Res Function(ArtistListResponse) _then;

/// Create a copy of ArtistListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? artists = null,Object? limit = null,Object? nextCursor = freezed,Object? offset = null,Object? total = null,Object? additionalProperties = null,}) {
  return _then(ArtistListResponse(
artists: null == artists ? _self.artists : artists // ignore: cast_nullable_to_non_nullable
as List<ArtistSummary>,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistListResponse].
extension ArtistListResponsePatterns on ArtistListResponse {
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
