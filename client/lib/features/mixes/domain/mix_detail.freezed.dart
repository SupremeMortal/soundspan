// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mix_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MixDetail {

/// The server's mix id.
 String get id;/// The mix name.
 String get name;/// The mix description; null when the server sends none.
 String? get description;/// Values to pass to the cover-art endpoint; the first four make the
/// mosaic.
 List<String> get artworkRefs;/// The tracks in server order; a track without a `playbackId` is not
/// playable.
 List<Track> get tracks;
/// Create a copy of MixDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MixDetailCopyWith<MixDetail> get copyWith => _$MixDetailCopyWithImpl<MixDetail>(this as MixDetail, _$identity);

  /// Serializes this MixDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MixDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MixDetail&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&const DeepCollectionEquality().equals(other.artworkRefs, _this.artworkRefs)&&const DeepCollectionEquality().equals(other.tracks, _this.tracks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MixDetail;
  return Object.hash(runtimeType,_this.id,_this.name,_this.description,const DeepCollectionEquality().hash(_this.artworkRefs),const DeepCollectionEquality().hash(_this.tracks));
}

@override
String toString() {
  final _this = this as MixDetail;
  return 'MixDetail(id: ${_this.id}, name: ${_this.name}, description: ${_this.description}, artworkRefs: ${_this.artworkRefs}, tracks: ${_this.tracks})';
}


}

/// @nodoc
abstract mixin class $MixDetailCopyWith<$Res>  {
  factory $MixDetailCopyWith(MixDetail value, $Res Function(MixDetail) _then) = _$MixDetailCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description, List<String> artworkRefs, List<Track> tracks
});




}
/// @nodoc
class _$MixDetailCopyWithImpl<$Res>
    implements $MixDetailCopyWith<$Res> {
  _$MixDetailCopyWithImpl(this._self, this._then);

  final MixDetail _self;
  final $Res Function(MixDetail) _then;

/// Create a copy of MixDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? artworkRefs = null,Object? tracks = null,}) {
  return _then(MixDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,artworkRefs: null == artworkRefs ? _self.artworkRefs : artworkRefs // ignore: cast_nullable_to_non_nullable
as List<String>,tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,
  ));
}

}


/// Adds pattern-matching-related methods to [MixDetail].
extension MixDetailPatterns on MixDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MixDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MixDetail() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MixDetail value)  $default,){
final _that = this;
switch (_that) {
case _MixDetail():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MixDetail value)?  $default,){
final _that = this;
switch (_that) {
case _MixDetail() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  List<String> artworkRefs,  List<Track> tracks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MixDetail() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.artworkRefs,_that.tracks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  List<String> artworkRefs,  List<Track> tracks)  $default,) {final _that = this;
switch (_that) {
case _MixDetail():
return $default(_that.id,_that.name,_that.description,_that.artworkRefs,_that.tracks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description,  List<String> artworkRefs,  List<Track> tracks)?  $default,) {final _that = this;
switch (_that) {
case _MixDetail() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.artworkRefs,_that.tracks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MixDetail implements MixDetail {
  const _MixDetail({required this.id, required this.name, this.description,  List<String> artworkRefs = const <String>[],  List<Track> tracks = const <Track>[]}): _artworkRefs = artworkRefs,_tracks = tracks;
  factory _MixDetail.fromJson(Map<String, dynamic> json) => _$MixDetailFromJson(json);

/// The server's mix id.
@override final  String id;
/// The mix name.
@override final  String name;
/// The mix description; null when the server sends none.
@override final  String? description;
/// Values to pass to the cover-art endpoint; the first four make the
/// mosaic.
 final  List<String> _artworkRefs;
/// Values to pass to the cover-art endpoint; the first four make the
/// mosaic.
@override@JsonKey() List<String> get artworkRefs {
  if (_artworkRefs is EqualUnmodifiableListView) return _artworkRefs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artworkRefs);
}

/// The tracks in server order; a track without a `playbackId` is not
/// playable.
 final  List<Track> _tracks;
/// The tracks in server order; a track without a `playbackId` is not
/// playable.
@override@JsonKey() List<Track> get tracks {
  if (_tracks is EqualUnmodifiableListView) return _tracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tracks);
}


/// Create a copy of MixDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MixDetailCopyWith<_MixDetail> get copyWith => __$MixDetailCopyWithImpl<_MixDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MixDetailToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MixDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.artworkRefs, _artworkRefs)&&const DeepCollectionEquality().equals(other.tracks, _tracks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,description,const DeepCollectionEquality().hash(_artworkRefs),const DeepCollectionEquality().hash(_tracks));
}

@override
String toString() {
    return 'MixDetail(id: $id, name: $name, description: $description, artworkRefs: $artworkRefs, tracks: $tracks)';
}


}

/// @nodoc
abstract mixin class _$MixDetailCopyWith<$Res> implements $MixDetailCopyWith<$Res> {
  factory _$MixDetailCopyWith(_MixDetail value, $Res Function(_MixDetail) _then) = __$MixDetailCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description, List<String> artworkRefs, List<Track> tracks
});




}
/// @nodoc
class __$MixDetailCopyWithImpl<$Res>
    implements _$MixDetailCopyWith<$Res> {
  __$MixDetailCopyWithImpl(this._self, this._then);

  final _MixDetail _self;
  final $Res Function(_MixDetail) _then;

/// Create a copy of MixDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? artworkRefs = null,Object? tracks = null,}) {
  return _then(_MixDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,artworkRefs: null == artworkRefs ? _self._artworkRefs : artworkRefs // ignore: cast_nullable_to_non_nullable
as List<String>,tracks: null == tracks ? _self._tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,
  ));
}


}

// dart format on
