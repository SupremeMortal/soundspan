// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recently_listened_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecentlyListenedItem {


/// Create a copy of RecentlyListenedItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentlyListenedItemCopyWith<RecentlyListenedItem> get copyWith => _$RecentlyListenedItemCopyWithImpl<RecentlyListenedItem>(this as RecentlyListenedItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RecentlyListenedItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentlyListenedItem&&(identical(other.albumCount, _this.albumCount) || other.albumCount == _this.albumCount)&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.coverArt, _this.coverArt) || other.coverArt == _this.coverArt)&&(identical(other.episodeId, _this.episodeId) || other.episodeId == _this.episodeId)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.lastPlayedAt, _this.lastPlayedAt) || other.lastPlayedAt == _this.lastPlayedAt)&&(identical(other.mbid, _this.mbid) || other.mbid == _this.mbid)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.progress, _this.progress) || other.progress == _this.progress)&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as RecentlyListenedItem;
  return Object.hash(runtimeType,_this.albumCount,_this.author,_this.coverArt,_this.episodeId,_this.id,_this.lastPlayedAt,_this.mbid,_this.name,_this.progress,_this.type,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as RecentlyListenedItem;
  return 'RecentlyListenedItem(albumCount: ${_this.albumCount}, author: ${_this.author}, coverArt: ${_this.coverArt}, episodeId: ${_this.episodeId}, id: ${_this.id}, lastPlayedAt: ${_this.lastPlayedAt}, mbid: ${_this.mbid}, name: ${_this.name}, progress: ${_this.progress}, type: ${_this.type}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $RecentlyListenedItemCopyWith<$Res>  {
  factory $RecentlyListenedItemCopyWith(RecentlyListenedItem value, $Res Function(RecentlyListenedItem) _then) = _$RecentlyListenedItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: RecentlyListenedItem._read_albumCount, toJson: RecentlyListenedItem._write_albumCount) int? albumCount,@JsonKey(includeIfNull: false) String? author,@JsonKey(required: true) String? coverArt,@JsonKey(disallowNullValue: true, includeIfNull: false) String? episodeId,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true, disallowNullValue: true, fromJson: RecentlyListenedItem._read_lastPlayedAt, toJson: RecentlyListenedItem._write_lastPlayedAt) DateTime lastPlayedAt,@JsonKey(includeIfNull: false) String? mbid,@JsonKey(required: true, disallowNullValue: true) String name,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: RecentlyListenedItem._read_progress, toJson: RecentlyListenedItem._write_progress) int? progress,@JsonKey(required: true, disallowNullValue: true, fromJson: RecentlyListenedItem._read_type, toJson: RecentlyListenedItem._write_type) RecentlyListenedItemType type,@JsonKey(readValue: RecentlyListenedItem._extras, fromJson: RecentlyListenedItem._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$RecentlyListenedItemCopyWithImpl<$Res>
    implements $RecentlyListenedItemCopyWith<$Res> {
  _$RecentlyListenedItemCopyWithImpl(this._self, this._then);

  final RecentlyListenedItem _self;
  final $Res Function(RecentlyListenedItem) _then;

/// Create a copy of RecentlyListenedItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? albumCount = freezed,Object? author = freezed,Object? coverArt = freezed,Object? episodeId = freezed,Object? id = null,Object? lastPlayedAt = null,Object? mbid = freezed,Object? name = null,Object? progress = freezed,Object? type = null,Object? additionalProperties = null,}) {
  return _then(RecentlyListenedItem(
albumCount: freezed == albumCount ? _self.albumCount : albumCount // ignore: cast_nullable_to_non_nullable
as int?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,episodeId: freezed == episodeId ? _self.episodeId : episodeId // ignore: cast_nullable_to_non_nullable
as String?,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lastPlayedAt: null == lastPlayedAt ? _self.lastPlayedAt : lastPlayedAt // ignore: cast_nullable_to_non_nullable
as DateTime,mbid: freezed == mbid ? _self.mbid : mbid // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as RecentlyListenedItemType,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [RecentlyListenedItem].
extension RecentlyListenedItemPatterns on RecentlyListenedItem {
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
