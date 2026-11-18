// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'listen_group_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ListenGroupSnapshot {


/// Create a copy of ListenGroupSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListenGroupSnapshotCopyWith<ListenGroupSnapshot> get copyWith => _$ListenGroupSnapshotCopyWithImpl<ListenGroupSnapshot>(this as ListenGroupSnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ListenGroupSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListenGroupSnapshot&&(identical(other.groupType, _this.groupType) || other.groupType == _this.groupType)&&(identical(other.hostUserId, _this.hostUserId) || other.hostUserId == _this.hostUserId)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive)&&(identical(other.joinCode, _this.joinCode) || other.joinCode == _this.joinCode)&&const DeepCollectionEquality().equals(other.members, _this.members)&&(identical(other.membershipVersion, _this.membershipVersion) || other.membershipVersion == _this.membershipVersion)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.playback, _this.playback) || other.playback == _this.playback)&&(identical(other.readyDeadlineMs, _this.readyDeadlineMs) || other.readyDeadlineMs == _this.readyDeadlineMs)&&const DeepCollectionEquality().equals(other.readyUserIds, _this.readyUserIds)&&(identical(other.syncState, _this.syncState) || other.syncState == _this.syncState)&&(identical(other.visibility, _this.visibility) || other.visibility == _this.visibility)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as ListenGroupSnapshot;
  return Object.hash(runtimeType,_this.groupType,_this.hostUserId,_this.id,_this.isActive,_this.joinCode,const DeepCollectionEquality().hash(_this.members),_this.membershipVersion,_this.name,_this.playback,_this.readyDeadlineMs,const DeepCollectionEquality().hash(_this.readyUserIds),_this.syncState,_this.visibility,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as ListenGroupSnapshot;
  return 'ListenGroupSnapshot(groupType: ${_this.groupType}, hostUserId: ${_this.hostUserId}, id: ${_this.id}, isActive: ${_this.isActive}, joinCode: ${_this.joinCode}, members: ${_this.members}, membershipVersion: ${_this.membershipVersion}, name: ${_this.name}, playback: ${_this.playback}, readyDeadlineMs: ${_this.readyDeadlineMs}, readyUserIds: ${_this.readyUserIds}, syncState: ${_this.syncState}, visibility: ${_this.visibility}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $ListenGroupSnapshotCopyWith<$Res>  {
  factory $ListenGroupSnapshotCopyWith(ListenGroupSnapshot value, $Res Function(ListenGroupSnapshot) _then) = _$ListenGroupSnapshotCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true, fromJson: ListenGroupSnapshot._read_groupType, toJson: ListenGroupSnapshot._write_groupType) ListenGroupSnapshotGroupType groupType,@JsonKey(required: true, disallowNullValue: true) String hostUserId,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true, disallowNullValue: true) bool isActive,@JsonKey(required: true, disallowNullValue: true) String joinCode,@JsonKey(required: true, disallowNullValue: true) List<ListenGroupMember> members,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: ListenGroupSnapshot._read_membershipVersion, toJson: ListenGroupSnapshot._write_membershipVersion) int? membershipVersion,@JsonKey(required: true, disallowNullValue: true) String name,@JsonKey(required: true, disallowNullValue: true) ListenGroupPlayback playback,@JsonKey(includeIfNull: false, fromJson: ListenGroupSnapshot._read_readyDeadlineMs, toJson: ListenGroupSnapshot._write_readyDeadlineMs) int? readyDeadlineMs,@JsonKey(disallowNullValue: true, includeIfNull: false) List<String>? readyUserIds,@JsonKey(required: true, disallowNullValue: true, fromJson: ListenGroupSnapshot._read_syncState, toJson: ListenGroupSnapshot._write_syncState) ListenGroupSnapshotSyncState syncState,@JsonKey(required: true, disallowNullValue: true, fromJson: ListenGroupSnapshot._read_visibility, toJson: ListenGroupSnapshot._write_visibility) ListenGroupSnapshotVisibility visibility,@JsonKey(readValue: ListenGroupSnapshot._extras, fromJson: ListenGroupSnapshot._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$ListenGroupPlaybackCopyWith<$Res> get playback;

}
/// @nodoc
class _$ListenGroupSnapshotCopyWithImpl<$Res>
    implements $ListenGroupSnapshotCopyWith<$Res> {
  _$ListenGroupSnapshotCopyWithImpl(this._self, this._then);

  final ListenGroupSnapshot _self;
  final $Res Function(ListenGroupSnapshot) _then;

/// Create a copy of ListenGroupSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupType = null,Object? hostUserId = null,Object? id = null,Object? isActive = null,Object? joinCode = null,Object? members = null,Object? membershipVersion = freezed,Object? name = null,Object? playback = null,Object? readyDeadlineMs = freezed,Object? readyUserIds = freezed,Object? syncState = null,Object? visibility = null,Object? additionalProperties = null,}) {
  return _then(ListenGroupSnapshot(
groupType: null == groupType ? _self.groupType : groupType // ignore: cast_nullable_to_non_nullable
as ListenGroupSnapshotGroupType,hostUserId: null == hostUserId ? _self.hostUserId : hostUserId // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,joinCode: null == joinCode ? _self.joinCode : joinCode // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<ListenGroupMember>,membershipVersion: freezed == membershipVersion ? _self.membershipVersion : membershipVersion // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,playback: null == playback ? _self.playback : playback // ignore: cast_nullable_to_non_nullable
as ListenGroupPlayback,readyDeadlineMs: freezed == readyDeadlineMs ? _self.readyDeadlineMs : readyDeadlineMs // ignore: cast_nullable_to_non_nullable
as int?,readyUserIds: freezed == readyUserIds ? _self.readyUserIds : readyUserIds // ignore: cast_nullable_to_non_nullable
as List<String>?,syncState: null == syncState ? _self.syncState : syncState // ignore: cast_nullable_to_non_nullable
as ListenGroupSnapshotSyncState,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as ListenGroupSnapshotVisibility,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of ListenGroupSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ListenGroupPlaybackCopyWith<$Res> get playback {
  
  return $ListenGroupPlaybackCopyWith<$Res>(_self.playback, (value) {
    return _then(_self.copyWith(playback: value));
  });
}
}


/// Adds pattern-matching-related methods to [ListenGroupSnapshot].
extension ListenGroupSnapshotPatterns on ListenGroupSnapshot {
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
