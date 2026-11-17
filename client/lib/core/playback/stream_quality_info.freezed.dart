// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stream_quality_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StreamQualityInfo {

/// The quality the server chose: `original`, `high`, `medium`, `low`,
/// or a value a newer server added. Null only for a downloaded file
/// stored without a quality (the server default).
 String? get quality;/// The content type the server reports, a MIME type or a format name
/// such as `FLAC`, if known.
 String? get contentType;/// The codec, if known.
 String? get codec;/// The bit rate in kbit/s, if known.
 num? get bitrate;/// The sample rate in Hz, if known.
 num? get sampleRate;/// The bit depth, if known.
 num? get bitDepth;/// The duration in milliseconds, if known.
 int? get durationMs;/// The size of the stream in bytes, if known.
 int? get contentLength;/// Whether the item plays from a downloaded file on this device.
 bool get downloaded;
/// Create a copy of StreamQualityInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamQualityInfoCopyWith<StreamQualityInfo> get copyWith => _$StreamQualityInfoCopyWithImpl<StreamQualityInfo>(this as StreamQualityInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as StreamQualityInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamQualityInfo&&(identical(other.quality, _this.quality) || other.quality == _this.quality)&&(identical(other.contentType, _this.contentType) || other.contentType == _this.contentType)&&(identical(other.codec, _this.codec) || other.codec == _this.codec)&&(identical(other.bitrate, _this.bitrate) || other.bitrate == _this.bitrate)&&(identical(other.sampleRate, _this.sampleRate) || other.sampleRate == _this.sampleRate)&&(identical(other.bitDepth, _this.bitDepth) || other.bitDepth == _this.bitDepth)&&(identical(other.durationMs, _this.durationMs) || other.durationMs == _this.durationMs)&&(identical(other.contentLength, _this.contentLength) || other.contentLength == _this.contentLength)&&(identical(other.downloaded, _this.downloaded) || other.downloaded == _this.downloaded));
}


@override
int get hashCode {
  final _this = this as StreamQualityInfo;
  return Object.hash(runtimeType,_this.quality,_this.contentType,_this.codec,_this.bitrate,_this.sampleRate,_this.bitDepth,_this.durationMs,_this.contentLength,_this.downloaded);
}

@override
String toString() {
  final _this = this as StreamQualityInfo;
  return 'StreamQualityInfo(quality: ${_this.quality}, contentType: ${_this.contentType}, codec: ${_this.codec}, bitrate: ${_this.bitrate}, sampleRate: ${_this.sampleRate}, bitDepth: ${_this.bitDepth}, durationMs: ${_this.durationMs}, contentLength: ${_this.contentLength}, downloaded: ${_this.downloaded})';
}


}

/// @nodoc
abstract mixin class $StreamQualityInfoCopyWith<$Res>  {
  factory $StreamQualityInfoCopyWith(StreamQualityInfo value, $Res Function(StreamQualityInfo) _then) = _$StreamQualityInfoCopyWithImpl;
@useResult
$Res call({
 String? quality, String? contentType, String? codec, num? bitrate, num? sampleRate, num? bitDepth, int? durationMs, int? contentLength, bool downloaded
});




}
/// @nodoc
class _$StreamQualityInfoCopyWithImpl<$Res>
    implements $StreamQualityInfoCopyWith<$Res> {
  _$StreamQualityInfoCopyWithImpl(this._self, this._then);

  final StreamQualityInfo _self;
  final $Res Function(StreamQualityInfo) _then;

/// Create a copy of StreamQualityInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quality = freezed,Object? contentType = freezed,Object? codec = freezed,Object? bitrate = freezed,Object? sampleRate = freezed,Object? bitDepth = freezed,Object? durationMs = freezed,Object? contentLength = freezed,Object? downloaded = null,}) {
  return _then(StreamQualityInfo(
quality: freezed == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as String?,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,codec: freezed == codec ? _self.codec : codec // ignore: cast_nullable_to_non_nullable
as String?,bitrate: freezed == bitrate ? _self.bitrate : bitrate // ignore: cast_nullable_to_non_nullable
as num?,sampleRate: freezed == sampleRate ? _self.sampleRate : sampleRate // ignore: cast_nullable_to_non_nullable
as num?,bitDepth: freezed == bitDepth ? _self.bitDepth : bitDepth // ignore: cast_nullable_to_non_nullable
as num?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,contentLength: freezed == contentLength ? _self.contentLength : contentLength // ignore: cast_nullable_to_non_nullable
as int?,downloaded: null == downloaded ? _self.downloaded : downloaded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StreamQualityInfo].
extension StreamQualityInfoPatterns on StreamQualityInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreamQualityInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreamQualityInfo() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreamQualityInfo value)  $default,){
final _that = this;
switch (_that) {
case _StreamQualityInfo():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreamQualityInfo value)?  $default,){
final _that = this;
switch (_that) {
case _StreamQualityInfo() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? quality,  String? contentType,  String? codec,  num? bitrate,  num? sampleRate,  num? bitDepth,  int? durationMs,  int? contentLength,  bool downloaded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreamQualityInfo() when $default != null:
return $default(_that.quality,_that.contentType,_that.codec,_that.bitrate,_that.sampleRate,_that.bitDepth,_that.durationMs,_that.contentLength,_that.downloaded);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? quality,  String? contentType,  String? codec,  num? bitrate,  num? sampleRate,  num? bitDepth,  int? durationMs,  int? contentLength,  bool downloaded)  $default,) {final _that = this;
switch (_that) {
case _StreamQualityInfo():
return $default(_that.quality,_that.contentType,_that.codec,_that.bitrate,_that.sampleRate,_that.bitDepth,_that.durationMs,_that.contentLength,_that.downloaded);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? quality,  String? contentType,  String? codec,  num? bitrate,  num? sampleRate,  num? bitDepth,  int? durationMs,  int? contentLength,  bool downloaded)?  $default,) {final _that = this;
switch (_that) {
case _StreamQualityInfo() when $default != null:
return $default(_that.quality,_that.contentType,_that.codec,_that.bitrate,_that.sampleRate,_that.bitDepth,_that.durationMs,_that.contentLength,_that.downloaded);case _:
  return null;

}
}

}

