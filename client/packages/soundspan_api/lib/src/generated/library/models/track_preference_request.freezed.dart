// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'track_preference_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrackPreferenceRequest {


/// Create a copy of TrackPreferenceRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackPreferenceRequestCopyWith<TrackPreferenceRequest> get copyWith => _$TrackPreferenceRequestCopyWithImpl<TrackPreferenceRequest>(this as TrackPreferenceRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TrackPreferenceRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackPreferenceRequest&&(identical(other.metadata, _this.metadata) || other.metadata == _this.metadata)&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&(identical(other.signal, _this.signal) || other.signal == _this.signal)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as TrackPreferenceRequest;
  return Object.hash(runtimeType,_this.metadata,_this.playbackId,_this.signal,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as TrackPreferenceRequest;
  return 'TrackPreferenceRequest(metadata: ${_this.metadata}, playbackId: ${_this.playbackId}, signal: ${_this.signal}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $TrackPreferenceRequestCopyWith<$Res>  {
  factory $TrackPreferenceRequestCopyWith(TrackPreferenceRequest value, $Res Function(TrackPreferenceRequest) _then) = _$TrackPreferenceRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(disallowNullValue: true, includeIfNull: false) PlaybackMetadata? metadata,@JsonKey(required: true, disallowNullValue: true) String playbackId,@JsonKey(required: true, disallowNullValue: true, fromJson: TrackPreferenceRequest._read_signal, toJson: TrackPreferenceRequest._write_signal) PreferenceSignal signal,@JsonKey(readValue: TrackPreferenceRequest._extras, fromJson: TrackPreferenceRequest._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$PlaybackMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class _$TrackPreferenceRequestCopyWithImpl<$Res>
    implements $TrackPreferenceRequestCopyWith<$Res> {
  _$TrackPreferenceRequestCopyWithImpl(this._self, this._then);

  final TrackPreferenceRequest _self;
  final $Res Function(TrackPreferenceRequest) _then;

/// Create a copy of TrackPreferenceRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? metadata = freezed,Object? playbackId = null,Object? signal = null,Object? additionalProperties = null,}) {
  return _then(TrackPreferenceRequest(
metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as PlaybackMetadata?,playbackId: null == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as String,signal: null == signal ? _self.signal : signal // ignore: cast_nullable_to_non_nullable
as PreferenceSignal,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of TrackPreferenceRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaybackMetadataCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $PlaybackMetadataCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [TrackPreferenceRequest].
extension TrackPreferenceRequestPatterns on TrackPreferenceRequest {
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
