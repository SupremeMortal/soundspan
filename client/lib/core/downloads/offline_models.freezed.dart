// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offline_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OfflineResolution {

/// The resolved items, in track order.
 List<OfflineItem> get items;/// The bytes the downloadable items are expected to take, if known.
 int? get estimatedTotalBytes;/// The user's server-side cache limit in bytes, if known.
 int? get cacheLimitBytes;/// The bytes the user's devices already hold, if known.
 int? get cacheUsedBytes;
/// Create a copy of OfflineResolution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfflineResolutionCopyWith<OfflineResolution> get copyWith => _$OfflineResolutionCopyWithImpl<OfflineResolution>(this as OfflineResolution, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OfflineResolution;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OfflineResolution&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.estimatedTotalBytes, _this.estimatedTotalBytes) || other.estimatedTotalBytes == _this.estimatedTotalBytes)&&(identical(other.cacheLimitBytes, _this.cacheLimitBytes) || other.cacheLimitBytes == _this.cacheLimitBytes)&&(identical(other.cacheUsedBytes, _this.cacheUsedBytes) || other.cacheUsedBytes == _this.cacheUsedBytes));
}


@override
int get hashCode {
  final _this = this as OfflineResolution;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.estimatedTotalBytes,_this.cacheLimitBytes,_this.cacheUsedBytes);
}

@override
String toString() {
  final _this = this as OfflineResolution;
  return 'OfflineResolution(items: ${_this.items}, estimatedTotalBytes: ${_this.estimatedTotalBytes}, cacheLimitBytes: ${_this.cacheLimitBytes}, cacheUsedBytes: ${_this.cacheUsedBytes})';
}


}

/// @nodoc
abstract mixin class $OfflineResolutionCopyWith<$Res>  {
  factory $OfflineResolutionCopyWith(OfflineResolution value, $Res Function(OfflineResolution) _then) = _$OfflineResolutionCopyWithImpl;
@useResult
$Res call({
 List<OfflineItem> items, int? estimatedTotalBytes, int? cacheLimitBytes, int? cacheUsedBytes
});




}
/// @nodoc
class _$OfflineResolutionCopyWithImpl<$Res>
    implements $OfflineResolutionCopyWith<$Res> {
  _$OfflineResolutionCopyWithImpl(this._self, this._then);

  final OfflineResolution _self;
  final $Res Function(OfflineResolution) _then;

/// Create a copy of OfflineResolution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? estimatedTotalBytes = freezed,Object? cacheLimitBytes = freezed,Object? cacheUsedBytes = freezed,}) {
  return _then(OfflineResolution(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<OfflineItem>,estimatedTotalBytes: freezed == estimatedTotalBytes ? _self.estimatedTotalBytes : estimatedTotalBytes // ignore: cast_nullable_to_non_nullable
as int?,cacheLimitBytes: freezed == cacheLimitBytes ? _self.cacheLimitBytes : cacheLimitBytes // ignore: cast_nullable_to_non_nullable
as int?,cacheUsedBytes: freezed == cacheUsedBytes ? _self.cacheUsedBytes : cacheUsedBytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [OfflineResolution].
extension OfflineResolutionPatterns on OfflineResolution {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OfflineResolution value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OfflineResolution() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OfflineResolution value)  $default,){
final _that = this;
switch (_that) {
case _OfflineResolution():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OfflineResolution value)?  $default,){
final _that = this;
switch (_that) {
case _OfflineResolution() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<OfflineItem> items,  int? estimatedTotalBytes,  int? cacheLimitBytes,  int? cacheUsedBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OfflineResolution() when $default != null:
return $default(_that.items,_that.estimatedTotalBytes,_that.cacheLimitBytes,_that.cacheUsedBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<OfflineItem> items,  int? estimatedTotalBytes,  int? cacheLimitBytes,  int? cacheUsedBytes)  $default,) {final _that = this;
switch (_that) {
case _OfflineResolution():
return $default(_that.items,_that.estimatedTotalBytes,_that.cacheLimitBytes,_that.cacheUsedBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<OfflineItem> items,  int? estimatedTotalBytes,  int? cacheLimitBytes,  int? cacheUsedBytes)?  $default,) {final _that = this;
switch (_that) {
case _OfflineResolution() when $default != null:
return $default(_that.items,_that.estimatedTotalBytes,_that.cacheLimitBytes,_that.cacheUsedBytes);case _:
  return null;

}
}

}

/// @nodoc


class _OfflineResolution implements OfflineResolution {
  const _OfflineResolution({required  List<OfflineItem> items, this.estimatedTotalBytes, this.cacheLimitBytes, this.cacheUsedBytes}): _items = items;
  

/// The resolved items, in track order.
 final  List<OfflineItem> _items;
/// The resolved items, in track order.
@override List<OfflineItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// The bytes the downloadable items are expected to take, if known.
@override final  int? estimatedTotalBytes;
/// The user's server-side cache limit in bytes, if known.
@override final  int? cacheLimitBytes;
/// The bytes the user's devices already hold, if known.
@override final  int? cacheUsedBytes;

/// Create a copy of OfflineResolution
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OfflineResolutionCopyWith<_OfflineResolution> get copyWith => __$OfflineResolutionCopyWithImpl<_OfflineResolution>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OfflineResolution&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.estimatedTotalBytes, estimatedTotalBytes) || other.estimatedTotalBytes == estimatedTotalBytes)&&(identical(other.cacheLimitBytes, cacheLimitBytes) || other.cacheLimitBytes == cacheLimitBytes)&&(identical(other.cacheUsedBytes, cacheUsedBytes) || other.cacheUsedBytes == cacheUsedBytes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),estimatedTotalBytes,cacheLimitBytes,cacheUsedBytes);
}

