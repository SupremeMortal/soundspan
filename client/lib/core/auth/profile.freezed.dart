// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Profile {

/// The profile id, a UUID v4; names its directories and secret keys.
 String get id;/// The normalized server base URL, without a trailing slash; may
/// include a path prefix.
 Uri get baseUrl;/// The name the user gave the server; defaults to the host.
 String get displayName;/// The server's id of the signed-in user.
 String get userId;/// The signed-in user's username.
 String get username;/// The signed-in user's role on the server.
 String get role;/// How the credential was obtained.
 AuthKind get authKind;/// The playback device id, a UUID v4. Not a secret.
 String get deviceId;/// When the credential was issued.
 DateTime get credentialCreatedAt;/// Whether the profile is signed in.
 ProfileState get state;/// When the profile was last the active one.
 DateTime get lastUsedAt;/// The signed-in user's display name, if they have one.
 String? get userDisplayName;/// When the credential expires, if it does.
 DateTime? get credentialExpiresAt;/// The server version seen at the last capability refresh.
 String? get serverVersion;/// The server's feature flags from the last capability refresh.
 Map<String, Object?>? get features;/// When [features] was fetched.
 DateTime? get featuresFetchedAt;
/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileCopyWith<Profile> get copyWith => _$ProfileCopyWithImpl<Profile>(this as Profile, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Profile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Profile&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.baseUrl, _this.baseUrl) || other.baseUrl == _this.baseUrl)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.authKind, _this.authKind) || other.authKind == _this.authKind)&&(identical(other.deviceId, _this.deviceId) || other.deviceId == _this.deviceId)&&(identical(other.credentialCreatedAt, _this.credentialCreatedAt) || other.credentialCreatedAt == _this.credentialCreatedAt)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.lastUsedAt, _this.lastUsedAt) || other.lastUsedAt == _this.lastUsedAt)&&(identical(other.userDisplayName, _this.userDisplayName) || other.userDisplayName == _this.userDisplayName)&&(identical(other.credentialExpiresAt, _this.credentialExpiresAt) || other.credentialExpiresAt == _this.credentialExpiresAt)&&(identical(other.serverVersion, _this.serverVersion) || other.serverVersion == _this.serverVersion)&&const DeepCollectionEquality().equals(other.features, _this.features)&&(identical(other.featuresFetchedAt, _this.featuresFetchedAt) || other.featuresFetchedAt == _this.featuresFetchedAt));
}


@override
int get hashCode {
  final _this = this as Profile;
  return Object.hash(runtimeType,_this.id,_this.baseUrl,_this.displayName,_this.userId,_this.username,_this.role,_this.authKind,_this.deviceId,_this.credentialCreatedAt,_this.state,_this.lastUsedAt,_this.userDisplayName,_this.credentialExpiresAt,_this.serverVersion,const DeepCollectionEquality().hash(_this.features),_this.featuresFetchedAt);
}

@override
String toString() {
  final _this = this as Profile;
  return 'Profile(id: ${_this.id}, baseUrl: ${_this.baseUrl}, displayName: ${_this.displayName}, userId: ${_this.userId}, username: ${_this.username}, role: ${_this.role}, authKind: ${_this.authKind}, deviceId: ${_this.deviceId}, credentialCreatedAt: ${_this.credentialCreatedAt}, state: ${_this.state}, lastUsedAt: ${_this.lastUsedAt}, userDisplayName: ${_this.userDisplayName}, credentialExpiresAt: ${_this.credentialExpiresAt}, serverVersion: ${_this.serverVersion}, features: ${_this.features}, featuresFetchedAt: ${_this.featuresFetchedAt})';
}


}

