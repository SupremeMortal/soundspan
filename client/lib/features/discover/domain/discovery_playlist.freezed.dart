// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discovery_playlist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DiscoveryPlaylist {

/// The tracks, in server order; at least one.
 List<Track> get tracks;
/// Create a copy of DiscoveryPlaylist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscoveryPlaylistCopyWith<DiscoveryPlaylist> get copyWith => _$DiscoveryPlaylistCopyWithImpl<DiscoveryPlaylist>(this as DiscoveryPlaylist, _$identity);

  /// Serializes this DiscoveryPlaylist to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DiscoveryPlaylist;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscoveryPlaylist&&const DeepCollectionEquality().equals(other.tracks, _this.tracks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DiscoveryPlaylist;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.tracks));
}

@override
String toString() {
  final _this = this as DiscoveryPlaylist;
  return 'DiscoveryPlaylist(tracks: ${_this.tracks})';
}


}

/// @nodoc
abstract mixin class $DiscoveryPlaylistCopyWith<$Res>  {
  factory $DiscoveryPlaylistCopyWith(DiscoveryPlaylist value, $Res Function(DiscoveryPlaylist) _then) = _$DiscoveryPlaylistCopyWithImpl;
@useResult
$Res call({
 List<Track> tracks
});




}
/// @nodoc
class _$DiscoveryPlaylistCopyWithImpl<$Res>
    implements $DiscoveryPlaylistCopyWith<$Res> {
  _$DiscoveryPlaylistCopyWithImpl(this._self, this._then);

  final DiscoveryPlaylist _self;
  final $Res Function(DiscoveryPlaylist) _then;

/// Create a copy of DiscoveryPlaylist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tracks = null,}) {
  return _then(DiscoveryPlaylist(
tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,
  ));
}

}


/// Adds pattern-matching-related methods to [DiscoveryPlaylist].
extension DiscoveryPlaylistPatterns on DiscoveryPlaylist {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiscoveryPlaylist value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiscoveryPlaylist() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiscoveryPlaylist value)  $default,){
final _that = this;
switch (_that) {
case _DiscoveryPlaylist():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiscoveryPlaylist value)?  $default,){
final _that = this;
switch (_that) {
case _DiscoveryPlaylist() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Track> tracks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiscoveryPlaylist() when $default != null:
return $default(_that.tracks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Track> tracks)  $default,) {final _that = this;
switch (_that) {
case _DiscoveryPlaylist():
return $default(_that.tracks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Track> tracks)?  $default,) {final _that = this;
switch (_that) {
case _DiscoveryPlaylist() when $default != null:
return $default(_that.tracks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DiscoveryPlaylist implements DiscoveryPlaylist {
  const _DiscoveryPlaylist({required  List<Track> tracks}): _tracks = tracks;
  factory _DiscoveryPlaylist.fromJson(Map<String, dynamic> json) => _$DiscoveryPlaylistFromJson(json);

/// The tracks, in server order; at least one.
 final  List<Track> _tracks;
/// The tracks, in server order; at least one.
@override List<Track> get tracks {
  if (_tracks is EqualUnmodifiableListView) return _tracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tracks);
}


/// Create a copy of DiscoveryPlaylist
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiscoveryPlaylistCopyWith<_DiscoveryPlaylist> get copyWith => __$DiscoveryPlaylistCopyWithImpl<_DiscoveryPlaylist>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DiscoveryPlaylistToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiscoveryPlaylist&&const DeepCollectionEquality().equals(other.tracks, _tracks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_tracks));
}

@override
String toString() {
    return 'DiscoveryPlaylist(tracks: $tracks)';
}


}

/// @nodoc
abstract mixin class _$DiscoveryPlaylistCopyWith<$Res> implements $DiscoveryPlaylistCopyWith<$Res> {
  factory _$DiscoveryPlaylistCopyWith(_DiscoveryPlaylist value, $Res Function(_DiscoveryPlaylist) _then) = __$DiscoveryPlaylistCopyWithImpl;
@override @useResult
$Res call({
 List<Track> tracks
});




}
/// @nodoc
class __$DiscoveryPlaylistCopyWithImpl<$Res>
    implements _$DiscoveryPlaylistCopyWith<$Res> {
  __$DiscoveryPlaylistCopyWithImpl(this._self, this._then);

  final _DiscoveryPlaylist _self;
  final $Res Function(_DiscoveryPlaylist) _then;

/// Create a copy of DiscoveryPlaylist
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tracks = null,}) {
  return _then(_DiscoveryPlaylist(
tracks: null == tracks ? _self._tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,
  ));
}


}

// dart format on
