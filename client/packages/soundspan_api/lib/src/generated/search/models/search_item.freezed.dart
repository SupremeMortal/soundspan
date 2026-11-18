// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchItem {


/// Create a copy of SearchItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchItemCopyWith<SearchItem> get copyWith => _$SearchItemCopyWithImpl<SearchItem>(this as SearchItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SearchItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchItem&&(identical(other.album, _this.album) || other.album == _this.album)&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&(identical(other.catalogue, _this.catalogue) || other.catalogue == _this.catalogue)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.playlist, _this.playlist) || other.playlist == _this.playlist)&&(identical(other.podcast, _this.podcast) || other.podcast == _this.podcast)&&(identical(other.remoteAlbum, _this.remoteAlbum) || other.remoteAlbum == _this.remoteAlbum)&&(identical(other.remoteTrack, _this.remoteTrack) || other.remoteTrack == _this.remoteTrack)&&(identical(other.score, _this.score) || other.score == _this.score)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.track, _this.track) || other.track == _this.track)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as SearchItem;
  return Object.hash(runtimeType,_this.album,_this.artist,_this.catalogue,_this.kind,_this.playlist,_this.podcast,_this.remoteAlbum,_this.remoteTrack,_this.score,_this.source,_this.track,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as SearchItem;
  return 'SearchItem(album: ${_this.album}, artist: ${_this.artist}, catalogue: ${_this.catalogue}, kind: ${_this.kind}, playlist: ${_this.playlist}, podcast: ${_this.podcast}, remoteAlbum: ${_this.remoteAlbum}, remoteTrack: ${_this.remoteTrack}, score: ${_this.score}, source: ${_this.source}, track: ${_this.track}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $SearchItemCopyWith<$Res>  {
  factory $SearchItemCopyWith(SearchItem value, $Res Function(SearchItem) _then) = _$SearchItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(disallowNullValue: true, includeIfNull: false) SearchAlbum? album,@JsonKey(disallowNullValue: true, includeIfNull: false) SearchArtist? artist,@JsonKey(disallowNullValue: true, includeIfNull: false) DiscoverResult? catalogue,@JsonKey(required: true, disallowNullValue: true, fromJson: SearchItem._read_kind, toJson: SearchItem._write_kind) SearchItemKind kind,@JsonKey(disallowNullValue: true, includeIfNull: false) PlaylistSummary? playlist,@JsonKey(disallowNullValue: true, includeIfNull: false) SearchPodcast? podcast,@JsonKey(disallowNullValue: true, includeIfNull: false) SearchRemoteAlbum? remoteAlbum,@JsonKey(disallowNullValue: true, includeIfNull: false) SearchRemoteTrack? remoteTrack,@JsonKey(required: true, disallowNullValue: true) num score,@JsonKey(required: true, disallowNullValue: true, fromJson: SearchItem._read_source, toJson: SearchItem._write_source) SearchItemSource source,@JsonKey(disallowNullValue: true, includeIfNull: false) SearchTrack? track,@JsonKey(readValue: SearchItem._extras, fromJson: SearchItem._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$SearchAlbumCopyWith<$Res>? get album;$SearchArtistCopyWith<$Res>? get artist;$DiscoverResultCopyWith<$Res>? get catalogue;$PlaylistSummaryCopyWith<$Res>? get playlist;$SearchPodcastCopyWith<$Res>? get podcast;$SearchRemoteAlbumCopyWith<$Res>? get remoteAlbum;$SearchRemoteTrackCopyWith<$Res>? get remoteTrack;$SearchTrackCopyWith<$Res>? get track;

}
/// @nodoc
class _$SearchItemCopyWithImpl<$Res>
    implements $SearchItemCopyWith<$Res> {
  _$SearchItemCopyWithImpl(this._self, this._then);

  final SearchItem _self;
  final $Res Function(SearchItem) _then;

/// Create a copy of SearchItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? album = freezed,Object? artist = freezed,Object? catalogue = freezed,Object? kind = null,Object? playlist = freezed,Object? podcast = freezed,Object? remoteAlbum = freezed,Object? remoteTrack = freezed,Object? score = null,Object? source = null,Object? track = freezed,Object? additionalProperties = null,}) {
  return _then(SearchItem(
album: freezed == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as SearchAlbum?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as SearchArtist?,catalogue: freezed == catalogue ? _self.catalogue : catalogue // ignore: cast_nullable_to_non_nullable
as DiscoverResult?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SearchItemKind,playlist: freezed == playlist ? _self.playlist : playlist // ignore: cast_nullable_to_non_nullable
as PlaylistSummary?,podcast: freezed == podcast ? _self.podcast : podcast // ignore: cast_nullable_to_non_nullable
as SearchPodcast?,remoteAlbum: freezed == remoteAlbum ? _self.remoteAlbum : remoteAlbum // ignore: cast_nullable_to_non_nullable
as SearchRemoteAlbum?,remoteTrack: freezed == remoteTrack ? _self.remoteTrack : remoteTrack // ignore: cast_nullable_to_non_nullable
as SearchRemoteTrack?,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as num,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SearchItemSource,track: freezed == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as SearchTrack?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of SearchItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchAlbumCopyWith<$Res>? get album {
    if (_self.album == null) {
    return null;
  }

  return $SearchAlbumCopyWith<$Res>(_self.album!, (value) {
    return _then(_self.copyWith(album: value));
  });
}/// Create a copy of SearchItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchArtistCopyWith<$Res>? get artist {
    if (_self.artist == null) {
    return null;
  }

  return $SearchArtistCopyWith<$Res>(_self.artist!, (value) {
    return _then(_self.copyWith(artist: value));
  });
}/// Create a copy of SearchItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DiscoverResultCopyWith<$Res>? get catalogue {
    if (_self.catalogue == null) {
    return null;
  }

  return $DiscoverResultCopyWith<$Res>(_self.catalogue!, (value) {
    return _then(_self.copyWith(catalogue: value));
  });
}/// Create a copy of SearchItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaylistSummaryCopyWith<$Res>? get playlist {
    if (_self.playlist == null) {
    return null;
  }

  return $PlaylistSummaryCopyWith<$Res>(_self.playlist!, (value) {
    return _then(_self.copyWith(playlist: value));
  });
}/// Create a copy of SearchItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchPodcastCopyWith<$Res>? get podcast {
    if (_self.podcast == null) {
    return null;
  }

  return $SearchPodcastCopyWith<$Res>(_self.podcast!, (value) {
    return _then(_self.copyWith(podcast: value));
  });
}/// Create a copy of SearchItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchRemoteAlbumCopyWith<$Res>? get remoteAlbum {
    if (_self.remoteAlbum == null) {
    return null;
  }

  return $SearchRemoteAlbumCopyWith<$Res>(_self.remoteAlbum!, (value) {
    return _then(_self.copyWith(remoteAlbum: value));
  });
}/// Create a copy of SearchItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchRemoteTrackCopyWith<$Res>? get remoteTrack {
    if (_self.remoteTrack == null) {
    return null;
  }

  return $SearchRemoteTrackCopyWith<$Res>(_self.remoteTrack!, (value) {
    return _then(_self.copyWith(remoteTrack: value));
  });
}/// Create a copy of SearchItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchTrackCopyWith<$Res>? get track {
    if (_self.track == null) {
    return null;
  }

  return $SearchTrackCopyWith<$Res>(_self.track!, (value) {
    return _then(_self.copyWith(track: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchItem].
extension SearchItemPatterns on SearchItem {
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
