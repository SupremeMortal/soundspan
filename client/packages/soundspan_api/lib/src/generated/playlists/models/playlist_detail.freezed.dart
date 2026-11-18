// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaylistDetail {


/// Create a copy of PlaylistDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistDetailCopyWith<PlaylistDetail> get copyWith => _$PlaylistDetailCopyWithImpl<PlaylistDetail>(this as PlaylistDetail, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlaylistDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistDetail&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.isHidden, _this.isHidden) || other.isHidden == _this.isHidden)&&(identical(other.isOwner, _this.isOwner) || other.isOwner == _this.isOwner)&&(identical(other.isPublic, _this.isPublic) || other.isPublic == _this.isPublic)&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.pendingCount, _this.pendingCount) || other.pendingCount == _this.pendingCount)&&(identical(other.totalItemCount, _this.totalItemCount) || other.totalItemCount == _this.totalItemCount)&&(identical(other.trackCount, _this.trackCount) || other.trackCount == _this.trackCount)&&(identical(other.truncated, _this.truncated) || other.truncated == _this.truncated)&&(identical(other.unplayableCount, _this.unplayableCount) || other.unplayableCount == _this.unplayableCount)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.user, _this.user) || other.user == _this.user)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as PlaylistDetail;
  return Object.hash(runtimeType,_this.createdAt,_this.id,_this.isHidden,_this.isOwner,_this.isPublic,const DeepCollectionEquality().hash(_this.items),_this.name,_this.pendingCount,_this.totalItemCount,_this.trackCount,_this.truncated,_this.unplayableCount,_this.updatedAt,_this.user,_this.userId,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as PlaylistDetail;
  return 'PlaylistDetail(createdAt: ${_this.createdAt}, id: ${_this.id}, isHidden: ${_this.isHidden}, isOwner: ${_this.isOwner}, isPublic: ${_this.isPublic}, items: ${_this.items}, name: ${_this.name}, pendingCount: ${_this.pendingCount}, totalItemCount: ${_this.totalItemCount}, trackCount: ${_this.trackCount}, truncated: ${_this.truncated}, unplayableCount: ${_this.unplayableCount}, updatedAt: ${_this.updatedAt}, user: ${_this.user}, userId: ${_this.userId}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $PlaylistDetailCopyWith<$Res>  {
  factory $PlaylistDetailCopyWith(PlaylistDetail value, $Res Function(PlaylistDetail) _then) = _$PlaylistDetailCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true, fromJson: PlaylistDetail._read_createdAt, toJson: PlaylistDetail._write_createdAt) DateTime createdAt,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true, disallowNullValue: true) bool isHidden,@JsonKey(required: true, disallowNullValue: true) bool isOwner,@JsonKey(required: true, disallowNullValue: true) bool isPublic,@JsonKey(required: true, disallowNullValue: true) List<PlaylistItem> items,@JsonKey(required: true, disallowNullValue: true) String name,@JsonKey(required: true, disallowNullValue: true, fromJson: PlaylistDetail._read_pendingCount, toJson: PlaylistDetail._write_pendingCount) int pendingCount,@JsonKey(required: true, disallowNullValue: true, fromJson: PlaylistDetail._read_totalItemCount, toJson: PlaylistDetail._write_totalItemCount) int totalItemCount,@JsonKey(required: true, disallowNullValue: true, fromJson: PlaylistDetail._read_trackCount, toJson: PlaylistDetail._write_trackCount) int trackCount,@JsonKey(required: true, disallowNullValue: true) bool truncated,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: PlaylistDetail._read_unplayableCount, toJson: PlaylistDetail._write_unplayableCount) int? unplayableCount,@JsonKey(required: true, disallowNullValue: true, fromJson: PlaylistDetail._read_updatedAt, toJson: PlaylistDetail._write_updatedAt) DateTime updatedAt,@JsonKey(required: true, disallowNullValue: true) PlaylistOwner user,@JsonKey(required: true, disallowNullValue: true) String userId,@JsonKey(readValue: PlaylistDetail._extras, fromJson: PlaylistDetail._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$PlaylistOwnerCopyWith<$Res> get user;

}
/// @nodoc
class _$PlaylistDetailCopyWithImpl<$Res>
    implements $PlaylistDetailCopyWith<$Res> {
  _$PlaylistDetailCopyWithImpl(this._self, this._then);

  final PlaylistDetail _self;
  final $Res Function(PlaylistDetail) _then;

/// Create a copy of PlaylistDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? createdAt = null,Object? id = null,Object? isHidden = null,Object? isOwner = null,Object? isPublic = null,Object? items = null,Object? name = null,Object? pendingCount = null,Object? totalItemCount = null,Object? trackCount = null,Object? truncated = null,Object? unplayableCount = freezed,Object? updatedAt = null,Object? user = null,Object? userId = null,Object? additionalProperties = null,}) {
  return _then(PlaylistDetail(
createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,isHidden: null == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool,isOwner: null == isOwner ? _self.isOwner : isOwner // ignore: cast_nullable_to_non_nullable
as bool,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<PlaylistItem>,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,pendingCount: null == pendingCount ? _self.pendingCount : pendingCount // ignore: cast_nullable_to_non_nullable
as int,totalItemCount: null == totalItemCount ? _self.totalItemCount : totalItemCount // ignore: cast_nullable_to_non_nullable
as int,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,truncated: null == truncated ? _self.truncated : truncated // ignore: cast_nullable_to_non_nullable
as bool,unplayableCount: freezed == unplayableCount ? _self.unplayableCount : unplayableCount // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as PlaylistOwner,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of PlaylistDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaylistOwnerCopyWith<$Res> get user {
  
  return $PlaylistOwnerCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlaylistDetail].
extension PlaylistDetailPatterns on PlaylistDetail {
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
