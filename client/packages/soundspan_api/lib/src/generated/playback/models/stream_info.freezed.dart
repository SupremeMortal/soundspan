// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stream_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StreamInfo {


/// Create a copy of StreamInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamInfoCopyWith<StreamInfo> get copyWith => _$StreamInfoCopyWithImpl<StreamInfo>(this as StreamInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as StreamInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamInfo&&(identical(other.bitDepth, _this.bitDepth) || other.bitDepth == _this.bitDepth)&&(identical(other.bitrate, _this.bitrate) || other.bitrate == _this.bitrate)&&(identical(other.codec, _this.codec) || other.codec == _this.codec)&&(identical(other.contentLength, _this.contentLength) || other.contentLength == _this.contentLength)&&(identical(other.contentType, _this.contentType) || other.contentType == _this.contentType)&&(identical(other.durationMs, _this.durationMs) || other.durationMs == _this.durationMs)&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&(identical(other.quality, _this.quality) || other.quality == _this.quality)&&(identical(other.sampleRate, _this.sampleRate) || other.sampleRate == _this.sampleRate)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as StreamInfo;
  return Object.hash(runtimeType,_this.bitDepth,_this.bitrate,_this.codec,_this.contentLength,_this.contentType,_this.durationMs,_this.playbackId,_this.quality,_this.sampleRate,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as StreamInfo;
  return 'StreamInfo(bitDepth: ${_this.bitDepth}, bitrate: ${_this.bitrate}, codec: ${_this.codec}, contentLength: ${_this.contentLength}, contentType: ${_this.contentType}, durationMs: ${_this.durationMs}, playbackId: ${_this.playbackId}, quality: ${_this.quality}, sampleRate: ${_this.sampleRate}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $StreamInfoCopyWith<$Res>  {
  factory $StreamInfoCopyWith(StreamInfo value, $Res Function(StreamInfo) _then) = _$StreamInfoCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true) num? bitDepth,@JsonKey(required: true) num? bitrate,@JsonKey(required: true) String? codec,@JsonKey(required: true, fromJson: StreamInfo._read_contentLength, toJson: StreamInfo._write_contentLength) int? contentLength,@JsonKey(required: true) String? contentType,@JsonKey(required: true, fromJson: StreamInfo._read_durationMs, toJson: StreamInfo._write_durationMs) int? durationMs,@JsonKey(required: true, disallowNullValue: true) String playbackId,@JsonKey(required: true, disallowNullValue: true, fromJson: StreamInfo._read_quality, toJson: StreamInfo._write_quality) PlaybackQuality quality,@JsonKey(required: true) num? sampleRate,@JsonKey(readValue: StreamInfo._extras, fromJson: StreamInfo._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$StreamInfoCopyWithImpl<$Res>
    implements $StreamInfoCopyWith<$Res> {
  _$StreamInfoCopyWithImpl(this._self, this._then);

  final StreamInfo _self;
  final $Res Function(StreamInfo) _then;

/// Create a copy of StreamInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bitDepth = freezed,Object? bitrate = freezed,Object? codec = freezed,Object? contentLength = freezed,Object? contentType = freezed,Object? durationMs = freezed,Object? playbackId = null,Object? quality = null,Object? sampleRate = freezed,Object? additionalProperties = null,}) {
  return _then(StreamInfo(
bitDepth: freezed == bitDepth ? _self.bitDepth : bitDepth // ignore: cast_nullable_to_non_nullable
as num?,bitrate: freezed == bitrate ? _self.bitrate : bitrate // ignore: cast_nullable_to_non_nullable
as num?,codec: freezed == codec ? _self.codec : codec // ignore: cast_nullable_to_non_nullable
as String?,contentLength: freezed == contentLength ? _self.contentLength : contentLength // ignore: cast_nullable_to_non_nullable
as int?,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,playbackId: null == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as String,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as PlaybackQuality,sampleRate: freezed == sampleRate ? _self.sampleRate : sampleRate // ignore: cast_nullable_to_non_nullable
as num?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [StreamInfo].
extension StreamInfoPatterns on StreamInfo {
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
