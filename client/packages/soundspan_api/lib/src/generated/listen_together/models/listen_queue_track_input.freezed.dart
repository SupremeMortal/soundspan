// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'listen_queue_track_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ListenQueueTrackInput {


/// Create a copy of ListenQueueTrackInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListenQueueTrackInputCopyWith<ListenQueueTrackInput> get copyWith => _$ListenQueueTrackInputCopyWithImpl<ListenQueueTrackInput>(this as ListenQueueTrackInput, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ListenQueueTrackInput;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListenQueueTrackInput&&(identical(other.metadata, _this.metadata) || other.metadata == _this.metadata)&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as ListenQueueTrackInput;
  return Object.hash(runtimeType,_this.metadata,_this.playbackId,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as ListenQueueTrackInput;
  return 'ListenQueueTrackInput(metadata: ${_this.metadata}, playbackId: ${_this.playbackId}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $ListenQueueTrackInputCopyWith<$Res>  {
  factory $ListenQueueTrackInputCopyWith(ListenQueueTrackInput value, $Res Function(ListenQueueTrackInput) _then) = _$ListenQueueTrackInputCopyWithImpl;
@useResult
$Res call({
@JsonKey(disallowNullValue: true, includeIfNull: false) PlaybackMetadata? metadata,@JsonKey(required: true, disallowNullValue: true) String playbackId,@JsonKey(readValue: ListenQueueTrackInput._extras, fromJson: ListenQueueTrackInput._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$PlaybackMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class _$ListenQueueTrackInputCopyWithImpl<$Res>
    implements $ListenQueueTrackInputCopyWith<$Res> {
  _$ListenQueueTrackInputCopyWithImpl(this._self, this._then);

  final ListenQueueTrackInput _self;
  final $Res Function(ListenQueueTrackInput) _then;

/// Create a copy of ListenQueueTrackInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? metadata = freezed,Object? playbackId = null,Object? additionalProperties = null,}) {
  return _then(ListenQueueTrackInput(
metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as PlaybackMetadata?,playbackId: null == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of ListenQueueTrackInput
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


/// Adds pattern-matching-related methods to [ListenQueueTrackInput].
extension ListenQueueTrackInputPatterns on ListenQueueTrackInput {
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
