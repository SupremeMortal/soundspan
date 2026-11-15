// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'similar_tracks_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SimilarTracksResponse {


/// Create a copy of SimilarTracksResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimilarTracksResponseCopyWith<SimilarTracksResponse> get copyWith => _$SimilarTracksResponseCopyWithImpl<SimilarTracksResponse>(this as SimilarTracksResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SimilarTracksResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimilarTracksResponse&&(identical(other.sourceFeatures, _this.sourceFeatures) || other.sourceFeatures == _this.sourceFeatures)&&(identical(other.sourceTrackId, _this.sourceTrackId) || other.sourceTrackId == _this.sourceTrackId)&&const DeepCollectionEquality().equals(other.tracks, _this.tracks)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as SimilarTracksResponse;
  return Object.hash(runtimeType,_this.sourceFeatures,_this.sourceTrackId,const DeepCollectionEquality().hash(_this.tracks),const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as SimilarTracksResponse;
  return 'SimilarTracksResponse(sourceFeatures: ${_this.sourceFeatures}, sourceTrackId: ${_this.sourceTrackId}, tracks: ${_this.tracks}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $SimilarTracksResponseCopyWith<$Res>  {
  factory $SimilarTracksResponseCopyWith(SimilarTracksResponse value, $Res Function(SimilarTracksResponse) _then) = _$SimilarTracksResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, fromJson: SimilarTracksResponse._read_sourceFeatures, toJson: SimilarTracksResponse._write_sourceFeatures) NullableVibeAudioFeatures? sourceFeatures,@JsonKey(required: true, disallowNullValue: true) String sourceTrackId,@JsonKey(required: true, disallowNullValue: true) List<SimilarTrack> tracks,@JsonKey(readValue: SimilarTracksResponse._extras, fromJson: SimilarTracksResponse._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$VibeAudioFeaturesCopyWith<$Res>? get sourceFeatures;

}
/// @nodoc
class _$SimilarTracksResponseCopyWithImpl<$Res>
    implements $SimilarTracksResponseCopyWith<$Res> {
  _$SimilarTracksResponseCopyWithImpl(this._self, this._then);

  final SimilarTracksResponse _self;
  final $Res Function(SimilarTracksResponse) _then;

/// Create a copy of SimilarTracksResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sourceFeatures = freezed,Object? sourceTrackId = null,Object? tracks = null,Object? additionalProperties = null,}) {
  return _then(SimilarTracksResponse(
sourceFeatures: freezed == sourceFeatures ? _self.sourceFeatures : sourceFeatures // ignore: cast_nullable_to_non_nullable
as NullableVibeAudioFeatures?,sourceTrackId: null == sourceTrackId ? _self.sourceTrackId : sourceTrackId // ignore: cast_nullable_to_non_nullable
as String,tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<SimilarTrack>,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of SimilarTracksResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VibeAudioFeaturesCopyWith<$Res>? get sourceFeatures {
    if (_self.sourceFeatures == null) {
    return null;
  }

  return $VibeAudioFeaturesCopyWith<$Res>(_self.sourceFeatures!, (value) {
    return _then(_self.copyWith(sourceFeatures: value));
  });
}
}


/// Adds pattern-matching-related methods to [SimilarTracksResponse].
extension SimilarTracksResponsePatterns on SimilarTracksResponse {
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
