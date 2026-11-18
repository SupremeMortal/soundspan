// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vibe_search_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VibeSearchResponse {


/// Create a copy of VibeSearchResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VibeSearchResponseCopyWith<VibeSearchResponse> get copyWith => _$VibeSearchResponseCopyWithImpl<VibeSearchResponse>(this as VibeSearchResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as VibeSearchResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VibeSearchResponse&&(identical(other.minSimilarity, _this.minSimilarity) || other.minSimilarity == _this.minSimilarity)&&(identical(other.query, _this.query) || other.query == _this.query)&&(identical(other.totalAboveThreshold, _this.totalAboveThreshold) || other.totalAboveThreshold == _this.totalAboveThreshold)&&const DeepCollectionEquality().equals(other.tracks, _this.tracks)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as VibeSearchResponse;
  return Object.hash(runtimeType,_this.minSimilarity,_this.query,_this.totalAboveThreshold,const DeepCollectionEquality().hash(_this.tracks),const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as VibeSearchResponse;
  return 'VibeSearchResponse(minSimilarity: ${_this.minSimilarity}, query: ${_this.query}, totalAboveThreshold: ${_this.totalAboveThreshold}, tracks: ${_this.tracks}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $VibeSearchResponseCopyWith<$Res>  {
  factory $VibeSearchResponseCopyWith(VibeSearchResponse value, $Res Function(VibeSearchResponse) _then) = _$VibeSearchResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) num minSimilarity,@JsonKey(required: true, disallowNullValue: true) String query,@JsonKey(required: true, disallowNullValue: true, fromJson: VibeSearchResponse._read_totalAboveThreshold, toJson: VibeSearchResponse._write_totalAboveThreshold) int totalAboveThreshold,@JsonKey(required: true, disallowNullValue: true) List<VibeSearchTrack> tracks,@JsonKey(readValue: VibeSearchResponse._extras, fromJson: VibeSearchResponse._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$VibeSearchResponseCopyWithImpl<$Res>
    implements $VibeSearchResponseCopyWith<$Res> {
  _$VibeSearchResponseCopyWithImpl(this._self, this._then);

  final VibeSearchResponse _self;
  final $Res Function(VibeSearchResponse) _then;

/// Create a copy of VibeSearchResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minSimilarity = null,Object? query = null,Object? totalAboveThreshold = null,Object? tracks = null,Object? additionalProperties = null,}) {
  return _then(VibeSearchResponse(
minSimilarity: null == minSimilarity ? _self.minSimilarity : minSimilarity // ignore: cast_nullable_to_non_nullable
as num,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,totalAboveThreshold: null == totalAboveThreshold ? _self.totalAboveThreshold : totalAboveThreshold // ignore: cast_nullable_to_non_nullable
as int,tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<VibeSearchTrack>,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [VibeSearchResponse].
extension VibeSearchResponsePatterns on VibeSearchResponse {
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
