// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_source.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchSourceKnown {


/// Create a copy of SearchSourceKnown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchSourceKnownCopyWith<SearchSourceKnown> get copyWith => _$SearchSourceKnownCopyWithImpl<SearchSourceKnown>(this as SearchSourceKnown, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SearchSourceKnown;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchSourceKnown&&(identical(other.value, _this.value) || other.value == _this.value));
}


@override
int get hashCode {
  final _this = this as SearchSourceKnown;
  return Object.hash(runtimeType,_this.value);
}

@override
String toString() {
  final _this = this as SearchSourceKnown;
  return 'SearchSourceKnown(value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class $SearchSourceKnownCopyWith<$Res>  {
  factory $SearchSourceKnownCopyWith(SearchSourceKnown value, $Res Function(SearchSourceKnown) _then) = _$SearchSourceKnownCopyWithImpl;
@useResult
$Res call({
 SearchSourceValue value
});




}
/// @nodoc
class _$SearchSourceKnownCopyWithImpl<$Res>
    implements $SearchSourceKnownCopyWith<$Res> {
  _$SearchSourceKnownCopyWithImpl(this._self, this._then);

  final SearchSourceKnown _self;
  final $Res Function(SearchSourceKnown) _then;

/// Create a copy of SearchSourceKnown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,}) {
  return _then(SearchSourceKnown(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as SearchSourceValue,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchSourceKnown].
extension SearchSourceKnownPatterns on SearchSourceKnown {
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

/// @nodoc
mixin _$SearchSourceUnknown {


/// Create a copy of SearchSourceUnknown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchSourceUnknownCopyWith<SearchSourceUnknown> get copyWith => _$SearchSourceUnknownCopyWithImpl<SearchSourceUnknown>(this as SearchSourceUnknown, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SearchSourceUnknown;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchSourceUnknown&&(identical(other.rawValue, _this.rawValue) || other.rawValue == _this.rawValue));
}


@override
int get hashCode {
  final _this = this as SearchSourceUnknown;
  return Object.hash(runtimeType,_this.rawValue);
}

@override
String toString() {
  final _this = this as SearchSourceUnknown;
  return 'SearchSourceUnknown(rawValue: ${_this.rawValue})';
}


}

/// @nodoc
abstract mixin class $SearchSourceUnknownCopyWith<$Res>  {
  factory $SearchSourceUnknownCopyWith(SearchSourceUnknown value, $Res Function(SearchSourceUnknown) _then) = _$SearchSourceUnknownCopyWithImpl;
@useResult
$Res call({
 String rawValue
});




}
/// @nodoc
class _$SearchSourceUnknownCopyWithImpl<$Res>
    implements $SearchSourceUnknownCopyWith<$Res> {
  _$SearchSourceUnknownCopyWithImpl(this._self, this._then);

  final SearchSourceUnknown _self;
  final $Res Function(SearchSourceUnknown) _then;

/// Create a copy of SearchSourceUnknown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rawValue = null,}) {
  return _then(SearchSourceUnknown(
null == rawValue ? _self.rawValue : rawValue // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchSourceUnknown].
extension SearchSourceUnknownPatterns on SearchSourceUnknown {
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
