// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_listen_group_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreateListenGroupRequest {


/// Create a copy of CreateListenGroupRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateListenGroupRequestCopyWith<CreateListenGroupRequest> get copyWith => _$CreateListenGroupRequestCopyWithImpl<CreateListenGroupRequest>(this as CreateListenGroupRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CreateListenGroupRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateListenGroupRequest&&(identical(other.currentTimeMs, _this.currentTimeMs) || other.currentTimeMs == _this.currentTimeMs)&&(identical(other.currentTrackId, _this.currentTrackId) || other.currentTrackId == _this.currentTrackId)&&(identical(other.isPlaying, _this.isPlaying) || other.isPlaying == _this.isPlaying)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.queueTrackIds, _this.queueTrackIds)&&const DeepCollectionEquality().equals(other.queueTracks, _this.queueTracks)&&(identical(other.visibility, _this.visibility) || other.visibility == _this.visibility)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as CreateListenGroupRequest;
  return Object.hash(runtimeType,_this.currentTimeMs,_this.currentTrackId,_this.isPlaying,_this.name,const DeepCollectionEquality().hash(_this.queueTrackIds),const DeepCollectionEquality().hash(_this.queueTracks),_this.visibility,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as CreateListenGroupRequest;
  return 'CreateListenGroupRequest(currentTimeMs: ${_this.currentTimeMs}, currentTrackId: ${_this.currentTrackId}, isPlaying: ${_this.isPlaying}, name: ${_this.name}, queueTrackIds: ${_this.queueTrackIds}, queueTracks: ${_this.queueTracks}, visibility: ${_this.visibility}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $CreateListenGroupRequestCopyWith<$Res>  {
  factory $CreateListenGroupRequestCopyWith(CreateListenGroupRequest value, $Res Function(CreateListenGroupRequest) _then) = _$CreateListenGroupRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(disallowNullValue: true, includeIfNull: false) num? currentTimeMs,@JsonKey(disallowNullValue: true, includeIfNull: false) String? currentTrackId,@JsonKey(disallowNullValue: true, includeIfNull: false) bool? isPlaying,@JsonKey(disallowNullValue: true, includeIfNull: false) String? name,@JsonKey(disallowNullValue: true, includeIfNull: false) List<String>? queueTrackIds,@JsonKey(disallowNullValue: true, includeIfNull: false) List<ListenQueueTrackInput>? queueTracks,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: CreateListenGroupRequest._read_visibility, toJson: CreateListenGroupRequest._write_visibility) CreateListenGroupRequestVisibility? visibility,@JsonKey(readValue: CreateListenGroupRequest._extras, fromJson: CreateListenGroupRequest._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$CreateListenGroupRequestCopyWithImpl<$Res>
    implements $CreateListenGroupRequestCopyWith<$Res> {
  _$CreateListenGroupRequestCopyWithImpl(this._self, this._then);

  final CreateListenGroupRequest _self;
  final $Res Function(CreateListenGroupRequest) _then;

/// Create a copy of CreateListenGroupRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentTimeMs = freezed,Object? currentTrackId = freezed,Object? isPlaying = freezed,Object? name = freezed,Object? queueTrackIds = freezed,Object? queueTracks = freezed,Object? visibility = freezed,Object? additionalProperties = null,}) {
  return _then(CreateListenGroupRequest(
currentTimeMs: freezed == currentTimeMs ? _self.currentTimeMs : currentTimeMs // ignore: cast_nullable_to_non_nullable
as num?,currentTrackId: freezed == currentTrackId ? _self.currentTrackId : currentTrackId // ignore: cast_nullable_to_non_nullable
as String?,isPlaying: freezed == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,queueTrackIds: freezed == queueTrackIds ? _self.queueTrackIds : queueTrackIds // ignore: cast_nullable_to_non_nullable
as List<String>?,queueTracks: freezed == queueTracks ? _self.queueTracks : queueTracks // ignore: cast_nullable_to_non_nullable
as List<ListenQueueTrackInput>?,visibility: freezed == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as CreateListenGroupRequestVisibility?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateListenGroupRequest].
extension CreateListenGroupRequestPatterns on CreateListenGroupRequest {
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
