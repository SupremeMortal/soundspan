// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'listen_group_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ListenGroupSummary {


/// Create a copy of ListenGroupSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListenGroupSummaryCopyWith<ListenGroupSummary> get copyWith => _$ListenGroupSummaryCopyWithImpl<ListenGroupSummary>(this as ListenGroupSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ListenGroupSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListenGroupSummary&&(identical(other.currentTrack, _this.currentTrack) || other.currentTrack == _this.currentTrack)&&(identical(other.groupType, _this.groupType) || other.groupType == _this.groupType)&&(identical(other.host, _this.host) || other.host == _this.host)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.isMember, _this.isMember) || other.isMember == _this.isMember)&&(identical(other.isPlaying, _this.isPlaying) || other.isPlaying == _this.isPlaying)&&(identical(other.joinCode, _this.joinCode) || other.joinCode == _this.joinCode)&&(identical(other.memberCount, _this.memberCount) || other.memberCount == _this.memberCount)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.visibility, _this.visibility) || other.visibility == _this.visibility)&&const DeepCollectionEquality().equals(other.additionalProperties, _this.additionalProperties));
}


@override
int get hashCode {
  final _this = this as ListenGroupSummary;
  return Object.hash(runtimeType,_this.currentTrack,_this.groupType,_this.host,_this.id,_this.isMember,_this.isPlaying,_this.joinCode,_this.memberCount,_this.name,_this.visibility,const DeepCollectionEquality().hash(_this.additionalProperties));
}

@override
String toString() {
  final _this = this as ListenGroupSummary;
  return 'ListenGroupSummary(currentTrack: ${_this.currentTrack}, groupType: ${_this.groupType}, host: ${_this.host}, id: ${_this.id}, isMember: ${_this.isMember}, isPlaying: ${_this.isPlaying}, joinCode: ${_this.joinCode}, memberCount: ${_this.memberCount}, name: ${_this.name}, visibility: ${_this.visibility}, additionalProperties: ${_this.additionalProperties})';
}


}

/// @nodoc
abstract mixin class $ListenGroupSummaryCopyWith<$Res>  {
  factory $ListenGroupSummaryCopyWith(ListenGroupSummary value, $Res Function(ListenGroupSummary) _then) = _$ListenGroupSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true) ListenGroupSummaryCurrentTrack? currentTrack,@JsonKey(required: true, disallowNullValue: true, fromJson: ListenGroupSummary._read_groupType, toJson: ListenGroupSummary._write_groupType) ListenGroupSummaryGroupType groupType,@JsonKey(required: true, disallowNullValue: true) ListenGroupSummaryHost host,@JsonKey(required: true, disallowNullValue: true) String id,@JsonKey(required: true, disallowNullValue: true) bool isMember,@JsonKey(required: true, disallowNullValue: true) bool isPlaying,@JsonKey(required: true, disallowNullValue: true) String joinCode,@JsonKey(required: true, disallowNullValue: true, fromJson: ListenGroupSummary._read_memberCount, toJson: ListenGroupSummary._write_memberCount) int memberCount,@JsonKey(required: true, disallowNullValue: true) String name,@JsonKey(required: true, disallowNullValue: true, fromJson: ListenGroupSummary._read_visibility, toJson: ListenGroupSummary._write_visibility) ListenGroupSummaryVisibility visibility,@JsonKey(readValue: ListenGroupSummary._extras, fromJson: ListenGroupSummary._readExtras, includeToJson: false) Map<String, Object?> additionalProperties
});


$ListenGroupSummaryCurrentTrackCopyWith<$Res>? get currentTrack;$ListenGroupSummaryHostCopyWith<$Res> get host;

}
/// @nodoc
class _$ListenGroupSummaryCopyWithImpl<$Res>
    implements $ListenGroupSummaryCopyWith<$Res> {
  _$ListenGroupSummaryCopyWithImpl(this._self, this._then);

  final ListenGroupSummary _self;
  final $Res Function(ListenGroupSummary) _then;

/// Create a copy of ListenGroupSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentTrack = freezed,Object? groupType = null,Object? host = null,Object? id = null,Object? isMember = null,Object? isPlaying = null,Object? joinCode = null,Object? memberCount = null,Object? name = null,Object? visibility = null,Object? additionalProperties = null,}) {
  return _then(ListenGroupSummary(
currentTrack: freezed == currentTrack ? _self.currentTrack : currentTrack // ignore: cast_nullable_to_non_nullable
as ListenGroupSummaryCurrentTrack?,groupType: null == groupType ? _self.groupType : groupType // ignore: cast_nullable_to_non_nullable
as ListenGroupSummaryGroupType,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as ListenGroupSummaryHost,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,isMember: null == isMember ? _self.isMember : isMember // ignore: cast_nullable_to_non_nullable
as bool,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,joinCode: null == joinCode ? _self.joinCode : joinCode // ignore: cast_nullable_to_non_nullable
as String,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as ListenGroupSummaryVisibility,additionalProperties: null == additionalProperties ? _self.additionalProperties : additionalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of ListenGroupSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ListenGroupSummaryCurrentTrackCopyWith<$Res>? get currentTrack {
    if (_self.currentTrack == null) {
    return null;
  }

  return $ListenGroupSummaryCurrentTrackCopyWith<$Res>(_self.currentTrack!, (value) {
    return _then(_self.copyWith(currentTrack: value));
  });
}/// Create a copy of ListenGroupSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ListenGroupSummaryHostCopyWith<$Res> get host {
  
  return $ListenGroupSummaryHostCopyWith<$Res>(_self.host, (value) {
    return _then(_self.copyWith(host: value));
  });
}
}


/// Adds pattern-matching-related methods to [ListenGroupSummary].
extension ListenGroupSummaryPatterns on ListenGroupSummary {
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
