// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recent_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
RecentItem _$RecentItemFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'artist':
          return RecentArtist.fromJson(
            json
          );
                case 'podcast':
          return RecentPodcast.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'kind',
  'RecentItem',
  'Invalid union type "${json['kind']}"!'
);
        }
      
}

/// @nodoc
mixin _$RecentItem {



  /// Serializes this RecentItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentItem);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RecentItem()';
}


}

/// @nodoc
class $RecentItemCopyWith<$Res>  {
$RecentItemCopyWith(RecentItem _, $Res Function(RecentItem) __);
}


/// Adds pattern-matching-related methods to [RecentItem].
extension RecentItemPatterns on RecentItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RecentArtist value)?  artist,TResult Function( RecentPodcast value)?  podcast,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RecentArtist() when artist != null:
return artist(_that);case RecentPodcast() when podcast != null:
return podcast(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RecentArtist value)  artist,required TResult Function( RecentPodcast value)  podcast,}){
final _that = this;
switch (_that) {
case RecentArtist():
return artist(_that);case RecentPodcast():
return podcast(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RecentArtist value)?  artist,TResult? Function( RecentPodcast value)?  podcast,}){
final _that = this;
switch (_that) {
case RecentArtist() when artist != null:
return artist(_that);case RecentPodcast() when podcast != null:
return podcast(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Artist artist)?  artist,TResult Function( Podcast podcast)?  podcast,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RecentArtist() when artist != null:
return artist(_that.artist);case RecentPodcast() when podcast != null:
return podcast(_that.podcast);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Artist artist)  artist,required TResult Function( Podcast podcast)  podcast,}) {final _that = this;
switch (_that) {
case RecentArtist():
return artist(_that.artist);case RecentPodcast():
return podcast(_that.podcast);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Artist artist)?  artist,TResult? Function( Podcast podcast)?  podcast,}) {final _that = this;
switch (_that) {
case RecentArtist() when artist != null:
return artist(_that.artist);case RecentPodcast() when podcast != null:
return podcast(_that.podcast);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class RecentArtist implements RecentItem {
  const RecentArtist({required this.artist,  String? $type}): $type = $type ?? 'artist';
  factory RecentArtist.fromJson(Map<String, dynamic> json) => _$RecentArtistFromJson(json);

/// The artist.
 final  Artist artist;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of RecentItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentArtistCopyWith<RecentArtist> get copyWith => _$RecentArtistCopyWithImpl<RecentArtist>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecentArtistToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentArtist&&(identical(other.artist, artist) || other.artist == artist));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,artist);
}

@override
String toString() {
    return 'RecentItem.artist(artist: $artist)';
}


}

/// @nodoc
abstract mixin class $RecentArtistCopyWith<$Res> implements $RecentItemCopyWith<$Res> {
  factory $RecentArtistCopyWith(RecentArtist value, $Res Function(RecentArtist) _then) = _$RecentArtistCopyWithImpl;
@useResult
$Res call({
 Artist artist
});


$ArtistCopyWith<$Res> get artist;

}
/// @nodoc
class _$RecentArtistCopyWithImpl<$Res>
    implements $RecentArtistCopyWith<$Res> {
  _$RecentArtistCopyWithImpl(this._self, this._then);

  final RecentArtist _self;
  final $Res Function(RecentArtist) _then;

/// Create a copy of RecentItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? artist = null,}) {
  return _then(RecentArtist(
artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as Artist,
  ));
}

/// Create a copy of RecentItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArtistCopyWith<$Res> get artist {
  
  return $ArtistCopyWith<$Res>(_self.artist, (value) {
    return _then(_self.copyWith(artist: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class RecentPodcast implements RecentItem {
  const RecentPodcast({required this.podcast,  String? $type}): $type = $type ?? 'podcast';
  factory RecentPodcast.fromJson(Map<String, dynamic> json) => _$RecentPodcastFromJson(json);

/// The podcast.
 final  Podcast podcast;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of RecentItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentPodcastCopyWith<RecentPodcast> get copyWith => _$RecentPodcastCopyWithImpl<RecentPodcast>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecentPodcastToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentPodcast&&(identical(other.podcast, podcast) || other.podcast == podcast));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,podcast);
}

@override
String toString() {
    return 'RecentItem.podcast(podcast: $podcast)';
}


}

/// @nodoc
abstract mixin class $RecentPodcastCopyWith<$Res> implements $RecentItemCopyWith<$Res> {
  factory $RecentPodcastCopyWith(RecentPodcast value, $Res Function(RecentPodcast) _then) = _$RecentPodcastCopyWithImpl;
@useResult
$Res call({
 Podcast podcast
});


$PodcastCopyWith<$Res> get podcast;

}
/// @nodoc
class _$RecentPodcastCopyWithImpl<$Res>
    implements $RecentPodcastCopyWith<$Res> {
  _$RecentPodcastCopyWithImpl(this._self, this._then);

  final RecentPodcast _self;
  final $Res Function(RecentPodcast) _then;

/// Create a copy of RecentItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? podcast = null,}) {
  return _then(RecentPodcast(
podcast: null == podcast ? _self.podcast : podcast // ignore: cast_nullable_to_non_nullable
as Podcast,
  ));
}

/// Create a copy of RecentItem
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
