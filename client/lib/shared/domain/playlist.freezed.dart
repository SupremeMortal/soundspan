// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlaylistSummary {

/// The server's playlist id.
 String get id;/// The playlist name.
 String get name;/// The number of tracks.
 int get trackCount;/// Whether the signed-in user owns the playlist.
 bool get isOwner;/// Whether the playlist is public.
 bool get isPublic;/// Up to four values to pass to the cover-art endpoint, for the mosaic.
 List<String> get coverRefs;
/// Create a copy of PlaylistSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistSummaryCopyWith<PlaylistSummary> get copyWith => _$PlaylistSummaryCopyWithImpl<PlaylistSummary>(this as PlaylistSummary, _$identity);

  /// Serializes this PlaylistSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlaylistSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.trackCount, _this.trackCount) || other.trackCount == _this.trackCount)&&(identical(other.isOwner, _this.isOwner) || other.isOwner == _this.isOwner)&&(identical(other.isPublic, _this.isPublic) || other.isPublic == _this.isPublic)&&const DeepCollectionEquality().equals(other.coverRefs, _this.coverRefs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlaylistSummary;
  return Object.hash(runtimeType,_this.id,_this.name,_this.trackCount,_this.isOwner,_this.isPublic,const DeepCollectionEquality().hash(_this.coverRefs));
}

@override
String toString() {
  final _this = this as PlaylistSummary;
  return 'PlaylistSummary(id: ${_this.id}, name: ${_this.name}, trackCount: ${_this.trackCount}, isOwner: ${_this.isOwner}, isPublic: ${_this.isPublic}, coverRefs: ${_this.coverRefs})';
}


}

