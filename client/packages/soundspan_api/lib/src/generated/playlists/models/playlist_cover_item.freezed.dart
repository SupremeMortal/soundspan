// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist_cover_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaylistCoverItem {


/// Create a copy of PlaylistCoverItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistCoverItemCopyWith<PlaylistCoverItem> get copyWith => _$PlaylistCoverItemCopyWithImpl<PlaylistCoverItem>(this as PlaylistCoverItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlaylistCoverItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistCoverItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.track, _this.track) || other.track == _this.track)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as PlaylistCoverItem;
  return Object.hash(runtimeType,_this.id,_this.track,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as PlaylistCoverItem;
  return 'PlaylistCoverItem(id: ${_this.id}, track: ${_this.track}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $PlaylistCoverItemCopyWith<$Res>  {
  factory $PlaylistCoverItemCopyWith(PlaylistCoverItem value, $Res Function(PlaylistCoverItem) _then) = _$PlaylistCoverItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true) PlaylistCoverItemTrack? track,@JsonKey(readValue: PlaylistCoverItem._extras, fromJson: PlaylistCoverItem._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$PlaylistCoverItemTrackCopyWith<$Res>? get track;

}
/// @nodoc
class _$PlaylistCoverItemCopyWithImpl<$Res>
    implements $PlaylistCoverItemCopyWith<$Res> {
  _$PlaylistCoverItemCopyWithImpl(this._self, this._then);

  final PlaylistCoverItem _self;
  final $Res Function(PlaylistCoverItem) _then;

/// Create a copy of PlaylistCoverItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? track = freezed,Object? additionalProperties = null,}) {
  return _then(PlaylistCoverItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,track: freezed == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as PlaylistCoverItemTrack?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of PlaylistCoverItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaylistCoverItemTrackCopyWith<$Res>? get track {
    if (_self.track == null) {
    return null;
  }

  return $PlaylistCoverItemTrackCopyWith<$Res>(_self.track!, (value) {
    return _then(_self.copyWith(track: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlaylistCoverItem].
extension PlaylistCoverItemPatterns on PlaylistCoverItem {
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