@override
String toString() {
    return 'OfflineResolution(items: $items, estimatedTotalBytes: $estimatedTotalBytes, cacheLimitBytes: $cacheLimitBytes, cacheUsedBytes: $cacheUsedBytes)';
}


}

/// @nodoc
abstract mixin class _$OfflineResolutionCopyWith<$Res> implements $OfflineResolutionCopyWith<$Res> {
  factory _$OfflineResolutionCopyWith(_OfflineResolution value, $Res Function(_OfflineResolution) _then) = __$OfflineResolutionCopyWithImpl;
@override @useResult
$Res call({
 List<OfflineItem> items, int? estimatedTotalBytes, int? cacheLimitBytes, int? cacheUsedBytes
});




}
/// @nodoc
class __$OfflineResolutionCopyWithImpl<$Res>
    implements _$OfflineResolutionCopyWith<$Res> {
  __$OfflineResolutionCopyWithImpl(this._self, this._then);

  final _OfflineResolution _self;
  final $Res Function(_OfflineResolution) _then;

/// Create a copy of OfflineResolution
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? estimatedTotalBytes = freezed,Object? cacheLimitBytes = freezed,Object? cacheUsedBytes = freezed,}) {
  return _then(_OfflineResolution(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<OfflineItem>,estimatedTotalBytes: freezed == estimatedTotalBytes ? _self.estimatedTotalBytes : estimatedTotalBytes // ignore: cast_nullable_to_non_nullable
as int?,cacheLimitBytes: freezed == cacheLimitBytes ? _self.cacheLimitBytes : cacheLimitBytes // ignore: cast_nullable_to_non_nullable
as int?,cacheUsedBytes: freezed == cacheUsedBytes ? _self.cacheUsedBytes : cacheUsedBytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$OfflineItem {

/// The track.
 PlaybackId get playbackId;/// Whether the device may download it.
 bool get downloadable;/// The server-relative URL of the file, kept verbatim; resolved with
/// `StreamUrls.resolve`.
 String? get downloadUrl;/// The bytes the server will send, if it can say.
 int? get expectedBytes;/// The quality the server will send: `original`, `high`, `medium`,
/// `low`, or a value a newer server added.
 String? get quality;/// The content type of the file, if known.
 String? get contentType;/// Why the item is not downloadable, when it is not.
 OfflineUnavailableReason? get reason;
/// Create a copy of OfflineItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfflineItemCopyWith<OfflineItem> get copyWith => _$OfflineItemCopyWithImpl<OfflineItem>(this as OfflineItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OfflineItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OfflineItem&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&(identical(other.downloadable, _this.downloadable) || other.downloadable == _this.downloadable)&&(identical(other.downloadUrl, _this.downloadUrl) || other.downloadUrl == _this.downloadUrl)&&(identical(other.expectedBytes, _this.expectedBytes) || other.expectedBytes == _this.expectedBytes)&&(identical(other.quality, _this.quality) || other.quality == _this.quality)&&(identical(other.contentType, _this.contentType) || other.contentType == _this.contentType)&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}


@override
int get hashCode {
  final _this = this as OfflineItem;
  return Object.hash(runtimeType,_this.playbackId,_this.downloadable,_this.downloadUrl,_this.expectedBytes,_this.quality,_this.contentType,_this.reason);
}

@override
String toString() {
  final _this = this as OfflineItem;
  return 'OfflineItem(playbackId: ${_this.playbackId}, downloadable: ${_this.downloadable}, downloadUrl: ${_this.downloadUrl}, expectedBytes: ${_this.expectedBytes}, quality: ${_this.quality}, contentType: ${_this.contentType}, reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $OfflineItemCopyWith<$Res>  {
  factory $OfflineItemCopyWith(OfflineItem value, $Res Function(OfflineItem) _then) = _$OfflineItemCopyWithImpl;
@useResult
$Res call({
 PlaybackId playbackId, bool downloadable, String? downloadUrl, int? expectedBytes, String? quality, String? contentType, OfflineUnavailableReason? reason
});




}
/// @nodoc
class _$OfflineItemCopyWithImpl<$Res>
    implements $OfflineItemCopyWith<$Res> {
  _$OfflineItemCopyWithImpl(this._self, this._then);

  final OfflineItem _self;
  final $Res Function(OfflineItem) _then;

/// Create a copy of OfflineItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playbackId = null,Object? downloadable = null,Object? downloadUrl = freezed,Object? expectedBytes = freezed,Object? quality = freezed,Object? contentType = freezed,Object? reason = freezed,}) {
  return _then(OfflineItem(
playbackId: null == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as PlaybackId,downloadable: null == downloadable ? _self.downloadable : downloadable // ignore: cast_nullable_to_non_nullable
as bool,downloadUrl: freezed == downloadUrl ? _self.downloadUrl : downloadUrl // ignore: cast_nullable_to_non_nullable
as String?,expectedBytes: freezed == expectedBytes ? _self.expectedBytes : expectedBytes // ignore: cast_nullable_to_non_nullable
as int?,quality: freezed == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as String?,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as OfflineUnavailableReason?,
  ));
}

}


/// Adds pattern-matching-related methods to [OfflineItem].
extension OfflineItemPatterns on OfflineItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OfflineItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OfflineItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OfflineItem value)  $default,){
final _that = this;
switch (_that) {
case _OfflineItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OfflineItem value)?  $default,){
final _that = this;
switch (_that) {
case _OfflineItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlaybackId playbackId,  bool downloadable,  String? downloadUrl,  int? expectedBytes,  String? quality,  String? contentType,  OfflineUnavailableReason? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OfflineItem() when $default != null:
return $default(_that.playbackId,_that.downloadable,_that.downloadUrl,_that.expectedBytes,_that.quality,_that.contentType,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlaybackId playbackId,  bool downloadable,  String? downloadUrl,  int? expectedBytes,  String? quality,  String? contentType,  OfflineUnavailableReason? reason)  $default,) {final _that = this;
switch (_that) {
case _OfflineItem():
return $default(_that.playbackId,_that.downloadable,_that.downloadUrl,_that.expectedBytes,_that.quality,_that.contentType,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlaybackId playbackId,  bool downloadable,  String? downloadUrl,  int? expectedBytes,  String? quality,  String? contentType,  OfflineUnavailableReason? reason)?  $default,) {final _that = this;
switch (_that) {
case _OfflineItem() when $default != null:
return $default(_that.playbackId,_that.downloadable,_that.downloadUrl,_that.expectedBytes,_that.quality,_that.contentType,_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class _OfflineItem implements OfflineItem {
  const _OfflineItem({required this.playbackId, required this.downloadable, this.downloadUrl, this.expectedBytes, this.quality, this.contentType, this.reason});
  

/// The track.
@override final  PlaybackId playbackId;
/// Whether the device may download it.
@override final  bool downloadable;
/// The server-relative URL of the file, kept verbatim; resolved with
/// `StreamUrls.resolve`.
@override final  String? downloadUrl;
/// The bytes the server will send, if it can say.
@override final  int? expectedBytes;
/// The quality the server will send: `original`, `high`, `medium`,
/// `low`, or a value a newer server added.
@override final  String? quality;
/// The content type of the file, if known.
@override final  String? contentType;
/// Why the item is not downloadable, when it is not.
@override final  OfflineUnavailableReason? reason;

/// Create a copy of OfflineItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OfflineItemCopyWith<_OfflineItem> get copyWith => __$OfflineItemCopyWithImpl<_OfflineItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OfflineItem&&(identical(other.playbackId, playbackId) || other.playbackId == playbackId)&&(identical(other.downloadable, downloadable) || other.downloadable == downloadable)&&(identical(other.downloadUrl, downloadUrl) || other.downloadUrl == downloadUrl)&&(identical(other.expectedBytes, expectedBytes) || other.expectedBytes == expectedBytes)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,playbackId,downloadable,downloadUrl,expectedBytes,quality,contentType,reason);
}

@override
String toString() {
    return 'OfflineItem(playbackId: $playbackId, downloadable: $downloadable, downloadUrl: $downloadUrl, expectedBytes: $expectedBytes, quality: $quality, contentType: $contentType, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$OfflineItemCopyWith<$Res> implements $OfflineItemCopyWith<$Res> {
  factory _$OfflineItemCopyWith(_OfflineItem value, $Res Function(_OfflineItem) _then) = __$OfflineItemCopyWithImpl;
@override @useResult
$Res call({
 PlaybackId playbackId, bool downloadable, String? downloadUrl, int? expectedBytes, String? quality, String? contentType, OfflineUnavailableReason? reason
});




}
/// @nodoc
class __$OfflineItemCopyWithImpl<$Res>
    implements _$OfflineItemCopyWith<$Res> {
  __$OfflineItemCopyWithImpl(this._self, this._then);

  final _OfflineItem _self;
  final $Res Function(_OfflineItem) _then;

/// Create a copy of OfflineItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playbackId = null,Object? downloadable = null,Object? downloadUrl = freezed,Object? expectedBytes = freezed,Object? quality = freezed,Object? contentType = freezed,Object? reason = freezed,}) {
  return _then(_OfflineItem(
playbackId: null == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as PlaybackId,downloadable: null == downloadable ? _self.downloadable : downloadable // ignore: cast_nullable_to_non_nullable
as bool,downloadUrl: freezed == downloadUrl ? _self.downloadUrl : downloadUrl // ignore: cast_nullable_to_non_nullable
as String?,expectedBytes: freezed == expectedBytes ? _self.expectedBytes : expectedBytes // ignore: cast_nullable_to_non_nullable
as int?,quality: freezed == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as String?,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as OfflineUnavailableReason?,
  ));
}


}

/// @nodoc
mixin _$ServerOfflineItem {

/// The track.
 PlaybackId get playbackId;/// Whether the device must delete it.
 bool get revoked;/// The recorded quality.
 String? get quality;/// The recorded size in bytes.
 int? get sizeBytes;
/// Create a copy of ServerOfflineItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerOfflineItemCopyWith<ServerOfflineItem> get copyWith => _$ServerOfflineItemCopyWithImpl<ServerOfflineItem>(this as ServerOfflineItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ServerOfflineItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerOfflineItem&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&(identical(other.revoked, _this.revoked) || other.revoked == _this.revoked)&&(identical(other.quality, _this.quality) || other.quality == _this.quality)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes));
}


@override
int get hashCode {
  final _this = this as ServerOfflineItem;
  return Object.hash(runtimeType,_this.playbackId,_this.revoked,_this.quality,_this.sizeBytes);
}

@override
String toString() {
  final _this = this as ServerOfflineItem;
  return 'ServerOfflineItem(playbackId: ${_this.playbackId}, revoked: ${_this.revoked}, quality: ${_this.quality}, sizeBytes: ${_this.sizeBytes})';
}


}

/// @nodoc
abstract mixin class $ServerOfflineItemCopyWith<$Res>  {
  factory $ServerOfflineItemCopyWith(ServerOfflineItem value, $Res Function(ServerOfflineItem) _then) = _$ServerOfflineItemCopyWithImpl;
@useResult
$Res call({
 PlaybackId playbackId, bool revoked, String? quality, int? sizeBytes
});




}
/// @nodoc
class _$ServerOfflineItemCopyWithImpl<$Res>
    implements $ServerOfflineItemCopyWith<$Res> {
  _$ServerOfflineItemCopyWithImpl(this._self, this._then);

  final ServerOfflineItem _self;
  final $Res Function(ServerOfflineItem) _then;

/// Create a copy of ServerOfflineItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playbackId = null,Object? revoked = null,Object? quality = freezed,Object? sizeBytes = freezed,}) {
  return _then(ServerOfflineItem(
playbackId: null == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as PlaybackId,revoked: null == revoked ? _self.revoked : revoked // ignore: cast_nullable_to_non_nullable
as bool,quality: freezed == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ServerOfflineItem].
extension ServerOfflineItemPatterns on ServerOfflineItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServerOfflineItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServerOfflineItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServerOfflineItem value)  $default,){
final _that = this;
switch (_that) {
case _ServerOfflineItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServerOfflineItem value)?  $default,){
final _that = this;
switch (_that) {
case _ServerOfflineItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlaybackId playbackId,  bool revoked,  String? quality,  int? sizeBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServerOfflineItem() when $default != null:
return $default(_that.playbackId,_that.revoked,_that.quality,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlaybackId playbackId,  bool revoked,  String? quality,  int? sizeBytes)  $default,) {final _that = this;
switch (_that) {
case _ServerOfflineItem():
return $default(_that.playbackId,_that.revoked,_that.quality,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlaybackId playbackId,  bool revoked,  String? quality,  int? sizeBytes)?  $default,) {final _that = this;
switch (_that) {
case _ServerOfflineItem() when $default != null:
return $default(_that.playbackId,_that.revoked,_that.quality,_that.sizeBytes);case _:
  return null;

}
}

}

/// @nodoc


class _ServerOfflineItem implements ServerOfflineItem {
  const _ServerOfflineItem({required this.playbackId, required this.revoked, this.quality, this.sizeBytes});
  

/// The track.
@override final  PlaybackId playbackId;
/// Whether the device must delete it.
@override final  bool revoked;
/// The recorded quality.
@override final  String? quality;
/// The recorded size in bytes.
@override final  int? sizeBytes;

/// Create a copy of ServerOfflineItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServerOfflineItemCopyWith<_ServerOfflineItem> get copyWith => __$ServerOfflineItemCopyWithImpl<_ServerOfflineItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServerOfflineItem&&(identical(other.playbackId, playbackId) || other.playbackId == playbackId)&&(identical(other.revoked, revoked) || other.revoked == revoked)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,playbackId,revoked,quality,sizeBytes);
}

@override
String toString() {
    return 'ServerOfflineItem(playbackId: $playbackId, revoked: $revoked, quality: $quality, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class _$ServerOfflineItemCopyWith<$Res> implements $ServerOfflineItemCopyWith<$Res> {
  factory _$ServerOfflineItemCopyWith(_ServerOfflineItem value, $Res Function(_ServerOfflineItem) _then) = __$ServerOfflineItemCopyWithImpl;
@override @useResult
$Res call({
 PlaybackId playbackId, bool revoked, String? quality, int? sizeBytes
});




}
/// @nodoc
class __$ServerOfflineItemCopyWithImpl<$Res>
    implements _$ServerOfflineItemCopyWith<$Res> {
  __$ServerOfflineItemCopyWithImpl(this._self, this._then);

  final _ServerOfflineItem _self;
  final $Res Function(_ServerOfflineItem) _then;

/// Create a copy of ServerOfflineItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playbackId = null,Object? revoked = null,Object? quality = freezed,Object? sizeBytes = freezed,}) {
  return _then(_ServerOfflineItem(
playbackId: null == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as PlaybackId,revoked: null == revoked ? _self.revoked : revoked // ignore: cast_nullable_to_non_nullable
as bool,quality: freezed == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$OfflineStats {

/// Megabytes every device of the user holds.
 double get usedMb;/// The user's limit in megabytes.
 double get maxMb;/// Megabytes this device holds.
 double get deviceUsedMb;/// Tracks this device holds.
 int get deviceTrackCount;
/// Create a copy of OfflineStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfflineStatsCopyWith<OfflineStats> get copyWith => _$OfflineStatsCopyWithImpl<OfflineStats>(this as OfflineStats, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OfflineStats;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OfflineStats&&(identical(other.usedMb, _this.usedMb) || other.usedMb == _this.usedMb)&&(identical(other.maxMb, _this.maxMb) || other.maxMb == _this.maxMb)&&(identical(other.deviceUsedMb, _this.deviceUsedMb) || other.deviceUsedMb == _this.deviceUsedMb)&&(identical(other.deviceTrackCount, _this.deviceTrackCount) || other.deviceTrackCount == _this.deviceTrackCount));
}


@override
int get hashCode {
  final _this = this as OfflineStats;
  return Object.hash(runtimeType,_this.usedMb,_this.maxMb,_this.deviceUsedMb,_this.deviceTrackCount);
}

@override
String toString() {
  final _this = this as OfflineStats;
  return 'OfflineStats(usedMb: ${_this.usedMb}, maxMb: ${_this.maxMb}, deviceUsedMb: ${_this.deviceUsedMb}, deviceTrackCount: ${_this.deviceTrackCount})';
}


}

/// @nodoc
abstract mixin class $OfflineStatsCopyWith<$Res>  {
  factory $OfflineStatsCopyWith(OfflineStats value, $Res Function(OfflineStats) _then) = _$OfflineStatsCopyWithImpl;
@useResult
$Res call({
 double usedMb, double maxMb, double deviceUsedMb, int deviceTrackCount
});




}
/// @nodoc
class _$OfflineStatsCopyWithImpl<$Res>
    implements $OfflineStatsCopyWith<$Res> {
  _$OfflineStatsCopyWithImpl(this._self, this._then);

  final OfflineStats _self;
  final $Res Function(OfflineStats) _then;

/// Create a copy of OfflineStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? usedMb = null,Object? maxMb = null,Object? deviceUsedMb = null,Object? deviceTrackCount = null,}) {
  return _then(OfflineStats(
usedMb: null == usedMb ? _self.usedMb : usedMb // ignore: cast_nullable_to_non_nullable
as double,maxMb: null == maxMb ? _self.maxMb : maxMb // ignore: cast_nullable_to_non_nullable
as double,deviceUsedMb: null == deviceUsedMb ? _self.deviceUsedMb : deviceUsedMb // ignore: cast_nullable_to_non_nullable
as double,deviceTrackCount: null == deviceTrackCount ? _self.deviceTrackCount : deviceTrackCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OfflineStats].
extension OfflineStatsPatterns on OfflineStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OfflineStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OfflineStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OfflineStats value)  $default,){
final _that = this;
switch (_that) {
case _OfflineStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OfflineStats value)?  $default,){
final _that = this;
switch (_that) {
case _OfflineStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double usedMb,  double maxMb,  double deviceUsedMb,  int deviceTrackCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OfflineStats() when $default != null:
return $default(_that.usedMb,_that.maxMb,_that.deviceUsedMb,_that.deviceTrackCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double usedMb,  double maxMb,  double deviceUsedMb,  int deviceTrackCount)  $default,) {final _that = this;
switch (_that) {
case _OfflineStats():
return $default(_that.usedMb,_that.maxMb,_that.deviceUsedMb,_that.deviceTrackCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double usedMb,  double maxMb,  double deviceUsedMb,  int deviceTrackCount)?  $default,) {final _that = this;
switch (_that) {
case _OfflineStats() when $default != null:
return $default(_that.usedMb,_that.maxMb,_that.deviceUsedMb,_that.deviceTrackCount);case _:
  return null;

}
}

}

/// @nodoc


class _OfflineStats implements OfflineStats {
  const _OfflineStats({required this.usedMb, required this.maxMb, required this.deviceUsedMb, required this.deviceTrackCount});
  

/// Megabytes every device of the user holds.
@override final  double usedMb;
/// The user's limit in megabytes.
@override final  double maxMb;
/// Megabytes this device holds.
@override final  double deviceUsedMb;
/// Tracks this device holds.
@override final  int deviceTrackCount;

/// Create a copy of OfflineStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OfflineStatsCopyWith<_OfflineStats> get copyWith => __$OfflineStatsCopyWithImpl<_OfflineStats>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OfflineStats&&(identical(other.usedMb, usedMb) || other.usedMb == usedMb)&&(identical(other.maxMb, maxMb) || other.maxMb == maxMb)&&(identical(other.deviceUsedMb, deviceUsedMb) || other.deviceUsedMb == deviceUsedMb)&&(identical(other.deviceTrackCount, deviceTrackCount) || other.deviceTrackCount == deviceTrackCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,usedMb,maxMb,deviceUsedMb,deviceTrackCount);
}

@override
String toString() {
    return 'OfflineStats(usedMb: $usedMb, maxMb: $maxMb, deviceUsedMb: $deviceUsedMb, deviceTrackCount: $deviceTrackCount)';
}


}

/// @nodoc
abstract mixin class _$OfflineStatsCopyWith<$Res> implements $OfflineStatsCopyWith<$Res> {
  factory _$OfflineStatsCopyWith(_OfflineStats value, $Res Function(_OfflineStats) _then) = __$OfflineStatsCopyWithImpl;
@override @useResult
$Res call({
 double usedMb, double maxMb, double deviceUsedMb, int deviceTrackCount
});




}
/// @nodoc
class __$OfflineStatsCopyWithImpl<$Res>
    implements _$OfflineStatsCopyWith<$Res> {
  __$OfflineStatsCopyWithImpl(this._self, this._then);

  final _OfflineStats _self;
  final $Res Function(_OfflineStats) _then;

/// Create a copy of OfflineStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? usedMb = null,Object? maxMb = null,Object? deviceUsedMb = null,Object? deviceTrackCount = null,}) {
  return _then(_OfflineStats(
usedMb: null == usedMb ? _self.usedMb : usedMb // ignore: cast_nullable_to_non_nullable
as double,maxMb: null == maxMb ? _self.maxMb : maxMb // ignore: cast_nullable_to_non_nullable
as double,deviceUsedMb: null == deviceUsedMb ? _self.deviceUsedMb : deviceUsedMb // ignore: cast_nullable_to_non_nullable
as double,deviceTrackCount: null == deviceTrackCount ? _self.deviceTrackCount : deviceTrackCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
