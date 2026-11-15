// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendations_for_you.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecommendationsForYou _$RecommendationsForYouFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['artists'],
    disallowNullValues: const ['artists'],
  );
  return RecommendationsForYou(
    artists: (json['artists'] as List<dynamic>)
        .map((e) => RecommendedArtist.fromJson(e as Map<String, dynamic>))
        .toList(),
    additionalProperties:
        RecommendationsForYou._extras(json, 'additionalProperties') == null
        ? const {}
        : RecommendationsForYou._readExtras(
            RecommendationsForYou._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$RecommendationsForYouToJson(
  RecommendationsForYou instance,
) => <String, dynamic>{
  'artists': instance.artists.map((e) => e.toJson()).toList(),
};
