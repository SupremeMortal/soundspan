// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_playlist_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UpdatePlaylistRequest {


/// Create a copy of UpdatePlaylistRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdatePlaylistRequestCopyWith<UpdatePlaylistRequest> get copyWith => _$UpdatePlaylistRequestCopyWithImpl<UpdatePlaylistRequest>(this as UpdatePlaylistRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UpdatePlaylistRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdatePlaylistRequest&&(identical(other.isPublic, _this.isPublic) || other.isPublic == _this.isPublic)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as UpdatePlaylistRequest;
  return Object.hash(runtimeType,_this.isPublic,_this.name,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as UpdatePlaylistRequest;
  return 'UpdatePlaylistRequest(isPublic: ${_this.isPublic}, name: ${_this.name}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $UpdatePlaylistRequestCopyWith<$Res>  {
  factory $UpdatePlaylistRequestCopyWith(UpdatePlaylistRequest value, $Res Function(UpdatePlaylistRequest) _then) = _$UpdatePlaylistRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(disallowNullValue: true, includeIfNull: false) bool? isPublic,@JsonKey(disallowNullValue: true, includeIfNull: false) String? name,@JsonKey(readValue: UpdatePlaylistRequest._extras, fromJson: UpdatePlaylistRequest._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$UpdatePlaylistRequestCopyWithImpl<$Res>
    implements $UpdatePlaylistRequestCopyWith<$Res> {
  _$UpdatePlaylistRequestCopyWithImpl(this._self, this._then);

  final UpdatePlaylistRequest _self;
  final $Res Function(UpdatePlaylistRequest) _then;

/// Create a copy of UpdatePlaylistRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isPublic = freezed,Object? name = freezed,Object? additionalProperties = null,}) {
  return _then(UpdatePlaylistRequest(
isPublic: freezed == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdatePlaylistRequest].
extension UpdatePlaylistRequestPatterns on UpdatePlaylistRequest {
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
