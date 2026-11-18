// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listen_group_summary_current_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListenGroupSummaryCurrentTrack _$ListenGroupSummaryCurrentTrackFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['artistName', 'id', 'title'],
    disallowNullValues: const ['artistName', 'id', 'title'],
  );
  return ListenGroupSummaryCurrentTrack(
    artistName: json['artistName'] as String,
    id: json['id'] as String,
    title: json['title'] as String,
    additionalProperties:
        ListenGroupSummaryCurrentTrack._extras(json, 'additionalProperties') ==
            null
        ? const {}
        : ListenGroupSummaryCurrentTrack._readExtras(
            ListenGroupSummaryCurrentTrack._extras(
              json,
              'additionalProperties',
            ),
          ),
  );
}

Map<String, dynamic> _$ListenGroupSummaryCurrentTrackToJson(
  ListenGroupSummaryCurrentTrack instance,
) => <String, dynamic>{
  'artistName': instance.artistName,
  'id': instance.id,
  'title': instance.title,
};
