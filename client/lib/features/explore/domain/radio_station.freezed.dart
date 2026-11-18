// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'radio_station.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RadioGenre {

/// The genre as the server names it, which also selects the station.
 String get name;/// How many library tracks carry the genre.
 int get trackCount;
/// Create a copy of RadioGenre
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioGenreCopyWith<RadioGenre> get copyWith => _$RadioGenreCopyWithImpl<RadioGenre>(this as RadioGenre, _$identity);

  /// Serializes this RadioGenre to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RadioGenre;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioGenre&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.trackCount, _this.trackCount) || other.trackCount == _this.trackCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RadioGenre;
  return Object.hash(runtimeType,_this.name,_this.trackCount);
}

@override
String toString() {
  final _this = this as RadioGenre;
  return 'RadioGenre(name: ${_this.name}, trackCount: ${_this.trackCount})';
}


}

/// @nodoc
abstract mixin class $RadioGenreCopyWith<$Res>  {
  factory $RadioGenreCopyWith(RadioGenre value, $Res Function(RadioGenre) _then) = _$RadioGenreCopyWithImpl;
@useResult
$Res call({
 String name, int trackCount
});




}
/// @nodoc
class _$RadioGenreCopyWithImpl<$Res>
    implements $RadioGenreCopyWith<$Res> {
  _$RadioGenreCopyWithImpl(this._self, this._then);

  final RadioGenre _self;
  final $Res Function(RadioGenre) _then;

/// Create a copy of RadioGenre
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? trackCount = null,}) {
  return _then(RadioGenre(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RadioGenre].
extension RadioGenrePatterns on RadioGenre {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadioGenre value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadioGenre() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadioGenre value)  $default,){
final _that = this;
switch (_that) {
case _RadioGenre():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadioGenre value)?  $default,){
final _that = this;
switch (_that) {
case _RadioGenre() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int trackCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadioGenre() when $default != null:
return $default(_that.name,_that.trackCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int trackCount)  $default,) {final _that = this;
switch (_that) {
case _RadioGenre():
return $default(_that.name,_that.trackCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int trackCount)?  $default,) {final _that = this;
switch (_that) {
case _RadioGenre() when $default != null:
return $default(_that.name,_that.trackCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RadioGenre implements RadioGenre {
  const _RadioGenre({required this.name, required this.trackCount});
  factory _RadioGenre.fromJson(Map<String, dynamic> json) => _$RadioGenreFromJson(json);

/// The genre as the server names it, which also selects the station.
@override final  String name;
/// How many library tracks carry the genre.
@override final  int trackCount;

/// Create a copy of RadioGenre
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadioGenreCopyWith<_RadioGenre> get copyWith => __$RadioGenreCopyWithImpl<_RadioGenre>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RadioGenreToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadioGenre&&(identical(other.name, name) || other.name == name)&&(identical(other.trackCount, trackCount) || other.trackCount == trackCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,trackCount);
}

@override
String toString() {
    return 'RadioGenre(name: $name, trackCount: $trackCount)';
}


}

/// @nodoc
abstract mixin class _$RadioGenreCopyWith<$Res> implements $RadioGenreCopyWith<$Res> {
  factory _$RadioGenreCopyWith(_RadioGenre value, $Res Function(_RadioGenre) _then) = __$RadioGenreCopyWithImpl;
@override @useResult
$Res call({
 String name, int trackCount
});




}
/// @nodoc
class __$RadioGenreCopyWithImpl<$Res>
    implements _$RadioGenreCopyWith<$Res> {
  __$RadioGenreCopyWithImpl(this._self, this._then);

  final _RadioGenre _self;
  final $Res Function(_RadioGenre) _then;

/// Create a copy of RadioGenre
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? trackCount = null,}) {
  return _then(_RadioGenre(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$RadioDecade {

/// The first year of the decade, such as 1990.
 int get decade;/// How many library tracks were released in the decade.
 int get trackCount;
/// Create a copy of RadioDecade
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioDecadeCopyWith<RadioDecade> get copyWith => _$RadioDecadeCopyWithImpl<RadioDecade>(this as RadioDecade, _$identity);

  /// Serializes this RadioDecade to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RadioDecade;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioDecade&&(identical(other.decade, _this.decade) || other.decade == _this.decade)&&(identical(other.trackCount, _this.trackCount) || other.trackCount == _this.trackCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RadioDecade;
  return Object.hash(runtimeType,_this.decade,_this.trackCount);
}

@override
String toString() {
  final _this = this as RadioDecade;
  return 'RadioDecade(decade: ${_this.decade}, trackCount: ${_this.trackCount})';
}


}

/// @nodoc
abstract mixin class $RadioDecadeCopyWith<$Res>  {
  factory $RadioDecadeCopyWith(RadioDecade value, $Res Function(RadioDecade) _then) = _$RadioDecadeCopyWithImpl;
@useResult
$Res call({
 int decade, int trackCount
});




}
/// @nodoc
class _$RadioDecadeCopyWithImpl<$Res>
    implements $RadioDecadeCopyWith<$Res> {
  _$RadioDecadeCopyWithImpl(this._self, this._then);

  final RadioDecade _self;
  final $Res Function(RadioDecade) _then;

/// Create a copy of RadioDecade
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? decade = null,Object? trackCount = null,}) {
  return _then(RadioDecade(
decade: null == decade ? _self.decade : decade // ignore: cast_nullable_to_non_nullable
as int,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RadioDecade].
extension RadioDecadePatterns on RadioDecade {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadioDecade value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadioDecade() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadioDecade value)  $default,){
final _that = this;
switch (_that) {
case _RadioDecade():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadioDecade value)?  $default,){
final _that = this;
switch (_that) {
case _RadioDecade() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int decade,  int trackCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadioDecade() when $default != null:
return $default(_that.decade,_that.trackCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int decade,  int trackCount)  $default,) {final _that = this;
switch (_that) {
case _RadioDecade():
return $default(_that.decade,_that.trackCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int decade,  int trackCount)?  $default,) {final _that = this;
switch (_that) {
case _RadioDecade() when $default != null:
return $default(_that.decade,_that.trackCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RadioDecade implements RadioDecade {
  const _RadioDecade({required this.decade, required this.trackCount});
  factory _RadioDecade.fromJson(Map<String, dynamic> json) => _$RadioDecadeFromJson(json);

/// The first year of the decade, such as 1990.
@override final  int decade;
/// How many library tracks were released in the decade.
@override final  int trackCount;

/// Create a copy of RadioDecade
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadioDecadeCopyWith<_RadioDecade> get copyWith => __$RadioDecadeCopyWithImpl<_RadioDecade>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RadioDecadeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadioDecade&&(identical(other.decade, decade) || other.decade == decade)&&(identical(other.trackCount, trackCount) || other.trackCount == trackCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,decade,trackCount);
}

@override
String toString() {
    return 'RadioDecade(decade: $decade, trackCount: $trackCount)';
}


}

/// @nodoc
abstract mixin class _$RadioDecadeCopyWith<$Res> implements $RadioDecadeCopyWith<$Res> {
  factory _$RadioDecadeCopyWith(_RadioDecade value, $Res Function(_RadioDecade) _then) = __$RadioDecadeCopyWithImpl;
@override @useResult
$Res call({
 int decade, int trackCount
});




}
/// @nodoc
class __$RadioDecadeCopyWithImpl<$Res>
    implements _$RadioDecadeCopyWith<$Res> {
  __$RadioDecadeCopyWithImpl(this._self, this._then);

  final _RadioDecade _self;
  final $Res Function(_RadioDecade) _then;

/// Create a copy of RadioDecade
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? decade = null,Object? trackCount = null,}) {
  return _then(_RadioDecade(
decade: null == decade ? _self.decade : decade // ignore: cast_nullable_to_non_nullable
as int,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$RadioStation {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioStation);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RadioStation()';
}


}

/// @nodoc
class $RadioStationCopyWith<$Res>  {
$RadioStationCopyWith(RadioStation _, $Res Function(RadioStation) __);
}


/// Adds pattern-matching-related methods to [RadioStation].
extension RadioStationPatterns on RadioStation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GenreStation value)?  genre,TResult Function( DecadeStation value)?  decade,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GenreStation() when genre != null:
return genre(_that);case DecadeStation() when decade != null:
return decade(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GenreStation value)  genre,required TResult Function( DecadeStation value)  decade,}){
final _that = this;
switch (_that) {
case GenreStation():
return genre(_that);case DecadeStation():
return decade(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GenreStation value)?  genre,TResult? Function( DecadeStation value)?  decade,}){
final _that = this;
switch (_that) {
case GenreStation() when genre != null:
return genre(_that);case DecadeStation() when decade != null:
return decade(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String name)?  genre,TResult Function( int decade)?  decade,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GenreStation() when genre != null:
return genre(_that.name);case DecadeStation() when decade != null:
return decade(_that.decade);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String name)  genre,required TResult Function( int decade)  decade,}) {final _that = this;
switch (_that) {
case GenreStation():
return genre(_that.name);case DecadeStation():
return decade(_that.decade);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String name)?  genre,TResult? Function( int decade)?  decade,}) {final _that = this;
switch (_that) {
case GenreStation() when genre != null:
return genre(_that.name);case DecadeStation() when decade != null:
return decade(_that.decade);case _:
  return null;

}
}

}

/// @nodoc


class GenreStation implements RadioStation {
  const GenreStation(this.name);
  

 final  String name;

/// Create a copy of RadioStation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GenreStationCopyWith<GenreStation> get copyWith => _$GenreStationCopyWithImpl<GenreStation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GenreStation&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name);
}

@override
String toString() {
    return 'RadioStation.genre(name: $name)';
}


}

/// @nodoc
abstract mixin class $GenreStationCopyWith<$Res> implements $RadioStationCopyWith<$Res> {
  factory $GenreStationCopyWith(GenreStation value, $Res Function(GenreStation) _then) = _$GenreStationCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$GenreStationCopyWithImpl<$Res>
    implements $GenreStationCopyWith<$Res> {
  _$GenreStationCopyWithImpl(this._self, this._then);

  final GenreStation _self;
  final $Res Function(GenreStation) _then;

/// Create a copy of RadioStation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(GenreStation(
null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DecadeStation implements RadioStation {
  const DecadeStation(this.decade);
  

 final  int decade;

/// Create a copy of RadioStation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DecadeStationCopyWith<DecadeStation> get copyWith => _$DecadeStationCopyWithImpl<DecadeStation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DecadeStation&&(identical(other.decade, decade) || other.decade == decade));
}


@override
int get hashCode {
    return Object.hash(runtimeType,decade);
}

@override
String toString() {
    return 'RadioStation.decade(decade: $decade)';
}


}

/// @nodoc
abstract mixin class $DecadeStationCopyWith<$Res> implements $RadioStationCopyWith<$Res> {
  factory $DecadeStationCopyWith(DecadeStation value, $Res Function(DecadeStation) _then) = _$DecadeStationCopyWithImpl;
@useResult
$Res call({
 int decade
});




}
/// @nodoc
class _$DecadeStationCopyWithImpl<$Res>
    implements $DecadeStationCopyWith<$Res> {
  _$DecadeStationCopyWithImpl(this._self, this._then);

  final DecadeStation _self;
  final $Res Function(DecadeStation) _then;

/// Create a copy of RadioStation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? decade = null,}) {
  return _then(DecadeStation(
null == decade ? _self.decade : decade // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
