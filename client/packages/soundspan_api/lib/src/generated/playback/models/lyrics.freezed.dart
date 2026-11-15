// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lyrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Lyrics {


/// Create a copy of Lyrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LyricsCopyWith<Lyrics> get copyWith => _$LyricsCopyWithImpl<Lyrics>(this as Lyrics, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Lyrics;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Lyrics&&(identical(other.plainLyrics, _this.plainLyrics) || other.plainLyrics == _this.plainLyrics)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.synced, _this.synced) || other.synced == _this.synced)&&(identical(other.syncedLyrics, _this.syncedLyrics) || other.syncedLyrics == _this.syncedLyrics)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as Lyrics;
  return Object.hash(runtimeType,_this.plainLyrics,_this.source,_this.synced,_this.syncedLyrics,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as Lyrics;
  return 'Lyrics(plainLyrics: ${_this.plainLyrics}, source: ${_this.source}, synced: ${_this.synced}, syncedLyrics: ${_this.syncedLyrics}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $LyricsCopyWith<$Res>  {
  factory $LyricsCopyWith(Lyrics value, $Res Function(Lyrics) _then) = _$LyricsCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true) String? plainLyrics,@JsonKey(required: true, disallowNullValue: true, fromJson: Lyrics._read_source, toJson: Lyrics._write_source) LyricsSource source,@JsonKey(required: true, disallowNullValue: true) bool synced,@JsonKey(required: true) String? syncedLyrics,@JsonKey(readValue: Lyrics._extras, fromJson: Lyrics._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$LyricsCopyWithImpl<$Res>
    implements $LyricsCopyWith<$Res> {
  _$LyricsCopyWithImpl(this._self, this._then);

  final Lyrics _self;
  final $Res Function(Lyrics) _then;

/// Create a copy of Lyrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plainLyrics = freezed,Object? source = null,Object? synced = null,Object? syncedLyrics = freezed,Object? additionalProperties = null,}) {
  return _then(Lyrics(
plainLyrics: freezed == plainLyrics ? _self.plainLyrics : plainLyrics // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as LyricsSource,synced: null == synced ? _self.synced : synced // ignore: cast_nullable_to_non_nullable
as bool,syncedLyrics: freezed == syncedLyrics ? _self.syncedLyrics : syncedLyrics // ignore: cast_nullable_to_non_nullable
as String?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [Lyrics].
extension LyricsPatterns on Lyrics {
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
