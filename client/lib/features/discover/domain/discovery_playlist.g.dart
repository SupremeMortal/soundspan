// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_playlist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DiscoveryPlaylist _$DiscoveryPlaylistFromJson(Map<String, dynamic> json) =>
    _DiscoveryPlaylist(
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DiscoveryPlaylistToJson(_DiscoveryPlaylist instance) =>
    <String, dynamic>{'tracks': instance.tracks};
