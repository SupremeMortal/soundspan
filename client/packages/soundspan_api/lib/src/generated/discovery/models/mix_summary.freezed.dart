// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mix_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MixSummary {


/// Create a copy of MixSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MixSummaryCopyWith<MixSummary> get copyWith => _$MixSummaryCopyWithImpl<MixSummary>(this as MixSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MixSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MixSummary&&(identical(other.color, _this.color) || other.color == _this.color)&&const DeepCollectionEquality().equals(other.coverUrls, _this.coverUrls)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.trackCount, _this.trackCount) || other.trackCount == _this.trackCount)&&const DeepCollectionEquality().equals(other.trackIds, _this.trackIds)&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as MixSummary;
  return Object.hash(runtimeType,_this.color,const DeepCollectionEquality().hash(_this.coverUrls),_this.description,_this.id,_this.name,_this.trackCount,const DeepCollectionEquality().hash(_this.trackIds),_this.type,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as MixSummary;
  return 'MixSummary(color: ${_this.color}, coverUrls: ${_this.coverUrls}, description: ${_this.description}, id: ${_this.id}, name: ${_this.name}, trackCount: ${_this.trackCount}, trackIds: ${_this.trackIds}, type: ${_this.type}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $MixSummaryCopyWith<$Res>  {
  factory $MixSummaryCopyWith(MixSummary value, $Res Function(MixSummary) _then) = _$MixSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String color,@JsonKey(required: true, disallowNullValue: true) List<String> coverUrls,@JsonKey(required: true, disallowNullValue: true) String description,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true, disallowNullValue: true) String name,@JsonKey(required: true, disallowNullValue: true, fromJson: MixSummary._read_trackCount, toJson: MixSummary._write_trackCount) int trackCount,@JsonKey(required: true, disallowNullValue: true) List<String> trackIds,@JsonKey(required: true, disallowNullValue: true) String type,@JsonKey(readValue: MixSummary._extras, fromJson: MixSummary._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$MixSummaryCopyWithImpl<$Res>
    implements $MixSummaryCopyWith<$Res> {
  _$MixSummaryCopyWithImpl(this._self, this._then);

  final MixSummary _self;
  final $Res Function(MixSummary) _then;

/// Create a copy of MixSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? color = null,Object? coverUrls = null,Object? description = null,Object? id = null,Object? name = null,Object? trackCount = null,Object? trackIds = null,Object? type = null,Object? additionalProperties = null,}) {
  return _then(MixSummary(
color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,coverUrls: null == coverUrls ? _self.coverUrls : coverUrls // ignore: cast_nullable_to_non_nullable
as List<String>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,trackIds: null == trackIds ? _self.trackIds : trackIds // ignore: cast_nullable_to_non_nullable
as List<String>,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [MixSummary].
extension MixSummaryPatterns on MixSummary {
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
