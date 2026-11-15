// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'podcast_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PodcastDetail {

/// The podcast.
 Podcast get podcast;/// Its episodes, in server order.
 List<Episode> get episodes;
/// Create a copy of PodcastDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PodcastDetailCopyWith<PodcastDetail> get copyWith => _$PodcastDetailCopyWithImpl<PodcastDetail>(this as PodcastDetail, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PodcastDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PodcastDetail&&(identical(other.podcast, _this.podcast) || other.podcast == _this.podcast)&&const DeepCollectionEquality().equals(other.episodes, _this.episodes));
}


@override
int get hashCode {
  final _this = this as PodcastDetail;
  return Object.hash(runtimeType,_this.podcast,const DeepCollectionEquality().hash(_this.episodes));
}

@override
String toString() {
  final _this = this as PodcastDetail;
  return 'PodcastDetail(podcast: ${_this.podcast}, episodes: ${_this.episodes})';
}


}

/// @nodoc
abstract mixin class $PodcastDetailCopyWith<$Res>  {
  factory $PodcastDetailCopyWith(PodcastDetail value, $Res Function(PodcastDetail) _then) = _$PodcastDetailCopyWithImpl;
@useResult
$Res call({
 Podcast podcast, List<Episode> episodes
});


$PodcastCopyWith<$Res> get podcast;

}
/// @nodoc
class _$PodcastDetailCopyWithImpl<$Res>
    implements $PodcastDetailCopyWith<$Res> {
  _$PodcastDetailCopyWithImpl(this._self, this._then);

  final PodcastDetail _self;
  final $Res Function(PodcastDetail) _then;

/// Create a copy of PodcastDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? podcast = null,Object? episodes = null,}) {
  return _then(PodcastDetail(
podcast: null == podcast ? _self.podcast : podcast // ignore: cast_nullable_to_non_nullable
as Podcast,episodes: null == episodes ? _self.episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<Episode>,
  ));
}
/// Create a copy of PodcastDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PodcastCopyWith<$Res> get podcast {
  
  return $PodcastCopyWith<$Res>(_self.podcast, (value) {
    return _then(_self.copyWith(podcast: value));
  });
}
}


/// Adds pattern-matching-related methods to [PodcastDetail].
extension PodcastDetailPatterns on PodcastDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PodcastDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PodcastDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PodcastDetail value)  $default,){
final _that = this;
switch (_that) {
case _PodcastDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PodcastDetail value)?  $default,){
final _that = this;
switch (_that) {
case _PodcastDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Podcast podcast,  List<Episode> episodes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PodcastDetail() when $default != null:
return $default(_that.podcast,_that.episodes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Podcast podcast,  List<Episode> episodes)  $default,) {final _that = this;
switch (_that) {
case _PodcastDetail():
return $default(_that.podcast,_that.episodes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Podcast podcast,  List<Episode> episodes)?  $default,) {final _that = this;
switch (_that) {
case _PodcastDetail() when $default != null:
return $default(_that.podcast,_that.episodes);case _:
  return null;

}
}

}

/// @nodoc


class _PodcastDetail implements PodcastDetail {
  const _PodcastDetail({required this.podcast, required  List<Episode> episodes}): _episodes = episodes;
  

/// The podcast.
@override final  Podcast podcast;
/// Its episodes, in server order.
 final  List<Episode> _episodes;
/// Its episodes, in server order.
@override List<Episode> get episodes {
  if (_episodes is EqualUnmodifiableListView) return _episodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_episodes);
}


/// Create a copy of PodcastDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PodcastDetailCopyWith<_PodcastDetail> get copyWith => __$PodcastDetailCopyWithImpl<_PodcastDetail>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PodcastDetail&&(identical(other.podcast, podcast) || other.podcast == podcast)&&const DeepCollectionEquality().equals(other.episodes, _episodes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,podcast,const DeepCollectionEquality().hash(_episodes));
}

@override
String toString() {
    return 'PodcastDetail(podcast: $podcast, episodes: $episodes)';
}


}

/// @nodoc
abstract mixin class _$PodcastDetailCopyWith<$Res> implements $PodcastDetailCopyWith<$Res> {
  factory _$PodcastDetailCopyWith(_PodcastDetail value, $Res Function(_PodcastDetail) _then) = __$PodcastDetailCopyWithImpl;
@override @useResult
$Res call({
 Podcast podcast, List<Episode> episodes
});


@override $PodcastCopyWith<$Res> get podcast;

}
/// @nodoc
class __$PodcastDetailCopyWithImpl<$Res>
    implements _$PodcastDetailCopyWith<$Res> {
  __$PodcastDetailCopyWithImpl(this._self, this._then);

  final _PodcastDetail _self;
  final $Res Function(_PodcastDetail) _then;

/// Create a copy of PodcastDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? podcast = null,Object? episodes = null,}) {
  return _then(_PodcastDetail(
podcast: null == podcast ? _self.podcast : podcast // ignore: cast_nullable_to_non_nullable
as Podcast,episodes: null == episodes ? _self._episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<Episode>,
  ));
}

/// Create a copy of PodcastDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PodcastCopyWith<$Res> get podcast {
  
  return $PodcastCopyWith<$Res>(_self.podcast, (value) {
    return _then(_self.copyWith(podcast: value));
  });
}
}

// dart format on
