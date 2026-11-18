// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_artist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DiscoveryArtist _$DiscoveryArtistFromJson(Map<String, dynamic> json) =>
    _DiscoveryArtist(
      name: json['name'] as String,
      artworkRef: json['artworkRef'] as String?,
      libraryArtistId: json['libraryArtistId'] as String?,
    );

Map<String, dynamic> _$DiscoveryArtistToJson(_DiscoveryArtist instance) =>
    <String, dynamic>{
      'name': instance.name,
      'artworkRef': instance.artworkRef,
      'libraryArtistId': instance.libraryArtistId,
    };
