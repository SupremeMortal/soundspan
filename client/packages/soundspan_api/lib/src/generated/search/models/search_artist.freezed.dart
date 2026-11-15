// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_artist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchArtist {


/// Create a copy of SearchArtist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchArtistCopyWith<SearchArtist> get copyWith => _$SearchArtistCopyWithImpl<SearchArtist>(this as SearchArtist, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SearchArtist;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchArtist&&(identical(other.heroUrl, _this.heroUrl) || other.heroUrl == _this.heroUrl)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.mbid, _this.mbid) || other.mbid == _this.mbid)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.peer, _this.peer) || other.peer == _this.peer)&&(identical(other.rank, _this.rank) || other.rank == _this.rank)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.summary, _this.summary) || other.summary == _this.summary)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as SearchArtist;
  return Object.hash(runtimeType,_this.heroUrl,_this.id,_this.mbid,_this.name,_this.peer,_this.rank,_this.source,_this.summary,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as SearchArtist;
  return 'SearchArtist(heroUrl: ${_this.heroUrl}, id: ${_this.id}, mbid: ${_this.mbid}, name: ${_this.name}, peer: ${_this.peer}, rank: ${_this.rank}, source: ${_this.source}, summary: ${_this.summary}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $SearchArtistCopyWith<$Res>  {
  factory $SearchArtistCopyWith(SearchArtist value, $Res Function(SearchArtist) _then) = _$SearchArtistCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true) String? heroUrl,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true) String? mbid,@JsonKey(required: true, disallowNullValue: true) String name,@JsonKey(includeIfNull: false) PeerRef? peer,@JsonKey(required: true, disallowNullValue: true) num rank,@JsonKey(disallowNullValue: true, includeIfNull: false, fromJson: SearchArtist._read_source, toJson: SearchArtist._write_source) SearchArtistSource? source,@JsonKey(includeIfNull: false) String? summary,@JsonKey(readValue: SearchArtist._extras, fromJson: SearchArtist._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$PeerRefCopyWith<$Res>? get peer;

}
/// @nodoc
class _$SearchArtistCopyWithImpl<$Res>
    implements $SearchArtistCopyWith<$Res> {
  _$SearchArtistCopyWithImpl(this._self, this._then);

  final SearchArtist _self;
  final $Res Function(SearchArtist) _then;

/// Create a copy of SearchArtist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? heroUrl = freezed,Object? id = null,Object? mbid = freezed,Object? name = null,Object? peer = freezed,Object? rank = null,Object? source = freezed,Object? summary = freezed,Object? additionalProperties = null,}) {
  return _then(SearchArtist(
heroUrl: freezed == heroUrl ? _self.heroUrl : heroUrl // ignore: cast_nullable_to_non_nullable
as String?,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mbid: freezed == mbid ? _self.mbid : mbid // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,peer: freezed == peer ? _self.peer : peer // ignore: cast_nullable_to_non_nullable
as PeerRef?,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as num,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SearchArtistSource?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of SearchArtist
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeerRefCopyWith<$Res>? get peer {
    if (_self.peer == null) {
    return null;
  }

  return $PeerRefCopyWith<$Res>(_self.peer!, (value) {
    return _then(_self.copyWith(peer: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchArtist].
extension SearchArtistPatterns on SearchArtist {
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
