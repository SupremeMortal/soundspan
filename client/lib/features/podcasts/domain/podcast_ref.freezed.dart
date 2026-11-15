// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'podcast_ref.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PodcastRef {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PodcastRef);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PodcastRef()';
}


}

/// @nodoc
class $PodcastRefCopyWith<$Res>  {
$PodcastRefCopyWith(PodcastRef _, $Res Function(PodcastRef) __);
}


/// Adds pattern-matching-related methods to [PodcastRef].
extension PodcastRefPatterns on PodcastRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FeedPodcastRef value)?  feed,TResult Function( ItunesPodcastRef value)?  itunes,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FeedPodcastRef() when feed != null:
return feed(_that);case ItunesPodcastRef() when itunes != null:
return itunes(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FeedPodcastRef value)  feed,required TResult Function( ItunesPodcastRef value)  itunes,}){
final _that = this;
switch (_that) {
case FeedPodcastRef():
return feed(_that);case ItunesPodcastRef():
return itunes(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FeedPodcastRef value)?  feed,TResult? Function( ItunesPodcastRef value)?  itunes,}){
final _that = this;
switch (_that) {
case FeedPodcastRef() when feed != null:
return feed(_that);case ItunesPodcastRef() when itunes != null:
return itunes(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String feedUrl)?  feed,TResult Function( String itunesId)?  itunes,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FeedPodcastRef() when feed != null:
return feed(_that.feedUrl);case ItunesPodcastRef() when itunes != null:
return itunes(_that.itunesId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String feedUrl)  feed,required TResult Function( String itunesId)  itunes,}) {final _that = this;
switch (_that) {
case FeedPodcastRef():
return feed(_that.feedUrl);case ItunesPodcastRef():
return itunes(_that.itunesId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String feedUrl)?  feed,TResult? Function( String itunesId)?  itunes,}) {final _that = this;
switch (_that) {
case FeedPodcastRef() when feed != null:
return feed(_that.feedUrl);case ItunesPodcastRef() when itunes != null:
return itunes(_that.itunesId);case _:
  return null;

}
}

}

/// @nodoc


class FeedPodcastRef implements PodcastRef {
  const FeedPodcastRef(this.feedUrl);
  

 final  String feedUrl;

/// Create a copy of PodcastRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedPodcastRefCopyWith<FeedPodcastRef> get copyWith => _$FeedPodcastRefCopyWithImpl<FeedPodcastRef>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedPodcastRef&&(identical(other.feedUrl, feedUrl) || other.feedUrl == feedUrl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,feedUrl);
}

@override
String toString() {
    return 'PodcastRef.feed(feedUrl: $feedUrl)';
}


}

/// @nodoc
abstract mixin class $FeedPodcastRefCopyWith<$Res> implements $PodcastRefCopyWith<$Res> {
  factory $FeedPodcastRefCopyWith(FeedPodcastRef value, $Res Function(FeedPodcastRef) _then) = _$FeedPodcastRefCopyWithImpl;
@useResult
$Res call({
 String feedUrl
});




}
/// @nodoc
class _$FeedPodcastRefCopyWithImpl<$Res>
    implements $FeedPodcastRefCopyWith<$Res> {
  _$FeedPodcastRefCopyWithImpl(this._self, this._then);

  final FeedPodcastRef _self;
  final $Res Function(FeedPodcastRef) _then;

/// Create a copy of PodcastRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? feedUrl = null,}) {
  return _then(FeedPodcastRef(
null == feedUrl ? _self.feedUrl : feedUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ItunesPodcastRef implements PodcastRef {
  const ItunesPodcastRef(this.itunesId);
  

 final  String itunesId;

/// Create a copy of PodcastRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItunesPodcastRefCopyWith<ItunesPodcastRef> get copyWith => _$ItunesPodcastRefCopyWithImpl<ItunesPodcastRef>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ItunesPodcastRef&&(identical(other.itunesId, itunesId) || other.itunesId == itunesId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,itunesId);
}

@override
String toString() {
    return 'PodcastRef.itunes(itunesId: $itunesId)';
}


}

/// @nodoc
abstract mixin class $ItunesPodcastRefCopyWith<$Res> implements $PodcastRefCopyWith<$Res> {
  factory $ItunesPodcastRefCopyWith(ItunesPodcastRef value, $Res Function(ItunesPodcastRef) _then) = _$ItunesPodcastRefCopyWithImpl;
@useResult
$Res call({
 String itunesId
});




}
/// @nodoc
class _$ItunesPodcastRefCopyWithImpl<$Res>
    implements $ItunesPodcastRefCopyWith<$Res> {
  _$ItunesPodcastRefCopyWithImpl(this._self, this._then);

  final ItunesPodcastRef _self;
  final $Res Function(ItunesPodcastRef) _then;

/// Create a copy of PodcastRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? itunesId = null,}) {
  return _then(ItunesPodcastRef(
null == itunesId ? _self.itunesId : itunesId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
