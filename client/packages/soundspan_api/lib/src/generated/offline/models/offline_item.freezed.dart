// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offline_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OfflineItem {


/// Create a copy of OfflineItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfflineItemCopyWith<OfflineItem> get copyWith => _$OfflineItemCopyWithImpl<OfflineItem>(this as OfflineItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OfflineItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OfflineItem&&(identical(other.contentType, _this.contentType) || other.contentType == _this.contentType)&&(identical(other.downloadUrl, _this.downloadUrl) || other.downloadUrl == _this.downloadUrl)&&(identical(other.downloadable, _this.downloadable) || other.downloadable == _this.downloadable)&&(identical(other.expectedSize, _this.expectedSize) || other.expectedSize == _this.expectedSize)&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&(identical(other.quality, _this.quality) || other.quality == _this.quality)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as OfflineItem;
  return Object.hash(runtimeType,_this.contentType,_this.downloadUrl,_this.downloadable,_this.expectedSize,_this.playbackId,_this.quality,_this.reason,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as OfflineItem;
  return 'OfflineItem(contentType: ${_this.contentType}, downloadUrl: ${_this.downloadUrl}, downloadable: ${_this.downloadable}, expectedSize: ${_this.expectedSize}, playbackId: ${_this.playbackId}, quality: ${_this.quality}, reason: ${_this.reason}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $OfflineItemCopyWith<$Res>  {
  factory $OfflineItemCopyWith(OfflineItem value, $Res Function(OfflineItem) _then) = _$OfflineItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) String? contentType,@JsonKey(disallowNullValue: true, includeIfNull: false) String? downloadUrl,@JsonKey(required: true, disallowNullValue: true) bool downloadable,@JsonKey(includeIfNull: false, fromJson: OfflineItem._read_expectedSize, toJson: OfflineItem._write_expectedSize) int? expectedSize,@JsonKey(required: true, disallowNullValue: true) String playbackId,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: OfflineItem._read_quality, toJson: OfflineItem._write_quality) OfflineItemQuality? quality,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: OfflineItem._read_reason, toJson: OfflineItem._write_reason) OfflineItemReason? reason,@JsonKey(readValue: OfflineItem._extras, fromJson: OfflineItem._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
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
@pragma('vm:prefer-inline') @override $Res call({Object? contentType = freezed,Object? downloadUrl = freezed,Object? downloadable = null,Object? expectedSize = freezed,Object? playbackId = null,Object? quality = freezed,Object? reason = freezed,Object? additionalProperties = null,}) {
  return _then(OfflineItem(
contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,downloadUrl: freezed == downloadUrl ? _self.downloadUrl : downloadUrl // ignore: cast_nullable_to_non_nullable
as String?,downloadable: null == downloadable ? _self.downloadable : downloadable // ignore: cast_nullable_to_non_nullable
as bool,expectedSize: freezed == expectedSize ? _self.expectedSize : expectedSize // ignore: cast_nullable_to_non_nullable
as int?,playbackId: null == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as String,quality: freezed == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as OfflineItemQuality?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as OfflineItemReason?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
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