/// @nodoc
abstract mixin class $ProfileCopyWith<$Res>  {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) _then) = _$ProfileCopyWithImpl;
@useResult
$Res call({
 String id, Uri baseUrl, String displayName, String userId, String username, String role, AuthKind authKind, String deviceId, DateTime credentialCreatedAt, ProfileState state, DateTime lastUsedAt, String? userDisplayName, DateTime? credentialExpiresAt, String? serverVersion, Map<String, Object?>? features, DateTime? featuresFetchedAt
});




}
/// @nodoc
class _$ProfileCopyWithImpl<$Res>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._self, this._then);

  final Profile _self;
  final $Res Function(Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? baseUrl = null,Object? displayName = null,Object? userId = null,Object? username = null,Object? role = null,Object? authKind = null,Object? deviceId = null,Object? credentialCreatedAt = null,Object? state = null,Object? lastUsedAt = null,Object? userDisplayName = freezed,Object? credentialExpiresAt = freezed,Object? serverVersion = freezed,Object? features = freezed,Object? featuresFetchedAt = freezed,}) {
  return _then(Profile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as Uri,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,authKind: null == authKind ? _self.authKind : authKind // ignore: cast_nullable_to_non_nullable
as AuthKind,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,credentialCreatedAt: null == credentialCreatedAt ? _self.credentialCreatedAt : credentialCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ProfileState,lastUsedAt: null == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as DateTime,userDisplayName: freezed == userDisplayName ? _self.userDisplayName : userDisplayName // ignore: cast_nullable_to_non_nullable
as String?,credentialExpiresAt: freezed == credentialExpiresAt ? _self.credentialExpiresAt : credentialExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,serverVersion: freezed == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String?,features: freezed == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,featuresFetchedAt: freezed == featuresFetchedAt ? _self.featuresFetchedAt : featuresFetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Profile].
extension ProfilePatterns on Profile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Profile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Profile value)  $default,){
final _that = this;
switch (_that) {
case _Profile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Profile value)?  $default,){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Uri baseUrl,  String displayName,  String userId,  String username,  String role,  AuthKind authKind,  String deviceId,  DateTime credentialCreatedAt,  ProfileState state,  DateTime lastUsedAt,  String? userDisplayName,  DateTime? credentialExpiresAt,  String? serverVersion,  Map<String, Object?>? features,  DateTime? featuresFetchedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.id,_that.baseUrl,_that.displayName,_that.userId,_that.username,_that.role,_that.authKind,_that.deviceId,_that.credentialCreatedAt,_that.state,_that.lastUsedAt,_that.userDisplayName,_that.credentialExpiresAt,_that.serverVersion,_that.features,_that.featuresFetchedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Uri baseUrl,  String displayName,  String userId,  String username,  String role,  AuthKind authKind,  String deviceId,  DateTime credentialCreatedAt,  ProfileState state,  DateTime lastUsedAt,  String? userDisplayName,  DateTime? credentialExpiresAt,  String? serverVersion,  Map<String, Object?>? features,  DateTime? featuresFetchedAt)  $default,) {final _that = this;
switch (_that) {
case _Profile():
return $default(_that.id,_that.baseUrl,_that.displayName,_that.userId,_that.username,_that.role,_that.authKind,_that.deviceId,_that.credentialCreatedAt,_that.state,_that.lastUsedAt,_that.userDisplayName,_that.credentialExpiresAt,_that.serverVersion,_that.features,_that.featuresFetchedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Uri baseUrl,  String displayName,  String userId,  String username,  String role,  AuthKind authKind,  String deviceId,  DateTime credentialCreatedAt,  ProfileState state,  DateTime lastUsedAt,  String? userDisplayName,  DateTime? credentialExpiresAt,  String? serverVersion,  Map<String, Object?>? features,  DateTime? featuresFetchedAt)?  $default,) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.id,_that.baseUrl,_that.displayName,_that.userId,_that.username,_that.role,_that.authKind,_that.deviceId,_that.credentialCreatedAt,_that.state,_that.lastUsedAt,_that.userDisplayName,_that.credentialExpiresAt,_that.serverVersion,_that.features,_that.featuresFetchedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Profile implements Profile {
  const _Profile({required this.id, required this.baseUrl, required this.displayName, required this.userId, required this.username, required this.role, required this.authKind, required this.deviceId, required this.credentialCreatedAt, required this.state, required this.lastUsedAt, this.userDisplayName, this.credentialExpiresAt, this.serverVersion,  Map<String, Object?>? features, this.featuresFetchedAt}): _features = features;
  

/// The profile id, a UUID v4; names its directories and secret keys.
@override final  String id;
/// The normalized server base URL, without a trailing slash; may
/// include a path prefix.
@override final  Uri baseUrl;
/// The name the user gave the server; defaults to the host.
@override final  String displayName;
/// The server's id of the signed-in user.
@override final  String userId;
/// The signed-in user's username.
@override final  String username;
/// The signed-in user's role on the server.
@override final  String role;
/// How the credential was obtained.
@override final  AuthKind authKind;
/// The playback device id, a UUID v4. Not a secret.
@override final  String deviceId;
/// When the credential was issued.
@override final  DateTime credentialCreatedAt;
/// Whether the profile is signed in.
@override final  ProfileState state;
/// When the profile was last the active one.
@override final  DateTime lastUsedAt;
/// The signed-in user's display name, if they have one.
@override final  String? userDisplayName;
/// When the credential expires, if it does.
@override final  DateTime? credentialExpiresAt;
/// The server version seen at the last capability refresh.
@override final  String? serverVersion;
/// The server's feature flags from the last capability refresh.
 final  Map<String, Object?>? _features;
/// The server's feature flags from the last capability refresh.
@override Map<String, Object?>? get features {
  final value = _features;
  if (value == null) return null;
  if (_features is EqualUnmodifiableMapView) return _features;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// When [features] was fetched.
@override final  DateTime? featuresFetchedAt;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileCopyWith<_Profile> get copyWith => __$ProfileCopyWithImpl<_Profile>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Profile&&(identical(other.id, id) || other.id == id)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.role, role) || other.role == role)&&(identical(other.authKind, authKind) || other.authKind == authKind)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.credentialCreatedAt, credentialCreatedAt) || other.credentialCreatedAt == credentialCreatedAt)&&(identical(other.state, state) || other.state == state)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt)&&(identical(other.userDisplayName, userDisplayName) || other.userDisplayName == userDisplayName)&&(identical(other.credentialExpiresAt, credentialExpiresAt) || other.credentialExpiresAt == credentialExpiresAt)&&(identical(other.serverVersion, serverVersion) || other.serverVersion == serverVersion)&&const DeepCollectionEquality().equals(other.features, _features)&&(identical(other.featuresFetchedAt, featuresFetchedAt) || other.featuresFetchedAt == featuresFetchedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,baseUrl,displayName,userId,username,role,authKind,deviceId,credentialCreatedAt,state,lastUsedAt,userDisplayName,credentialExpiresAt,serverVersion,const DeepCollectionEquality().hash(_features),featuresFetchedAt);
}

