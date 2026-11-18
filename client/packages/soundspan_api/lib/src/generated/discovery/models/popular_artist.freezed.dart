// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'popular_artist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PopularArtist {


/// Create a copy of PopularArtist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PopularArtistCopyWith<PopularArtist> get copyWith => _$PopularArtistCopyWithImpl<PopularArtist>(this as PopularArtist, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PopularArtist;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PopularArtist&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.image, _this.image) || other.image == _this.image)&&(identical(other.listeners, _this.listeners) || other.listeners == _this.listeners)&&(identical(other.mbid, _this.mbid) || other.mbid == _this.mbid)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.playCount, _this.playCount) || other.playCount == _this.playCount)&&(identical(other.url, _this.url) || other.url == _this.url)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as PopularArtist;
  return Object.hash(runtimeType,_this.id,_this.image,_this.listeners,_this.mbid,_this.name,_this.playCount,_this.url,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as PopularArtist;
  return 'PopularArtist(id: ${_this.id}, image: ${_this.image}, listeners: ${_this.listeners}, mbid: ${_this.mbid}, name: ${_this.name}, playCount: ${_this.playCount}, url: ${_this.url}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $PopularArtistCopyWith<$Res>  {
  factory $PopularArtistCopyWith(PopularArtist value, $Res Function(PopularArtist) _then) = _$PopularArtistCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true) String? image,@JsonKey(required: true, disallowNullValue: true, fromJson: PopularArtist._read_listeners, toJson: PopularArtist._write_listeners) int listeners,@JsonKey(disallowNullValue: true, includeIfNull: false) String? mbid,@JsonKey(required: true, disallowNullValue: true) String name,@JsonKey(required: true, disallowNullValue: true, fromJson: PopularArtist._read_playCount, toJson: PopularArtist._write_playCount) int playCount,@JsonKey(disallowNullValue: true, includeIfNull: false) String? url,@JsonKey(readValue: PopularArtist._extras, fromJson: PopularArtist._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$PopularArtistCopyWithImpl<$Res>
    implements $PopularArtistCopyWith<$Res> {
  _$PopularArtistCopyWithImpl(this._self, this._then);

  final PopularArtist _self;
  final $Res Function(PopularArtist) _then;

/// Create a copy of PopularArtist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? image = freezed,Object? listeners = null,Object? mbid = freezed,Object? name = null,Object? playCount = null,Object? url = freezed,Object? additionalProperties = null,}) {
  return _then(PopularArtist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,listeners: null == listeners ? _self.listeners : listeners // ignore: cast_nullable_to_non_nullable
as int,mbid: freezed == mbid ? _self.mbid : mbid // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [PopularArtist].
extension PopularArtistPatterns on PopularArtist {
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
