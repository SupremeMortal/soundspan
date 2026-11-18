// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response200.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginTokenResponse _$LoginTokenResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['refreshToken', 'token', 'user'],
    disallowNullValues: const ['refreshToken', 'token', 'user'],
  );
  return LoginTokenResponse(
    refreshToken: json['refreshToken'] as String,
    token: json['token'] as String,
    user: LoginUser.fromJson(json['user'] as Map<String, dynamic>),
    additionalProperties:
        LoginTokenResponse._extras(json, 'additionalProperties') == null
        ? const {}
        : LoginTokenResponse._readExtras(
            LoginTokenResponse._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$LoginTokenResponseToJson(LoginTokenResponse instance) =>
    <String, dynamic>{
      'refreshToken': instance.refreshToken,
      'token': instance.token,
      'user': instance.user.toJson(),
    };

LoginTwoFactorChallenge _$LoginTwoFactorChallengeFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['message', 'requires2FA'],
    disallowNullValues: const ['message', 'requires2FA'],
  );
  return LoginTwoFactorChallenge(
    message: json['message'] as String,
    requires2FA: LoginTwoFactorChallenge._read_requires2FA(json['requires2FA']),
    additionalProperties:
        LoginTwoFactorChallenge._extras(json, 'additionalProperties') == null
        ? const {}
        : LoginTwoFactorChallenge._readExtras(
            LoginTwoFactorChallenge._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$LoginTwoFactorChallengeToJson(
  LoginTwoFactorChallenge instance,
) => <String, dynamic>{
  'message': instance.message,
  'requires2FA': ?LoginTwoFactorChallenge._write_requires2FA(
    instance.requires2FA,
  ),
};
