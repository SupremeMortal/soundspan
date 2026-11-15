// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'online_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnlineUser {


/// Create a copy of OnlineUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnlineUserCopyWith<OnlineUser> get copyWith => _$OnlineUserCopyWithImpl<OnlineUser>(this as OnlineUser, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OnlineUser;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnlineUser&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.hasProfilePicture, _this.hasProfilePicture) || other.hasProfilePicture == _this.hasProfilePicture)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.isInListenTogetherGroup, _this.isInListenTogetherGroup) || other.isInListenTogetherGroup == _this.isInListenTogetherGroup)&&(identical(other.lastHeartbeatAt, _this.lastHeartbeatAt) || other.lastHeartbeatAt == _this.lastHeartbeatAt)&&(identical(other.listeningStatus, _this.listeningStatus) || other.listeningStatus == _this.listeningStatus)&&(identical(other.listeningTrack, _this.listeningTrack) || other.listeningTrack == _this.listeningTrack)&&(identical(other.username, _this.username) || other.username == _this.username)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as OnlineUser;
  return Object.hash(runtimeType,_this.displayName,_this.hasProfilePicture,_this.id,_this.isInListenTogetherGroup,_this.lastHeartbeatAt,_this.listeningStatus,_this.listeningTrack,_this.username,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as OnlineUser;
  return 'OnlineUser(displayName: ${_this.displayName}, hasProfilePicture: ${_this.hasProfilePicture}, id: ${_this.id}, isInListenTogetherGroup: ${_this.isInListenTogetherGroup}, lastHeartbeatAt: ${_this.lastHeartbeatAt}, listeningStatus: ${_this.listeningStatus}, listeningTrack: ${_this.listeningTrack}, username: ${_this.username}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $OnlineUserCopyWith<$Res>  {
  factory $OnlineUserCopyWith(OnlineUser value, $Res Function(OnlineUser) _then) = _$OnlineUserCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String displayName,@JsonKey(required: true, disallowNullValue: true) bool hasProfilePicture,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true, disallowNullValue: true) bool isInListenTogetherGroup,@JsonKey(required: true, disallowNullValue: true, fromJson: OnlineUser._read_lastHeartbeatAt, toJson: OnlineUser._write_lastHeartbeatAt) DateTime lastHeartbeatAt,@JsonKey(required: true, disallowNullValue: true, fromJson: OnlineUser._read_listeningStatus, toJson: OnlineUser._write_listeningStatus) OnlineUserListeningStatus listeningStatus,@JsonKey(required: true, disallowNullValue: true) OnlineUserTrack listeningTrack,@JsonKey(required: true, disallowNullValue: true) String username,@JsonKey(readValue: OnlineUser._extras, fromJson: OnlineUser._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$OnlineUserTrackCopyWith<$Res> get listeningTrack;

}
/// @nodoc
class _$OnlineUserCopyWithImpl<$Res>
    implements $OnlineUserCopyWith<$Res> {
  _$OnlineUserCopyWithImpl(this._self, this._then);

  final OnlineUser _self;
  final $Res Function(OnlineUser) _then;

/// Create a copy of OnlineUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayName = null,Object? hasProfilePicture = null,Object? id = null,Object? isInListenTogetherGroup = null,Object? lastHeartbeatAt = null,Object? listeningStatus = null,Object? listeningTrack = null,Object? username = null,Object? additionalProperties = null,}) {
  return _then(OnlineUser(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,hasProfilePicture: null == hasProfilePicture ? _self.hasProfilePicture : hasProfilePicture // ignore: cast_nullable_to_non_nullable
as bool,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,isInListenTogetherGroup: null == isInListenTogetherGroup ? _self.isInListenTogetherGroup : isInListenTogetherGroup // ignore: cast_nullable_to_non_nullable
as bool,lastHeartbeatAt: null == lastHeartbeatAt ? _self.lastHeartbeatAt : lastHeartbeatAt // ignore: cast_nullable_to_non_nullable
as DateTime,listeningStatus: null == listeningStatus ? _self.listeningStatus : listeningStatus // ignore: cast_nullable_to_non_nullable
as OnlineUserListeningStatus,listeningTrack: null == listeningTrack ? _self.listeningTrack : listeningTrack // ignore: cast_nullable_to_non_nullable
as OnlineUserTrack,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of OnlineUser
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OnlineUserTrackCopyWith<$Res> get listeningTrack {
  
  return $OnlineUserTrackCopyWith<$Res>(_self.listeningTrack, (value) {
    return _then(_self.copyWith(listeningTrack: value));
  });
}
}


/// Adds pattern-matching-related methods to [OnlineUser].
extension OnlineUserPatterns on OnlineUser {
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
