// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserSettings {


/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserSettingsCopyWith<UserSettings> get copyWith => _$UserSettingsCopyWithImpl<UserSettings>(this as UserSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UserSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserSettings&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.hasProfilePicture, _this.hasProfilePicture) || other.hasProfilePicture == _this.hasProfilePicture)&&(identical(other.loudnessMode, _this.loudnessMode) || other.loudnessMode == _this.loudnessMode)&&(identical(other.maxCacheSizeMb, _this.maxCacheSizeMb) || other.maxCacheSizeMb == _this.maxCacheSizeMb)&&(identical(other.offlineEnabled, _this.offlineEnabled) || other.offlineEnabled == _this.offlineEnabled)&&(identical(other.playbackQuality, _this.playbackQuality) || other.playbackQuality == _this.playbackQuality)&&(identical(other.shareListeningStatus, _this.shareListeningStatus) || other.shareListeningStatus == _this.shareListeningStatus)&&(identical(other.shareOnlinePresence, _this.shareOnlinePresence) || other.shareOnlinePresence == _this.shareOnlinePresence)&&(identical(other.showTidalExplore, _this.showTidalExplore) || other.showTidalExplore == _this.showTidalExplore)&&(identical(other.showYtMusicExplore, _this.showYtMusicExplore) || other.showYtMusicExplore == _this.showYtMusicExplore)&&(identical(other.tidalStreamingQuality, _this.tidalStreamingQuality) || other.tidalStreamingQuality == _this.tidalStreamingQuality)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.wifiOnly, _this.wifiOnly) || other.wifiOnly == _this.wifiOnly)&&(identical(other.ytMusicQuality, _this.ytMusicQuality) || other.ytMusicQuality == _this.ytMusicQuality)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as UserSettings;
  return Object.hash(runtimeType,_this.displayName,_this.hasProfilePicture,_this.loudnessMode,_this.maxCacheSizeMb,_this.offlineEnabled,_this.playbackQuality,_this.shareListeningStatus,_this.shareOnlinePresence,_this.showTidalExplore,_this.showYtMusicExplore,_this.tidalStreamingQuality,_this.userId,_this.wifiOnly,_this.ytMusicQuality,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as UserSettings;
  return 'UserSettings(displayName: ${_this.displayName}, hasProfilePicture: ${_this.hasProfilePicture}, loudnessMode: ${_this.loudnessMode}, maxCacheSizeMb: ${_this.maxCacheSizeMb}, offlineEnabled: ${_this.offlineEnabled}, playbackQuality: ${_this.playbackQuality}, shareListeningStatus: ${_this.shareListeningStatus}, shareOnlinePresence: ${_this.shareOnlinePresence}, showTidalExplore: ${_this.showTidalExplore}, showYtMusicExplore: ${_this.showYtMusicExplore}, tidalStreamingQuality: ${_this.tidalStreamingQuality}, userId: ${_this.userId}, wifiOnly: ${_this.wifiOnly}, ytMusicQuality: ${_this.ytMusicQuality}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $UserSettingsCopyWith<$Res>  {
  factory $UserSettingsCopyWith(UserSettings value, $Res Function(UserSettings) _then) = _$UserSettingsCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true) String? displayName,@JsonKey(disallowNullValue: true, includeIfNull: false) bool? hasProfilePicture,@JsonKey(required: true, disallowNullValue: true, fromJson: UserSettings._read_loudnessMode, toJson: UserSettings._write_loudnessMode) LoudnessMode loudnessMode,@JsonKey(required: true, disallowNullValue: true, fromJson: UserSettings._read_maxCacheSizeMb, toJson: UserSettings._write_maxCacheSizeMb) int maxCacheSizeMb,@JsonKey(required: true, disallowNullValue: true) bool offlineEnabled,@JsonKey(required: true, disallowNullValue: true, fromJson: UserSettings._read_playbackQuality, toJson: UserSettings._write_playbackQuality) PlaybackQuality playbackQuality,@JsonKey(required: true, disallowNullValue: true) bool shareListeningStatus,@JsonKey(required: true, disallowNullValue: true) bool shareOnlinePresence,@JsonKey(required: true, disallowNullValue: true) bool showTidalExplore,@JsonKey(required: true, disallowNullValue: true) bool showYtMusicExplore,@JsonKey(required: true, disallowNullValue: true) String tidalStreamingQuality,@JsonKey(required: true, disallowNullValue: true) String userId,@JsonKey(required: true, disallowNullValue: true) bool wifiOnly,@JsonKey(required: true, disallowNullValue: true) String ytMusicQuality,@JsonKey(readValue: UserSettings._extras, fromJson: UserSettings._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$UserSettingsCopyWithImpl<$Res>
    implements $UserSettingsCopyWith<$Res> {
  _$UserSettingsCopyWithImpl(this._self, this._then);

  final UserSettings _self;
  final $Res Function(UserSettings) _then;

/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayName = freezed,Object? hasProfilePicture = freezed,Object? loudnessMode = null,Object? maxCacheSizeMb = null,Object? offlineEnabled = null,Object? playbackQuality = null,Object? shareListeningStatus = null,Object? shareOnlinePresence = null,Object? showTidalExplore = null,Object? showYtMusicExplore = null,Object? tidalStreamingQuality = null,Object? userId = null,Object? wifiOnly = null,Object? ytMusicQuality = null,Object? additionalProperties = null,}) {
  return _then(UserSettings(
displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,hasProfilePicture: freezed == hasProfilePicture ? _self.hasProfilePicture : hasProfilePicture // ignore: cast_nullable_to_non_nullable
as bool?,loudnessMode: null == loudnessMode ? _self.loudnessMode : loudnessMode // ignore: cast_nullable_to_non_nullable
as LoudnessMode,maxCacheSizeMb: null == maxCacheSizeMb ? _self.maxCacheSizeMb : maxCacheSizeMb // ignore: cast_nullable_to_non_nullable
as int,offlineEnabled: null == offlineEnabled ? _self.offlineEnabled : offlineEnabled // ignore: cast_nullable_to_non_nullable
as bool,playbackQuality: null == playbackQuality ? _self.playbackQuality : playbackQuality // ignore: cast_nullable_to_non_nullable
as PlaybackQuality,shareListeningStatus: null == shareListeningStatus ? _self.shareListeningStatus : shareListeningStatus // ignore: cast_nullable_to_non_nullable
as bool,shareOnlinePresence: null == shareOnlinePresence ? _self.shareOnlinePresence : shareOnlinePresence // ignore: cast_nullable_to_non_nullable
as bool,showTidalExplore: null == showTidalExplore ? _self.showTidalExplore : showTidalExplore // ignore: cast_nullable_to_non_nullable
as bool,showYtMusicExplore: null == showYtMusicExplore ? _self.showYtMusicExplore : showYtMusicExplore // ignore: cast_nullable_to_non_nullable
as bool,tidalStreamingQuality: null == tidalStreamingQuality ? _self.tidalStreamingQuality : tidalStreamingQuality // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,wifiOnly: null == wifiOnly ? _self.wifiOnly : wifiOnly // ignore: cast_nullable_to_non_nullable
as bool,ytMusicQuality: null == ytMusicQuality ? _self.ytMusicQuality : ytMusicQuality // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [UserSettings].
extension UserSettingsPatterns on UserSettings {
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
