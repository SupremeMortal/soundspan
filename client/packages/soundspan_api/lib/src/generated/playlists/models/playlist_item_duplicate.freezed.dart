// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist_item_duplicate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaylistItemDuplicate {


/// Create a copy of PlaylistItemDuplicate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistItemDuplicateCopyWith<PlaylistItemDuplicate> get copyWith => _$PlaylistItemDuplicateCopyWithImpl<PlaylistItemDuplicate>(this as PlaylistItemDuplicate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlaylistItemDuplicate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistItemDuplicate&&(identical(other.duplicated, _this.duplicated) || other.duplicated == _this.duplicated)&&(identical(other.item, _this.item) || other.item == _this.item)&&(identical(other.message, _this.message) || other.message == _this.message)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as PlaylistItemDuplicate;
  return Object.hash(runtimeType,_this.duplicated,_this.item,_this.message,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as PlaylistItemDuplicate;
  return 'PlaylistItemDuplicate(duplicated: ${_this.duplicated}, item: ${_this.item}, message: ${_this.message}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $PlaylistItemDuplicateCopyWith<$Res>  {
  factory $PlaylistItemDuplicateCopyWith(PlaylistItemDuplicate value, $Res Function(PlaylistItemDuplicate) _then) = _$PlaylistItemDuplicateCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true, fromJson: PlaylistItemDuplicate._read_duplicated, toJson: PlaylistItemDuplicate._write_duplicated) PlaylistItemDuplicateDuplicated duplicated,@JsonKey(required: true, disallowNullValue: true) PlaylistItem item,@JsonKey(required: true, disallowNullValue: true) String message,@JsonKey(readValue: PlaylistItemDuplicate._extras, fromJson: PlaylistItemDuplicate._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$PlaylistItemCopyWith<$Res> get item;

}
/// @nodoc
class _$PlaylistItemDuplicateCopyWithImpl<$Res>
    implements $PlaylistItemDuplicateCopyWith<$Res> {
  _$PlaylistItemDuplicateCopyWithImpl(this._self, this._then);

  final PlaylistItemDuplicate _self;
  final $Res Function(PlaylistItemDuplicate) _then;

/// Create a copy of PlaylistItemDuplicate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? duplicated = null,Object? item = null,Object? message = null,Object? additionalProperties = null,}) {
  return _then(PlaylistItemDuplicate(
duplicated: null == duplicated ? _self.duplicated : duplicated // ignore: cast_nullable_to_non_nullable
as PlaylistItemDuplicateDuplicated,item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as PlaylistItem,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of PlaylistItemDuplicate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaylistItemCopyWith<$Res> get item {
  
  return $PlaylistItemCopyWith<$Res>(_self.item, (value) {
    return _then(_self.copyWith(item: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlaylistItemDuplicate].
extension PlaylistItemDuplicatePatterns on PlaylistItemDuplicate {
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
