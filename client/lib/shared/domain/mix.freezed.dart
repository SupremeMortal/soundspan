// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mix.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MixSummary {

/// The server's mix id.
 String get id;/// The mix name.
 String get name;/// The mix description.
 String get description;/// Values to pass to the cover-art endpoint, for the mosaic.
 List<String> get coverRefs;
/// Create a copy of MixSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MixSummaryCopyWith<MixSummary> get copyWith => _$MixSummaryCopyWithImpl<MixSummary>(this as MixSummary, _$identity);

  /// Serializes this MixSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MixSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MixSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&const DeepCollectionEquality().equals(other.coverRefs, _this.coverRefs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MixSummary;
  return Object.hash(runtimeType,_this.id,_this.name,_this.description,const DeepCollectionEquality().hash(_this.coverRefs));
}

@override
String toString() {
  final _this = this as MixSummary;
  return 'MixSummary(id: ${_this.id}, name: ${_this.name}, description: ${_this.description}, coverRefs: ${_this.coverRefs})';
}


}

/// @nodoc
abstract mixin class $MixSummaryCopyWith<$Res>  {
  factory $MixSummaryCopyWith(MixSummary value, $Res Function(MixSummary) _then) = _$MixSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, List<String> coverRefs
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? coverRefs = null,}) {
  return _then(MixSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,coverRefs: null == coverRefs ? _self.coverRefs : coverRefs // ignore: cast_nullable_to_non_nullable
as List<String>,
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MixSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MixSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MixSummary value)  $default,){
final _that = this;
switch (_that) {
case _MixSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MixSummary value)?  $default,){
final _that = this;
switch (_that) {
case _MixSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  List<String> coverRefs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MixSummary() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.coverRefs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  List<String> coverRefs)  $default,) {final _that = this;
switch (_that) {
case _MixSummary():
return $default(_that.id,_that.name,_that.description,_that.coverRefs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  List<String> coverRefs)?  $default,) {final _that = this;
switch (_that) {
case _MixSummary() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.coverRefs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MixSummary implements MixSummary {
  const _MixSummary({required this.id, required this.name, required this.description,  List<String> coverRefs = const <String>[]}): _coverRefs = coverRefs;
  factory _MixSummary.fromJson(Map<String, dynamic> json) => _$MixSummaryFromJson(json);

/// The server's mix id.
@override final  String id;
/// The mix name.
@override final  String name;
/// The mix description.
@override final  String description;
/// Values to pass to the cover-art endpoint, for the mosaic.
 final  List<String> _coverRefs;
/// Values to pass to the cover-art endpoint, for the mosaic.
@override@JsonKey() List<String> get coverRefs {
  if (_coverRefs is EqualUnmodifiableListView) return _coverRefs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_coverRefs);
}


/// Create a copy of MixSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MixSummaryCopyWith<_MixSummary> get copyWith => __$MixSummaryCopyWithImpl<_MixSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MixSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MixSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.coverRefs, _coverRefs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,description,const DeepCollectionEquality().hash(_coverRefs));
}

@override
String toString() {
    return 'MixSummary(id: $id, name: $name, description: $description, coverRefs: $coverRefs)';
}


}

/// @nodoc
abstract mixin class _$MixSummaryCopyWith<$Res> implements $MixSummaryCopyWith<$Res> {
  factory _$MixSummaryCopyWith(_MixSummary value, $Res Function(_MixSummary) _then) = __$MixSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, List<String> coverRefs
});




}
/// @nodoc
class __$MixSummaryCopyWithImpl<$Res>
    implements _$MixSummaryCopyWith<$Res> {
  __$MixSummaryCopyWithImpl(this._self, this._then);

  final _MixSummary _self;
  final $Res Function(_MixSummary) _then;

/// Create a copy of MixSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? coverRefs = null,}) {
  return _then(_MixSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,coverRefs: null == coverRefs ? _self._coverRefs : coverRefs // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