@override
String toString() {
    return 'Profile(id: $id, baseUrl: $baseUrl, displayName: $displayName, userId: $userId, username: $username, role: $role, authKind: $authKind, deviceId: $deviceId, credentialCreatedAt: $credentialCreatedAt, state: $state, lastUsedAt: $lastUsedAt, userDisplayName: $userDisplayName, credentialExpiresAt: $credentialExpiresAt, serverVersion: $serverVersion, features: $features, featuresFetchedAt: $featuresFetchedAt)';
}


}

/// @nodoc
abstract mixin class _$ProfileCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$ProfileCopyWith(_Profile value, $Res Function(_Profile) _then) = __$ProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, Uri baseUrl, String displayName, String userId, String username, String role, AuthKind authKind, String deviceId, DateTime credentialCreatedAt, ProfileState state, DateTime lastUsedAt, String? userDisplayName, DateTime? credentialExpiresAt, String? serverVersion, Map<String, Object?>? features, DateTime? featuresFetchedAt
});




}
/// @nodoc
class __$ProfileCopyWithImpl<$Res>
    implements _$ProfileCopyWith<$Res> {
  __$ProfileCopyWithImpl(this._self, this._then);

  final _Profile _self;
  final $Res Function(_Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? baseUrl = null,Object? displayName = null,Object? userId = null,Object? username = null,Object? role = null,Object? authKind = null,Object? deviceId = null,Object? credentialCreatedAt = null,Object? state = null,Object? lastUsedAt = null,Object? userDisplayName = freezed,Object? credentialExpiresAt = freezed,Object? serverVersion = freezed,Object? features = freezed,Object? featuresFetchedAt = freezed,}) {
  return _then(_Profile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as Uri,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,authKind: null == authKind ? _self.authKind : authKind // ignore: cast_nullable_to_non_nullable
as AuthKind,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,credentialCreatedAt: null == credentialCreatedAt ? _self.credentialCreatedAt : credentialCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ProfileState,lastUsedAt: null == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as DateTime,userDisplayName: freezed == userDisplayName ? _self.userDisplayName : userDisplayName // ignore: cast_nullable_to_non_nullable
as String?,credentialExpiresAt: freezed == credentialExpiresAt ? _self.credentialExpiresAt : credentialExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,serverVersion: freezed == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as String?,features: freezed == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,featuresFetchedAt: freezed == featuresFetchedAt ? _self.featuresFetchedAt : featuresFetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
