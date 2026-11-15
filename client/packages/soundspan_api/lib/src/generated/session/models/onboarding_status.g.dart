// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OnboardingStatus _$OnboardingStatusFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['hasAccount', 'needsOnboarding'],
    disallowNullValues: const ['hasAccount', 'needsOnboarding'],
  );
  return OnboardingStatus(
    hasAccount: json['hasAccount'] as bool,
    needsOnboarding: json['needsOnboarding'] as bool,
    additionalProperties:
        OnboardingStatus._extras(json, 'additionalProperties') == null
        ? const {}
        : OnboardingStatus._readExtras(
            OnboardingStatus._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$OnboardingStatusToJson(OnboardingStatus instance) =>
    <String, dynamic>{
      'hasAccount': instance.hasAccount,
      'needsOnboarding': instance.needsOnboarding,
    };
