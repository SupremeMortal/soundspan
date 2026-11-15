// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'displayName',
      'loudnessMode',
      'maxCacheSizeMb',
      'offlineEnabled',
      'playbackQuality',
      'shareListeningStatus',
      'shareOnlinePresence',
      'showTidalExplore',
      'showYtMusicExplore',
      'tidalStreamingQuality',
      'userId',
      'wifiOnly',
      'ytMusicQuality',
    ],
    disallowNullValues: const [
      'hasProfilePicture',
      'loudnessMode',
      'maxCacheSizeMb',
      'offlineEnabled',
      'playbackQuality',
      'shareListeningStatus',
      'shareOnlinePresence',
      'showTidalExplore',
      'showYtMusicExplore',
      'tidalStreamingQuality',
      'userId',
      'wifiOnly',
      'ytMusicQuality',
    ],
  );
  return UserSettings(
    displayName: json['displayName'] as String?,
    hasProfilePicture: json['hasProfilePicture'] as bool?,
    loudnessMode: UserSettings._read_loudnessMode(json['loudnessMode']),
    maxCacheSizeMb: UserSettings._read_maxCacheSizeMb(json['maxCacheSizeMb']),
    offlineEnabled: json['offlineEnabled'] as bool,
    playbackQuality: UserSettings._read_playbackQuality(
      json['playbackQuality'],
    ),
    shareListeningStatus: json['shareListeningStatus'] as bool,
    shareOnlinePresence: json['shareOnlinePresence'] as bool,
    showTidalExplore: json['showTidalExplore'] as bool,
    showYtMusicExplore: json['showYtMusicExplore'] as bool,
    tidalStreamingQuality: json['tidalStreamingQuality'] as String,
    userId: json['userId'] as String,
    wifiOnly: json['wifiOnly'] as bool,
    ytMusicQuality: json['ytMusicQuality'] as String,
    additionalProperties:
        UserSettings._extras(json, 'additionalProperties') == null
        ? const {}
        : UserSettings._readExtras(
            UserSettings._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$UserSettingsToJson(UserSettings instance) =>
    <String, dynamic>{
      'displayName': instance.displayName,
      'hasProfilePicture': ?instance.hasProfilePicture,
      'loudnessMode': ?UserSettings._write_loudnessMode(instance.loudnessMode),
      'maxCacheSizeMb': ?UserSettings._write_maxCacheSizeMb(
        instance.maxCacheSizeMb,
      ),
      'offlineEnabled': instance.offlineEnabled,
      'playbackQuality': ?UserSettings._write_playbackQuality(
        instance.playbackQuality,
      ),
      'shareListeningStatus': instance.shareListeningStatus,
      'shareOnlinePresence': instance.shareOnlinePresence,
      'showTidalExplore': instance.showTidalExplore,
      'showYtMusicExplore': instance.showYtMusicExplore,
      'tidalStreamingQuality': instance.tidalStreamingQuality,
      'userId': instance.userId,
      'wifiOnly': instance.wifiOnly,
      'ytMusicQuality': instance.ytMusicQuality,
    };
