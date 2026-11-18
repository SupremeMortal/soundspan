// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'play_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlayRecord {


/// Create a copy of PlayRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayRecordCopyWith<PlayRecord> get copyWith => _$PlayRecordCopyWithImpl<PlayRecord>(this as PlayRecord, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlayRecord;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayRecord&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.listenedMs, _this.listenedMs) || other.listenedMs == _this.listenedMs)&&(identical(other.playedAt, _this.playedAt) || other.playedAt == _this.playedAt)&&(identical(other.source, _this.source) || other.source == _this.source)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as PlayRecord;
  return Object.hash(runtimeType,_this.id,_this.listenedMs,_this.playedAt,_this.source,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as PlayRecord;
  return 'PlayRecord(id: ${_this.id}, listenedMs: ${_this.listenedMs}, playedAt: ${_this.playedAt}, source: ${_this.source}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $PlayRecordCopyWith<$Res>  {
  factory $PlayRecordCopyWith(PlayRecord value, $Res Function(PlayRecord) _then) = _$PlayRecordCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true, fromJson: PlayRecord._read_listenedMs, toJson: PlayRecord._write_listenedMs) int? listenedMs,@JsonKey(required: true, disallowNullValue: true, fromJson: PlayRecord._read_playedAt, toJson: PlayRecord._write_playedAt) DateTime playedAt,@JsonKey(required: true, disallowNullValue: true, fromJson: PlayRecord._read_source, toJson: PlayRecord._write_source) PlayRecordSource source,@JsonKey(readValue: PlayRecord._extras, fromJson: PlayRecord._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$PlayRecordCopyWithImpl<$Res>
    implements $PlayRecordCopyWith<$Res> {
  _$PlayRecordCopyWithImpl(this._self, this._then);

  final PlayRecord _self;
  final $Res Function(PlayRecord) _then;

/// Create a copy of PlayRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? listenedMs = freezed,Object? playedAt = null,Object? source = null,Object? additionalProperties = null,}) {
  return _then(PlayRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,listenedMs: freezed == listenedMs ? _self.listenedMs : listenedMs // ignore: cast_nullable_to_non_nullable
as int?,playedAt: null == playedAt ? _self.playedAt : playedAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as PlayRecordSource,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayRecord].
extension PlayRecordPatterns on PlayRecord {
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
