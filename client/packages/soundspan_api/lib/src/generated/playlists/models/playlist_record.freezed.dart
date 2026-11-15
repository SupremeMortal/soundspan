// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaylistRecord {


/// Create a copy of PlaylistRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistRecordCopyWith<PlaylistRecord> get copyWith => _$PlaylistRecordCopyWithImpl<PlaylistRecord>(this as PlaylistRecord, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlaylistRecord;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistRecord&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.isPublic, _this.isPublic) || other.isPublic == _this.isPublic)&&(identical(other.mixId, _this.mixId) || other.mixId == _this.mixId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.spotifyPlaylistId, _this.spotifyPlaylistId) || other.spotifyPlaylistId == _this.spotifyPlaylistId)&&(identical(other.spotifyPlaylistUrl, _this.spotifyPlaylistUrl) || other.spotifyPlaylistUrl == _this.spotifyPlaylistUrl)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as PlaylistRecord;
  return Object.hash(runtimeType,_this.createdAt,_this.id,_this.isPublic,_this.mixId,_this.name,_this.spotifyPlaylistId,_this.spotifyPlaylistUrl,_this.updatedAt,_this.userId,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as PlaylistRecord;
  return 'PlaylistRecord(createdAt: ${_this.createdAt}, id: ${_this.id}, isPublic: ${_this.isPublic}, mixId: ${_this.mixId}, name: ${_this.name}, spotifyPlaylistId: ${_this.spotifyPlaylistId}, spotifyPlaylistUrl: ${_this.spotifyPlaylistUrl}, updatedAt: ${_this.updatedAt}, userId: ${_this.userId}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $PlaylistRecordCopyWith<$Res>  {
  factory $PlaylistRecordCopyWith(PlaylistRecord value, $Res Function(PlaylistRecord) _then) = _$PlaylistRecordCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true, fromJson: PlaylistRecord._read_createdAt, toJson: PlaylistRecord._write_createdAt) DateTime createdAt,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true, disallowNullValue: true) bool isPublic,@JsonKey(required: true) String? mixId,@JsonKey(required: true, disallowNullValue: true) String name,@JsonKey(required: true) String? spotifyPlaylistId,@JsonKey(required: true) String? spotifyPlaylistUrl,@JsonKey(required: true, disallowNullValue: true, fromJson: PlaylistRecord._read_updatedAt, toJson: PlaylistRecord._write_updatedAt) DateTime updatedAt,@JsonKey(required: true, disallowNullValue: true) String userId,@JsonKey(readValue: PlaylistRecord._extras, fromJson: PlaylistRecord._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$PlaylistRecordCopyWithImpl<$Res>
    implements $PlaylistRecordCopyWith<$Res> {
  _$PlaylistRecordCopyWithImpl(this._self, this._then);

  final PlaylistRecord _self;
  final $Res Function(PlaylistRecord) _then;

/// Create a copy of PlaylistRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? createdAt = null,Object? id = null,Object? isPublic = null,Object? mixId = freezed,Object? name = null,Object? spotifyPlaylistId = freezed,Object? spotifyPlaylistUrl = freezed,Object? updatedAt = null,Object? userId = null,Object? additionalProperties = null,}) {
  return _then(PlaylistRecord(
createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,mixId: freezed == mixId ? _self.mixId : mixId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,spotifyPlaylistId: freezed == spotifyPlaylistId ? _self.spotifyPlaylistId : spotifyPlaylistId // ignore: cast_nullable_to_non_nullable
as String?,spotifyPlaylistUrl: freezed == spotifyPlaylistUrl ? _self.spotifyPlaylistUrl : spotifyPlaylistUrl // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaylistRecord].
extension PlaylistRecordPatterns on PlaylistRecord {
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