/// @nodoc
abstract mixin class $PlaylistSummaryCopyWith<$Res>  {
  factory $PlaylistSummaryCopyWith(PlaylistSummary value, $Res Function(PlaylistSummary) _then) = _$PlaylistSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String name, int trackCount, bool isOwner, bool isPublic, List<String> coverRefs
});




}
/// @nodoc
class _$PlaylistSummaryCopyWithImpl<$Res>
    implements $PlaylistSummaryCopyWith<$Res> {
  _$PlaylistSummaryCopyWithImpl(this._self, this._then);

  final PlaylistSummary _self;
  final $Res Function(PlaylistSummary) _then;

/// Create a copy of PlaylistSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? trackCount = null,Object? isOwner = null,Object? isPublic = null,Object? coverRefs = null,}) {
  return _then(PlaylistSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,isOwner: null == isOwner ? _self.isOwner : isOwner // ignore: cast_nullable_to_non_nullable
as bool,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,coverRefs: null == coverRefs ? _self.coverRefs : coverRefs // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaylistSummary].
extension PlaylistSummaryPatterns on PlaylistSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaylistSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaylistSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaylistSummary value)  $default,){
final _that = this;
switch (_that) {
case _PlaylistSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaylistSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PlaylistSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int trackCount,  bool isOwner,  bool isPublic,  List<String> coverRefs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaylistSummary() when $default != null:
return $default(_that.id,_that.name,_that.trackCount,_that.isOwner,_that.isPublic,_that.coverRefs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int trackCount,  bool isOwner,  bool isPublic,  List<String> coverRefs)  $default,) {final _that = this;
switch (_that) {
case _PlaylistSummary():
return $default(_that.id,_that.name,_that.trackCount,_that.isOwner,_that.isPublic,_that.coverRefs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int trackCount,  bool isOwner,  bool isPublic,  List<String> coverRefs)?  $default,) {final _that = this;
switch (_that) {
case _PlaylistSummary() when $default != null:
return $default(_that.id,_that.name,_that.trackCount,_that.isOwner,_that.isPublic,_that.coverRefs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaylistSummary implements PlaylistSummary {
  const _PlaylistSummary({required this.id, required this.name, required this.trackCount, required this.isOwner, required this.isPublic,  List<String> coverRefs = const <String>[]}): _coverRefs = coverRefs;
  factory _PlaylistSummary.fromJson(Map<String, dynamic> json) => _$PlaylistSummaryFromJson(json);

/// The server's playlist id.
@override final  String id;
/// The playlist name.
@override final  String name;
/// The number of tracks.
@override final  int trackCount;
/// Whether the signed-in user owns the playlist.
@override final  bool isOwner;
/// Whether the playlist is public.
@override final  bool isPublic;
/// Up to four values to pass to the cover-art endpoint, for the mosaic.
 final  List<String> _coverRefs;
/// Up to four values to pass to the cover-art endpoint, for the mosaic.
@override@JsonKey() List<String> get coverRefs {
  if (_coverRefs is EqualUnmodifiableListView) return _coverRefs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_coverRefs);
}


/// Create a copy of PlaylistSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaylistSummaryCopyWith<_PlaylistSummary> get copyWith => __$PlaylistSummaryCopyWithImpl<_PlaylistSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaylistSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaylistSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.trackCount, trackCount) || other.trackCount == trackCount)&&(identical(other.isOwner, isOwner) || other.isOwner == isOwner)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&const DeepCollectionEquality().equals(other.coverRefs, _coverRefs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,trackCount,isOwner,isPublic,const DeepCollectionEquality().hash(_coverRefs));
}

@override
String toString() {
    return 'PlaylistSummary(id: $id, name: $name, trackCount: $trackCount, isOwner: $isOwner, isPublic: $isPublic, coverRefs: $coverRefs)';
}


}

/// @nodoc
abstract mixin class _$PlaylistSummaryCopyWith<$Res> implements $PlaylistSummaryCopyWith<$Res> {
  factory _$PlaylistSummaryCopyWith(_PlaylistSummary value, $Res Function(_PlaylistSummary) _then) = __$PlaylistSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int trackCount, bool isOwner, bool isPublic, List<String> coverRefs
});




}
/// @nodoc
class __$PlaylistSummaryCopyWithImpl<$Res>
    implements _$PlaylistSummaryCopyWith<$Res> {
  __$PlaylistSummaryCopyWithImpl(this._self, this._then);

  final _PlaylistSummary _self;
  final $Res Function(_PlaylistSummary) _then;

/// Create a copy of PlaylistSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? trackCount = null,Object? isOwner = null,Object? isPublic = null,Object? coverRefs = null,}) {
  return _then(_PlaylistSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,isOwner: null == isOwner ? _self.isOwner : isOwner // ignore: cast_nullable_to_non_nullable
as bool,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,coverRefs: null == coverRefs ? _self._coverRefs : coverRefs // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$PlaylistItem {

/// The server's item id.
 String get id;/// The item's position key; items are listed in ascending order.
 int get sort;/// The track.
 Track get track;/// Whether the server can play the item; a row that cannot is shown
/// disabled.
 bool get isPlayable;/// The server's explanation when the item cannot be played.
 String? get message;/// The `opUuid` of the pending add that shows this item before the
/// server has it; null for an item the server sent.
 String? get pendingOpUuid;
/// Create a copy of PlaylistItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistItemCopyWith<PlaylistItem> get copyWith => _$PlaylistItemCopyWithImpl<PlaylistItem>(this as PlaylistItem, _$identity);

  /// Serializes this PlaylistItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlaylistItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.sort, _this.sort) || other.sort == _this.sort)&&(identical(other.track, _this.track) || other.track == _this.track)&&(identical(other.isPlayable, _this.isPlayable) || other.isPlayable == _this.isPlayable)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.pendingOpUuid, _this.pendingOpUuid) || other.pendingOpUuid == _this.pendingOpUuid));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlaylistItem;
  return Object.hash(runtimeType,_this.id,_this.sort,_this.track,_this.isPlayable,_this.message,_this.pendingOpUuid);
}

@override
String toString() {
  final _this = this as PlaylistItem;
  return 'PlaylistItem(id: ${_this.id}, sort: ${_this.sort}, track: ${_this.track}, isPlayable: ${_this.isPlayable}, message: ${_this.message}, pendingOpUuid: ${_this.pendingOpUuid})';
}


}

/// @nodoc
abstract mixin class $PlaylistItemCopyWith<$Res>  {
  factory $PlaylistItemCopyWith(PlaylistItem value, $Res Function(PlaylistItem) _then) = _$PlaylistItemCopyWithImpl;
@useResult
$Res call({
 String id, int sort, Track track, bool isPlayable, String? message, String? pendingOpUuid
});


$TrackCopyWith<$Res> get track;

}
/// @nodoc
class _$PlaylistItemCopyWithImpl<$Res>
    implements $PlaylistItemCopyWith<$Res> {
  _$PlaylistItemCopyWithImpl(this._self, this._then);

  final PlaylistItem _self;
  final $Res Function(PlaylistItem) _then;

/// Create a copy of PlaylistItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sort = null,Object? track = null,Object? isPlayable = null,Object? message = freezed,Object? pendingOpUuid = freezed,}) {
  return _then(PlaylistItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as int,track: null == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as Track,isPlayable: null == isPlayable ? _self.isPlayable : isPlayable // ignore: cast_nullable_to_non_nullable
as bool,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,pendingOpUuid: freezed == pendingOpUuid ? _self.pendingOpUuid : pendingOpUuid // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PlaylistItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackCopyWith<$Res> get track {
  
  return $TrackCopyWith<$Res>(_self.track, (value) {
    return _then(_self.copyWith(track: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlaylistItem].
extension PlaylistItemPatterns on PlaylistItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaylistItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaylistItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaylistItem value)  $default,){
final _that = this;
switch (_that) {
case _PlaylistItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaylistItem value)?  $default,){
final _that = this;
switch (_that) {
case _PlaylistItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int sort,  Track track,  bool isPlayable,  String? message,  String? pendingOpUuid)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaylistItem() when $default != null:
return $default(_that.id,_that.sort,_that.track,_that.isPlayable,_that.message,_that.pendingOpUuid);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int sort,  Track track,  bool isPlayable,  String? message,  String? pendingOpUuid)  $default,) {final _that = this;
switch (_that) {
case _PlaylistItem():
return $default(_that.id,_that.sort,_that.track,_that.isPlayable,_that.message,_that.pendingOpUuid);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int sort,  Track track,  bool isPlayable,  String? message,  String? pendingOpUuid)?  $default,) {final _that = this;
switch (_that) {
case _PlaylistItem() when $default != null:
return $default(_that.id,_that.sort,_that.track,_that.isPlayable,_that.message,_that.pendingOpUuid);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaylistItem implements PlaylistItem {
  const _PlaylistItem({required this.id, required this.sort, required this.track, required this.isPlayable, this.message, this.pendingOpUuid});
  factory _PlaylistItem.fromJson(Map<String, dynamic> json) => _$PlaylistItemFromJson(json);

/// The server's item id.
@override final  String id;
/// The item's position key; items are listed in ascending order.
@override final  int sort;
/// The track.
@override final  Track track;
/// Whether the server can play the item; a row that cannot is shown
/// disabled.
@override final  bool isPlayable;
/// The server's explanation when the item cannot be played.
@override final  String? message;
/// The `opUuid` of the pending add that shows this item before the
/// server has it; null for an item the server sent.
@override final  String? pendingOpUuid;

/// Create a copy of PlaylistItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaylistItemCopyWith<_PlaylistItem> get copyWith => __$PlaylistItemCopyWithImpl<_PlaylistItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaylistItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaylistItem&&(identical(other.id, id) || other.id == id)&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.track, track) || other.track == track)&&(identical(other.isPlayable, isPlayable) || other.isPlayable == isPlayable)&&(identical(other.message, message) || other.message == message)&&(identical(other.pendingOpUuid, pendingOpUuid) || other.pendingOpUuid == pendingOpUuid));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,sort,track,isPlayable,message,pendingOpUuid);
}

@override
String toString() {
    return 'PlaylistItem(id: $id, sort: $sort, track: $track, isPlayable: $isPlayable, message: $message, pendingOpUuid: $pendingOpUuid)';
}


}

/// @nodoc
abstract mixin class _$PlaylistItemCopyWith<$Res> implements $PlaylistItemCopyWith<$Res> {
  factory _$PlaylistItemCopyWith(_PlaylistItem value, $Res Function(_PlaylistItem) _then) = __$PlaylistItemCopyWithImpl;
@override @useResult
$Res call({
 String id, int sort, Track track, bool isPlayable, String? message, String? pendingOpUuid
});


@override $TrackCopyWith<$Res> get track;

}
/// @nodoc
class __$PlaylistItemCopyWithImpl<$Res>
    implements _$PlaylistItemCopyWith<$Res> {
  __$PlaylistItemCopyWithImpl(this._self, this._then);

  final _PlaylistItem _self;
  final $Res Function(_PlaylistItem) _then;

/// Create a copy of PlaylistItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sort = null,Object? track = null,Object? isPlayable = null,Object? message = freezed,Object? pendingOpUuid = freezed,}) {
  return _then(_PlaylistItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as int,track: null == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as Track,isPlayable: null == isPlayable ? _self.isPlayable : isPlayable // ignore: cast_nullable_to_non_nullable
as bool,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,pendingOpUuid: freezed == pendingOpUuid ? _self.pendingOpUuid : pendingOpUuid // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PlaylistItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackCopyWith<$Res> get track {
  
  return $TrackCopyWith<$Res>(_self.track, (value) {
    return _then(_self.copyWith(track: value));
  });
}
}


/// @nodoc
mixin _$PlaylistDetail {

/// The playlist.
 PlaylistSummary get summary;/// The items in ascending [PlaylistItem.sort] order.
 List<PlaylistItem> get items;
/// Create a copy of PlaylistDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistDetailCopyWith<PlaylistDetail> get copyWith => _$PlaylistDetailCopyWithImpl<PlaylistDetail>(this as PlaylistDetail, _$identity);

  /// Serializes this PlaylistDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlaylistDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistDetail&&(identical(other.summary, _this.summary) || other.summary == _this.summary)&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlaylistDetail;
  return Object.hash(runtimeType,_this.summary,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as PlaylistDetail;
  return 'PlaylistDetail(summary: ${_this.summary}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $PlaylistDetailCopyWith<$Res>  {
  factory $PlaylistDetailCopyWith(PlaylistDetail value, $Res Function(PlaylistDetail) _then) = _$PlaylistDetailCopyWithImpl;
@useResult
$Res call({
 PlaylistSummary summary, List<PlaylistItem> items
});


$PlaylistSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$PlaylistDetailCopyWithImpl<$Res>
    implements $PlaylistDetailCopyWith<$Res> {
  _$PlaylistDetailCopyWithImpl(this._self, this._then);

  final PlaylistDetail _self;
  final $Res Function(PlaylistDetail) _then;

/// Create a copy of PlaylistDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summary = null,Object? items = null,}) {
  return _then(PlaylistDetail(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as PlaylistSummary,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<PlaylistItem>,
  ));
}
/// Create a copy of PlaylistDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaylistSummaryCopyWith<$Res> get summary {
  
  return $PlaylistSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlaylistDetail].
extension PlaylistDetailPatterns on PlaylistDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaylistDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaylistDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaylistDetail value)  $default,){
final _that = this;
switch (_that) {
case _PlaylistDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaylistDetail value)?  $default,){
final _that = this;
switch (_that) {
case _PlaylistDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlaylistSummary summary,  List<PlaylistItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaylistDetail() when $default != null:
return $default(_that.summary,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlaylistSummary summary,  List<PlaylistItem> items)  $default,) {final _that = this;
switch (_that) {
case _PlaylistDetail():
return $default(_that.summary,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlaylistSummary summary,  List<PlaylistItem> items)?  $default,) {final _that = this;
switch (_that) {
case _PlaylistDetail() when $default != null:
return $default(_that.summary,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaylistDetail implements PlaylistDetail {
  const _PlaylistDetail({required this.summary, required  List<PlaylistItem> items}): _items = items;
  factory _PlaylistDetail.fromJson(Map<String, dynamic> json) => _$PlaylistDetailFromJson(json);

/// The playlist.
@override final  PlaylistSummary summary;
/// The items in ascending [PlaylistItem.sort] order.
 final  List<PlaylistItem> _items;
/// The items in ascending [PlaylistItem.sort] order.
@override List<PlaylistItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of PlaylistDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaylistDetailCopyWith<_PlaylistDetail> get copyWith => __$PlaylistDetailCopyWithImpl<_PlaylistDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaylistDetailToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaylistDetail&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,summary,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'PlaylistDetail(summary: $summary, items: $items)';
}


}

/// @nodoc
abstract mixin class _$PlaylistDetailCopyWith<$Res> implements $PlaylistDetailCopyWith<$Res> {
  factory _$PlaylistDetailCopyWith(_PlaylistDetail value, $Res Function(_PlaylistDetail) _then) = __$PlaylistDetailCopyWithImpl;
@override @useResult
$Res call({
 PlaylistSummary summary, List<PlaylistItem> items
});


@override $PlaylistSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class __$PlaylistDetailCopyWithImpl<$Res>
    implements _$PlaylistDetailCopyWith<$Res> {
  __$PlaylistDetailCopyWithImpl(this._self, this._then);

  final _PlaylistDetail _self;
  final $Res Function(_PlaylistDetail) _then;

/// Create a copy of PlaylistDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summary = null,Object? items = null,}) {
  return _then(_PlaylistDetail(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as PlaylistSummary,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PlaylistItem>,
  ));
}

/// Create a copy of PlaylistDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaylistSummaryCopyWith<$Res> get summary {
  
  return $PlaylistSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}

// dart format on
