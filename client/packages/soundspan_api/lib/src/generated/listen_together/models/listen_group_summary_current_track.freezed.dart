// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'listen_group_summary_current_track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ListenGroupSummaryCurrentTrack {


/// Create a copy of ListenGroupSummaryCurrentTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListenGroupSummaryCurrentTrackCopyWith<ListenGroupSummaryCurrentTrack> get copyWith => _$ListenGroupSummaryCurrentTrackCopyWithImpl<ListenGroupSummaryCurrentTrack>(this as ListenGroupSummaryCurrentTrack, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ListenGroupSummaryCurrentTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListenGroupSummaryCurrentTrack&&(identical(other.artistName, _this.artistName) || other.artistName == _this.artistName)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as ListenGroupSummaryCurrentTrack;
  return Object.hash(runtimeType,_this.artistName,_this.id,_this.title,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as ListenGroupSummaryCurrentTrack;
  return 'ListenGroupSummaryCurrentTrack(artistName: ${_this.artistName}, id: ${_this.id}, title: ${_this.title}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $ListenGroupSummaryCurrentTrackCopyWith<$Res>  {
  factory $ListenGroupSummaryCurrentTrackCopyWith(ListenGroupSummaryCurrentTrack value, $Res Function(ListenGroupSummaryCurrentTrack) _then) = _$ListenGroupSummaryCurrentTrackCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String artistName,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true, disallowNullValue: true) String title,@JsonKey(readValue: ListenGroupSummaryCurrentTrack._extras, fromJson: ListenGroupSummaryCurrentTrack._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});




}
/// @nodoc
class _$ListenGroupSummaryCurrentTrackCopyWithImpl<$Res>
    implements $ListenGroupSummaryCurrentTrackCopyWith<$Res> {
  _$ListenGroupSummaryCurrentTrackCopyWithImpl(this._self, this._then);

  final ListenGroupSummaryCurrentTrack _self;
  final $Res Function(ListenGroupSummaryCurrentTrack) _then;

/// Create a copy of ListenGroupSummaryCurrentTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? artistName = null,Object? id = null,Object? title = null,Object? additionalProperties = null,}) {
  return _then(ListenGroupSummaryCurrentTrack(
artistName: null == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [ListenGroupSummaryCurrentTrack].
extension ListenGroupSummaryCurrentTrackPatterns on ListenGroupSummaryCurrentTrack {
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
