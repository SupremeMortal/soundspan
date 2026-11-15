// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'online_user_track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnlineUserTrack {


/// Create a copy of OnlineUserTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnlineUserTrackCopyWith<OnlineUserTrack> get copyWith => _$OnlineUserTrackCopyWithImpl<OnlineUserTrack>(this as OnlineUserTrack, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OnlineUserTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnlineUserTrack&&(identical(other.albumId, _this.albumId) || other.albumId == _this.albumId)&&(identical(other.albumTitle, _this.albumTitle) || other.albumTitle == _this.albumTitle)&&(identical(other.artistId, _this.artistId) || other.artistId == _this.artistId)&&(identical(other.artistName, _this.artistName) || other.artistName == _this.artistName)&&(identical(other.coverArt, _this.coverArt) || other.coverArt == _this.coverArt)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as OnlineUserTrack;
  return Object.hash(runtimeType,_this.albumId,_this.albumTitle,_this.artistId,_this.artistName,_this.coverArt,_this.duration,_this.id,_this.playbackId,_this.title,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as OnlineUserTrack;
  return 'OnlineUserTrack(albumId: ${_this.albumId}, albumTitle: ${_this.albumTitle}, artistId: ${_this.artistId}, artistName: ${_this.artistName}, coverArt: ${_this.coverArt}, duration: ${_this.duration}, id: ${_this.id}, playbackId: ${_this.playbackId}, title: ${_this.title}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $OnlineUserTrackCopyWith<$Res>  {
  factory $OnlineUserTrackCopyWith(OnlineUserTrack value, $Res Function(OnlineUserTrack) _then) = _$OnlineUserTrackCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true) String? albumId,@JsonKey(required: true, disallowNullValue: true) String albumTitle,@JsonKey(required: true) String? artistId,@JsonKey(required: true, disallowNullValue: true) String artistName,@JsonKey(required: true) String? coverArt,@JsonKey(required: true, disallowNullValue: true) num duration,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(disallowNullValue: true, includeIfNull: false) String? playbackId,@JsonKey(required: true, disallowNullValue: true) String title,@JsonKey(readValue: OnlineUserTrack._extras, fromJson: OnlineUserTrack._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$OnlineUserTrackCopyWithImpl<$Res>
    implements $OnlineUserTrackCopyWith<$Res> {
  _$OnlineUserTrackCopyWithImpl(this._self, this._then);

  final OnlineUserTrack _self;
  final $Res Function(OnlineUserTrack) _then;

/// Create a copy of OnlineUserTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? albumId = freezed,Object? albumTitle = null,Object? artistId = freezed,Object? artistName = null,Object? coverArt = freezed,Object? duration = null,Object? id = null,Object? playbackId = freezed,Object? title = null,Object? additionalProperties = null,}) {
  return _then(OnlineUserTrack(
albumId: freezed == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as String?,albumTitle: null == albumTitle ? _self.albumTitle : albumTitle // ignore: cast_nullable_to_non_nullable
as String,artistId: freezed == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as String?,artistName: null == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String,coverArt: freezed == coverArt ? _self.coverArt : coverArt // ignore: cast_nullable_to_non_nullable
as String?,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as num,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,playbackId: freezed == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [OnlineUserTrack].
extension OnlineUserTrackPatterns on OnlineUserTrack {
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