/// @nodoc


class _StreamQualityInfo implements StreamQualityInfo {
  const _StreamQualityInfo({required this.quality, this.contentType, this.codec, this.bitrate, this.sampleRate, this.bitDepth, this.durationMs, this.contentLength, this.downloaded = false});
  

/// The quality the server chose: `original`, `high`, `medium`, `low`,
/// or a value a newer server added. Null only for a downloaded file
/// stored without a quality (the server default).
@override final  String? quality;
/// The content type the server reports, a MIME type or a format name
/// such as `FLAC`, if known.
@override final  String? contentType;
/// The codec, if known.
@override final  String? codec;
/// The bit rate in kbit/s, if known.
@override final  num? bitrate;
/// The sample rate in Hz, if known.
@override final  num? sampleRate;
/// The bit depth, if known.
@override final  num? bitDepth;
/// The duration in milliseconds, if known.
@override final  int? durationMs;
/// The size of the stream in bytes, if known.
@override final  int? contentLength;
/// Whether the item plays from a downloaded file on this device.
@override@JsonKey() final  bool downloaded;

/// Create a copy of StreamQualityInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreamQualityInfoCopyWith<_StreamQualityInfo> get copyWith => __$StreamQualityInfoCopyWithImpl<_StreamQualityInfo>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreamQualityInfo&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.codec, codec) || other.codec == codec)&&(identical(other.bitrate, bitrate) || other.bitrate == bitrate)&&(identical(other.sampleRate, sampleRate) || other.sampleRate == sampleRate)&&(identical(other.bitDepth, bitDepth) || other.bitDepth == bitDepth)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.contentLength, contentLength) || other.contentLength == contentLength)&&(identical(other.downloaded, downloaded) || other.downloaded == downloaded));
}


@override
int get hashCode {
    return Object.hash(runtimeType,quality,contentType,codec,bitrate,sampleRate,bitDepth,durationMs,contentLength,downloaded);
}

@override
String toString() {
    return 'StreamQualityInfo(quality: $quality, contentType: $contentType, codec: $codec, bitrate: $bitrate, sampleRate: $sampleRate, bitDepth: $bitDepth, durationMs: $durationMs, contentLength: $contentLength, downloaded: $downloaded)';
}


}

/// @nodoc
abstract mixin class _$StreamQualityInfoCopyWith<$Res> implements $StreamQualityInfoCopyWith<$Res> {
  factory _$StreamQualityInfoCopyWith(_StreamQualityInfo value, $Res Function(_StreamQualityInfo) _then) = __$StreamQualityInfoCopyWithImpl;
@override @useResult
$Res call({
 String? quality, String? contentType, String? codec, num? bitrate, num? sampleRate, num? bitDepth, int? durationMs, int? contentLength, bool downloaded
});




}
/// @nodoc
class __$StreamQualityInfoCopyWithImpl<$Res>
    implements _$StreamQualityInfoCopyWith<$Res> {
  __$StreamQualityInfoCopyWithImpl(this._self, this._then);

  final _StreamQualityInfo _self;
  final $Res Function(_StreamQualityInfo) _then;

/// Create a copy of StreamQualityInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quality = freezed,Object? contentType = freezed,Object? codec = freezed,Object? bitrate = freezed,Object? sampleRate = freezed,Object? bitDepth = freezed,Object? durationMs = freezed,Object? contentLength = freezed,Object? downloaded = null,}) {
  return _then(_StreamQualityInfo(
quality: freezed == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as String?,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,codec: freezed == codec ? _self.codec : codec // ignore: cast_nullable_to_non_nullable
as String?,bitrate: freezed == bitrate ? _self.bitrate : bitrate // ignore: cast_nullable_to_non_nullable
as num?,sampleRate: freezed == sampleRate ? _self.sampleRate : sampleRate // ignore: cast_nullable_to_non_nullable
as num?,bitDepth: freezed == bitDepth ? _self.bitDepth : bitDepth // ignore: cast_nullable_to_non_nullable
as num?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,contentLength: freezed == contentLength ? _self.contentLength : contentLength // ignore: cast_nullable_to_non_nullable
as int?,downloaded: null == downloaded ? _self.downloaded : downloaded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
