// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'listen_group_playback.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ListenGroupPlayback {


/// Create a copy of ListenGroupPlayback
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListenGroupPlaybackCopyWith<ListenGroupPlayback> get copyWith => _$ListenGroupPlaybackCopyWithImpl<ListenGroupPlayback>(this as ListenGroupPlayback, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ListenGroupPlayback;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListenGroupPlayback&&(identical(other.currentIndex, _this.currentIndex) || other.currentIndex == _this.currentIndex)&&(identical(other.isPlaying, _this.isPlaying) || other.isPlaying == _this.isPlaying)&&(identical(other.positionMs, _this.positionMs) || other.positionMs == _this.positionMs)&&const DeepCollectionEquality().equals(other.queue, _this.queue)&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime)&&(identical(other.stateVersion, _this.stateVersion) || other.stateVersion == _this.stateVersion)&&(identical(other.trackId, _this.trackId) || other.trackId == _this.trackId)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as ListenGroupPlayback;
  return Object.hash(runtimeType,_this.currentIndex,_this.isPlaying,_this.positionMs,const DeepCollectionEquality().hash(_this.queue),_this.serverTime,_this.stateVersion,_this.trackId,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as ListenGroupPlayback;
  return 'ListenGroupPlayback(currentIndex: ${_this.currentIndex}, isPlaying: ${_this.isPlaying}, positionMs: ${_this.positionMs}, queue: ${_this.queue}, serverTime: ${_this.serverTime}, stateVersion: ${_this.stateVersion}, trackId: ${_this.trackId}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $ListenGroupPlaybackCopyWith<$Res>  {
  factory $ListenGroupPlaybackCopyWith(ListenGroupPlayback value, $Res Function(ListenGroupPlayback) _then) = _$ListenGroupPlaybackCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true, fromJson: ListenGroupPlayback._read_currentIndex, toJson: ListenGroupPlayback._write_currentIndex) int currentIndex,@JsonKey(required: true, disallowNullValue: true) bool isPlaying,@JsonKey(required: true, disallowNullValue: true) num positionMs,@JsonKey(required: true, disallowNullValue: true) List<ListenQueueItem> queue,@JsonKey(required: true, disallowNullValue: true, fromJson: ListenGroupPlayback._read_serverTime, toJson: ListenGroupPlayback._write_serverTime) int serverTime,@JsonKey(required: true, disallowNullValue: true, fromJson: ListenGroupPlayback._read_stateVersion, toJson: ListenGroupPlayback._write_stateVersion) int stateVersion,@JsonKey(required: true) String? trackId,@JsonKey(readValue: ListenGroupPlayback._extras, fromJson: ListenGroupPlayback._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$ListenGroupPlaybackCopyWithImpl<$Res>
    implements $ListenGroupPlaybackCopyWith<$Res> {
  _$ListenGroupPlaybackCopyWithImpl(this._self, this._then);

  final ListenGroupPlayback _self;
  final $Res Function(ListenGroupPlayback) _then;

/// Create a copy of ListenGroupPlayback
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentIndex = null,Object? isPlaying = null,Object? positionMs = null,Object? queue = null,Object? serverTime = null,Object? stateVersion = null,Object? trackId = freezed,Object? additionalProperties = null,}) {
  return _then(ListenGroupPlayback(
currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,positionMs: null == positionMs ? _self.positionMs : positionMs // ignore: cast_nullable_to_non_nullable
as num,queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as List<ListenQueueItem>,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as int,stateVersion: null == stateVersion ? _self.stateVersion : stateVersion // ignore: cast_nullable_to_non_nullable
as int,trackId: freezed == trackId ? _self.trackId : trackId // ignore: cast_nullable_to_non_nullable
as String?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [ListenGroupPlayback].
extension ListenGroupPlaybackPatterns on ListenGroupPlayback {
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
