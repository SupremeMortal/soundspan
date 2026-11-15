// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'listen_queue_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ListenQueueItem {


/// Create a copy of ListenQueueItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListenQueueItemCopyWith<ListenQueueItem> get copyWith => _$ListenQueueItemCopyWithImpl<ListenQueueItem>(this as ListenQueueItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ListenQueueItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListenQueueItem&&(identical(other.album, _this.album) || other.album == _this.album)&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.playbackId, _this.playbackId) || other.playbackId == _this.playbackId)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as ListenQueueItem;
  return Object.hash(runtimeType,_this.album,_this.artist,_this.duration,_this.id,_this.playbackId,_this.title,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as ListenQueueItem;
  return 'ListenQueueItem(album: ${_this.album}, artist: ${_this.artist}, duration: ${_this.duration}, id: ${_this.id}, playbackId: ${_this.playbackId}, title: ${_this.title}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $ListenQueueItemCopyWith<$Res>  {
  factory $ListenQueueItemCopyWith(ListenQueueItem value, $Res Function(ListenQueueItem) _then) = _$ListenQueueItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) ListenQueueItemAlbum album,@JsonKey(required: true, disallowNullValue: true) ListenQueueItemArtist artist,@JsonKey(required: true, disallowNullValue: true, fromJson: ListenQueueItem._read_duration, toJson: ListenQueueItem._write_duration) int duration,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(disallowNullValue: true, includeIfNull: false) String? playbackId,@JsonKey(required: true, disallowNullValue: true) String title,@JsonKey(readValue: ListenQueueItem._extras, fromJson: ListenQueueItem._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$ListenQueueItemAlbumCopyWith<$Res> get album;$ListenQueueItemArtistCopyWith<$Res> get artist;

}
/// @nodoc
class _$ListenQueueItemCopyWithImpl<$Res>
    implements $ListenQueueItemCopyWith<$Res> {
  _$ListenQueueItemCopyWithImpl(this._self, this._then);

  final ListenQueueItem _self;
  final $Res Function(ListenQueueItem) _then;

/// Create a copy of ListenQueueItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? album = null,Object? artist = null,Object? duration = null,Object? id = null,Object? playbackId = freezed,Object? title = null,Object? additionalProperties = null,}) {
  return _then(ListenQueueItem(
album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as ListenQueueItemAlbum,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as ListenQueueItemArtist,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,playbackId: freezed == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of ListenQueueItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ListenQueueItemAlbumCopyWith<$Res> get album {
  
  return $ListenQueueItemAlbumCopyWith<$Res>(_self.album, (value) {
    return _then(_self.copyWith(album: value));
  });
}/// Create a copy of ListenQueueItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ListenQueueItemArtistCopyWith<$Res> get artist {
  
  return $ListenQueueItemArtistCopyWith<$Res>(_self.artist, (value) {
    return _then(_self.copyWith(artist: value));
  });
}
}


/// Adds pattern-matching-related methods to [ListenQueueItem].
extension ListenQueueItemPatterns on ListenQueueItem {
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
