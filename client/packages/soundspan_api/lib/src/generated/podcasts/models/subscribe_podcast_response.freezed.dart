// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscribe_podcast_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubscribePodcastResponse {


/// Create a copy of SubscribePodcastResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscribePodcastResponseCopyWith<SubscribePodcastResponse> get copyWith => _$SubscribePodcastResponseCopyWithImpl<SubscribePodcastResponse>(this as SubscribePodcastResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SubscribePodcastResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscribePodcastResponse&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.podcast, _this.podcast) || other.podcast == _this.podcast)&&(identical(other.success, _this.success) || other.success == _this.success)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as SubscribePodcastResponse;
  return Object.hash(runtimeType,_this.message,_this.podcast,_this.success,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as SubscribePodcastResponse;
  return 'SubscribePodcastResponse(message: ${_this.message}, podcast: ${_this.podcast}, success: ${_this.success}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $SubscribePodcastResponseCopyWith<$Res>  {
  factory $SubscribePodcastResponseCopyWith(SubscribePodcastResponse value, $Res Function(SubscribePodcastResponse) _then) = _$SubscribePodcastResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true, disallowNullValue: true) String message,@JsonKey(required: true, disallowNullValue: true) SubscribedPodcastRef podcast,@JsonKey(required: true, disallowNullValue: true) bool success,@JsonKey(readValue: SubscribePodcastResponse._extras, fromJson: SubscribePodcastResponse._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$SubscribedPodcastRefCopyWith<$Res> get podcast;

}
/// @nodoc
class _$SubscribePodcastResponseCopyWithImpl<$Res>
    implements $SubscribePodcastResponseCopyWith<$Res> {
  _$SubscribePodcastResponseCopyWithImpl(this._self, this._then);

  final SubscribePodcastResponse _self;
  final $Res Function(SubscribePodcastResponse) _then;

/// Create a copy of SubscribePodcastResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,Object? podcast = null,Object? success = null,Object? additionalProperties = null,}) {
  return _then(SubscribePodcastResponse(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,podcast: null == podcast ? _self.podcast : podcast // ignore: cast_nullable_to_non_nullable
as SubscribedPodcastRef,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of SubscribePodcastResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubscribedPodcastRefCopyWith<$Res> get podcast {
  
  return $SubscribedPodcastRefCopyWith<$Res>(_self.podcast, (value) {
    return _then(_self.copyWith(podcast: value));
  });
}
}


/// Adds pattern-matching-related methods to [SubscribePodcastResponse].
extension SubscribePodcastResponsePatterns on SubscribePodcastResponse {
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
