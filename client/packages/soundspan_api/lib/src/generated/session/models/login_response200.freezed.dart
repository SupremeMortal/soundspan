// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'login_response200.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LoginTokenResponse {


/// Create a copy of LoginTokenResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginTokenResponseCopyWith<LoginTokenResponse> get copyWith => _$LoginTokenResponseCopyWithImpl<LoginTokenResponse>(this as LoginTokenResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LoginTokenResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginTokenResponse&&(identical(other.refreshToken, _this.refreshToken) || other.refreshToken == _this.refreshToken)&&(identical(other.token, _this.token) || other.token == _this.token)&&(identical(other.user, _this.user) || other.user == _this.user)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as LoginTokenResponse;
  return Object.hash(runtimeType,_this.refreshToken,_this.token,_this.user,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as LoginTokenResponse;
  return 'LoginTokenResponse(refreshToken: ${_this.refreshToken}, token: ${_this.token}, user: ${_this.user}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $LoginTokenResponseCopyWith<$Res>  {
  factory $LoginTokenResponseCopyWith(LoginTokenResponse value, $Res Function(LoginTokenResponse) _then) = _$LoginTokenResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String refreshToken,@JsonKey(required: true, disallowNullValue: true) String token,@JsonKey(required: true, disallowNullValue: true) LoginUser user,@JsonKey(readValue: LoginTokenResponse._extras, fromJson: LoginTokenResponse._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$LoginUserCopyWith<$Res> get user;

}
/// @nodoc
class _$LoginTokenResponseCopyWithImpl<$Res>
    implements $LoginTokenResponseCopyWith<$Res> {
  _$LoginTokenResponseCopyWithImpl(this._self, this._then);

  final LoginTokenResponse _self;
  final $Res Function(LoginTokenResponse) _then;

/// Create a copy of LoginTokenResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? refreshToken = null,Object? token = null,Object? user = null,Object? additionalProperties = null,}) {
  return _then(LoginTokenResponse(
refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as LoginUser,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of LoginTokenResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LoginUserCopyWith<$Res> get user {
  
  return $LoginUserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [LoginTokenResponse].
extension LoginTokenResponsePatterns on LoginTokenResponse {
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

/// @nodoc
mixin _$LoginTwoFactorChallenge {


/// Create a copy of LoginTwoFactorChallenge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginTwoFactorChallengeCopyWith<LoginTwoFactorChallenge> get copyWith => _$LoginTwoFactorChallengeCopyWithImpl<LoginTwoFactorChallenge>(this as LoginTwoFactorChallenge, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LoginTwoFactorChallenge;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginTwoFactorChallenge&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.requires2FA, _this.requires2FA) || other.requires2FA == _this.requires2FA)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as LoginTwoFactorChallenge;
  return Object.hash(runtimeType,_this.message,_this.requires2FA,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as LoginTwoFactorChallenge;
  return 'LoginTwoFactorChallenge(message: ${_this.message}, requires2FA: ${_this.requires2FA}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $LoginTwoFactorChallengeCopyWith<$Res>  {
  factory $LoginTwoFactorChallengeCopyWith(LoginTwoFactorChallenge value, $Res Function(LoginTwoFactorChallenge) _then) = _$LoginTwoFactorChallengeCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String message,@JsonKey(required: true, disallowNullValue: true, fromJson: LoginTwoFactorChallenge._read_requires2FA, toJson: LoginTwoFactorChallenge._write_requires2FA) LoginTwoFactorChallengeRequires2FA requires2FA,@JsonKey(readValue: LoginTwoFactorChallenge._extras, fromJson: LoginTwoFactorChallenge._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$LoginTwoFactorChallengeCopyWithImpl<$Res>
    implements $LoginTwoFactorChallengeCopyWith<$Res> {
  _$LoginTwoFactorChallengeCopyWithImpl(this._self, this._then);

  final LoginTwoFactorChallenge _self;
  final $Res Function(LoginTwoFactorChallenge) _then;

/// Create a copy of LoginTwoFactorChallenge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,Object? requires2FA = null,Object? additionalProperties = null,}) {
  return _then(LoginTwoFactorChallenge(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,requires2FA: null == requires2FA ? _self.requires2FA : requires2FA // ignore: cast_nullable_to_non_nullable
as LoginTwoFactorChallengeRequires2FA,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [LoginTwoFactorChallenge].
extension LoginTwoFactorChallengePatterns on LoginTwoFactorChallenge {
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
