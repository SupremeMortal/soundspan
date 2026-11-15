// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'queue_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QueueState {

/// The entries in canonical (unshuffled) order.
 List<QueueItem> get items;/// A permutation of indices into [items] when shuffle is on.
 List<int>? get shuffleOrder;/// Index into [playOrder] of the current item; null when empty.
 int? get cursor;/// The repeat mode.
 RepeatMode get repeat;/// What "Play" was pressed on.
 QueueContext? get context;/// Incremented by one on every change.
 int get revision;
/// Create a copy of QueueState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueStateCopyWith<QueueState> get copyWith => _$QueueStateCopyWithImpl<QueueState>(this as QueueState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as QueueState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueState&&const DeepCollectionEquality().equals(other.items, _this.items)&&const DeepCollectionEquality().equals(other.shuffleOrder, _this.shuffleOrder)&&(identical(other.cursor, _this.cursor) || other.cursor == _this.cursor)&&(identical(other.repeat, _this.repeat) || other.repeat == _this.repeat)&&(identical(other.context, _this.context) || other.context == _this.context)&&(identical(other.revision, _this.revision) || other.revision == _this.revision));
}


@override
int get hashCode {
  final _this = this as QueueState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),const DeepCollectionEquality().hash(_this.shuffleOrder),_this.cursor,_this.repeat,_this.context,_this.revision);
}

@override
String toString() {
  final _this = this as QueueState;
  return 'QueueState(items: ${_this.items}, shuffleOrder: ${_this.shuffleOrder}, cursor: ${_this.cursor}, repeat: ${_this.repeat}, context: ${_this.context}, revision: ${_this.revision})';
}


}

/// @nodoc
abstract mixin class $QueueStateCopyWith<$Res>  {
  factory $QueueStateCopyWith(QueueState value, $Res Function(QueueState) _then) = _$QueueStateCopyWithImpl;
@useResult
$Res call({
 List<QueueItem> items, List<int>? shuffleOrder, int? cursor, RepeatMode repeat, QueueContext? context, int revision
});


$QueueContextCopyWith<$Res>? get context;

}
/// @nodoc
class _$QueueStateCopyWithImpl<$Res>
    implements $QueueStateCopyWith<$Res> {
  _$QueueStateCopyWithImpl(this._self, this._then);

  final QueueState _self;
  final $Res Function(QueueState) _then;

/// Create a copy of QueueState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? shuffleOrder = freezed,Object? cursor = freezed,Object? repeat = null,Object? context = freezed,Object? revision = null,}) {
  return _then(QueueState(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<QueueItem>,shuffleOrder: freezed == shuffleOrder ? _self.shuffleOrder : shuffleOrder // ignore: cast_nullable_to_non_nullable
as List<int>?,cursor: freezed == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as int?,repeat: null == repeat ? _self.repeat : repeat // ignore: cast_nullable_to_non_nullable
as RepeatMode,context: freezed == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as QueueContext?,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of QueueState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QueueContextCopyWith<$Res>? get context {
    if (_self.context == null) {
    return null;
  }

  return $QueueContextCopyWith<$Res>(_self.context!, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}


/// Adds pattern-matching-related methods to [QueueState].
extension QueueStatePatterns on QueueState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueueState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueueState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueueState value)  $default,){
final _that = this;
switch (_that) {
case _QueueState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueueState value)?  $default,){
final _that = this;
switch (_that) {
case _QueueState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<QueueItem> items,  List<int>? shuffleOrder,  int? cursor,  RepeatMode repeat,  QueueContext? context,  int revision)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueueState() when $default != null:
return $default(_that.items,_that.shuffleOrder,_that.cursor,_that.repeat,_that.context,_that.revision);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<QueueItem> items,  List<int>? shuffleOrder,  int? cursor,  RepeatMode repeat,  QueueContext? context,  int revision)  $default,) {final _that = this;
switch (_that) {
case _QueueState():
return $default(_that.items,_that.shuffleOrder,_that.cursor,_that.repeat,_that.context,_that.revision);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<QueueItem> items,  List<int>? shuffleOrder,  int? cursor,  RepeatMode repeat,  QueueContext? context,  int revision)?  $default,) {final _that = this;
switch (_that) {
case _QueueState() when $default != null:
return $default(_that.items,_that.shuffleOrder,_that.cursor,_that.repeat,_that.context,_that.revision);case _:
  return null;

}
}

}

