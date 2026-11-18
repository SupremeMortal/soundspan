// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discover_alias_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiscoverAliasInfo {


/// Create a copy of DiscoverAliasInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscoverAliasInfoCopyWith<DiscoverAliasInfo> get copyWith => _$DiscoverAliasInfoCopyWithImpl<DiscoverAliasInfo>(this as DiscoverAliasInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DiscoverAliasInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscoverAliasInfo&&(identical(other.canonical, _this.canonical) || other.canonical == _this.canonical)&&(identical(other.mbid, _this.mbid) || other.mbid == _this.mbid)&&(identical(other.original, _this.original) || other.original == _this.original)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as DiscoverAliasInfo;
  return Object.hash(runtimeType,_this.canonical,_this.mbid,_this.original,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as DiscoverAliasInfo;
  return 'DiscoverAliasInfo(canonical: ${_this.canonical}, mbid: ${_this.mbid}, original: ${_this.original}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $DiscoverAliasInfoCopyWith<$Res>  {
  factory $DiscoverAliasInfoCopyWith(DiscoverAliasInfo value, $Res Function(DiscoverAliasInfo) _then) = _$DiscoverAliasInfoCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String canonical,@JsonKey(disallowNullValue: true, includeIfNull: false) String? mbid,@JsonKey(required: true, disallowNullValue: true) String original,@JsonKey(readValue: DiscoverAliasInfo._extras, fromJson: DiscoverAliasInfo._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$DiscoverAliasInfoCopyWithImpl<$Res>
    implements $DiscoverAliasInfoCopyWith<$Res> {
  _$DiscoverAliasInfoCopyWithImpl(this._self, this._then);

  final DiscoverAliasInfo _self;
  final $Res Function(DiscoverAliasInfo) _then;

/// Create a copy of DiscoverAliasInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? canonical = null,Object? mbid = freezed,Object? original = null,Object? additionalProperties = null,}) {
  return _then(DiscoverAliasInfo(
canonical: null == canonical ? _self.canonical : canonical // ignore: cast_nullable_to_non_nullable
as String,mbid: freezed == mbid ? _self.mbid : mbid // ignore: cast_nullable_to_non_nullable
as String?,original: null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [DiscoverAliasInfo].
extension DiscoverAliasInfoPatterns on DiscoverAliasInfo {
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