/// @nodoc


class _QueueState extends QueueState {
  const _QueueState({ List<QueueItem> items = const <QueueItem>[],  List<int>? shuffleOrder, this.cursor, this.repeat = RepeatMode.off, this.context, this.revision = 0}): _items = items,_shuffleOrder = shuffleOrder,super._();
  

/// The entries in canonical (unshuffled) order.
 final  List<QueueItem> _items;
/// The entries in canonical (unshuffled) order.
@override@JsonKey() List<QueueItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// A permutation of indices into [items] when shuffle is on.
 final  List<int>? _shuffleOrder;
/// A permutation of indices into [items] when shuffle is on.
@override List<int>? get shuffleOrder {
  final value = _shuffleOrder;
  if (value == null) return null;
  if (_shuffleOrder is EqualUnmodifiableListView) return _shuffleOrder;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Index into [playOrder] of the current item; null when empty.
@override final  int? cursor;
/// The repeat mode.
@override@JsonKey() final  RepeatMode repeat;
/// What "Play" was pressed on.
@override final  QueueContext? context;
/// Incremented by one on every change.
@override@JsonKey() final  int revision;

/// Create a copy of QueueState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueStateCopyWith<_QueueState> get copyWith => __$QueueStateCopyWithImpl<_QueueState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueueState&&const DeepCollectionEquality().equals(other.items, _items)&&const DeepCollectionEquality().equals(other.shuffleOrder, _shuffleOrder)&&(identical(other.cursor, cursor) || other.cursor == cursor)&&(identical(other.repeat, repeat) || other.repeat == repeat)&&(identical(other.context, context) || other.context == context)&&(identical(other.revision, revision) || other.revision == revision));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_shuffleOrder),cursor,repeat,context,revision);
}

@override
String toString() {
    return 'QueueState(items: $items, shuffleOrder: $shuffleOrder, cursor: $cursor, repeat: $repeat, context: $context, revision: $revision)';
}


}

/// @nodoc
abstract mixin class _$QueueStateCopyWith<$Res> implements $QueueStateCopyWith<$Res> {
  factory _$QueueStateCopyWith(_QueueState value, $Res Function(_QueueState) _then) = __$QueueStateCopyWithImpl;
@override @useResult
$Res call({
 List<QueueItem> items, List<int>? shuffleOrder, int? cursor, RepeatMode repeat, QueueContext? context, int revision
});


@override $QueueContextCopyWith<$Res>? get context;

}
/// @nodoc
class __$QueueStateCopyWithImpl<$Res>
    implements _$QueueStateCopyWith<$Res> {
  __$QueueStateCopyWithImpl(this._self, this._then);

  final _QueueState _self;
  final $Res Function(_QueueState) _then;

/// Create a copy of QueueState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? shuffleOrder = freezed,Object? cursor = freezed,Object? repeat = null,Object? context = freezed,Object? revision = null,}) {
  return _then(_QueueState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<QueueItem>,shuffleOrder: freezed == shuffleOrder ? _self._shuffleOrder : shuffleOrder // ignore: cast_nullable_to_non_nullable
as List<int>?,cursor: freezed == cursor ? _self.cursor : cursor // ignore: cast_nullable_to_non_nullable
as int?,repeat: null == repeat ? _self.repeat : repeat // ignore: cast_nullable_to_non_nullable
as RepeatMode,context: freezed == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as QueueContext?,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of QueueState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QueueContextCopyWith<$Res>? get context {
    if (_self.context == null) {
    return null;
  }

  return $QueueContextCopyWith<$Res>(_self.context!, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}

// dart format on
