// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'last_message_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LastMessageInfo {

 String get content; DateTime get createdAt;
/// Create a copy of LastMessageInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LastMessageInfoCopyWith<LastMessageInfo> get copyWith => _$LastMessageInfoCopyWithImpl<LastMessageInfo>(this as LastMessageInfo, _$identity);

  /// Serializes this LastMessageInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LastMessageInfo&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,createdAt);

@override
String toString() {
  return 'LastMessageInfo(content: $content, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $LastMessageInfoCopyWith<$Res>  {
  factory $LastMessageInfoCopyWith(LastMessageInfo value, $Res Function(LastMessageInfo) _then) = _$LastMessageInfoCopyWithImpl;
@useResult
$Res call({
 String content, DateTime createdAt
});




}
/// @nodoc
class _$LastMessageInfoCopyWithImpl<$Res>
    implements $LastMessageInfoCopyWith<$Res> {
  _$LastMessageInfoCopyWithImpl(this._self, this._then);

  final LastMessageInfo _self;
  final $Res Function(LastMessageInfo) _then;

/// Create a copy of LastMessageInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [LastMessageInfo].
extension LastMessageInfoPatterns on LastMessageInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LastMessageInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LastMessageInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LastMessageInfo value)  $default,){
final _that = this;
switch (_that) {
case _LastMessageInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LastMessageInfo value)?  $default,){
final _that = this;
switch (_that) {
case _LastMessageInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String content,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LastMessageInfo() when $default != null:
return $default(_that.content,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String content,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _LastMessageInfo():
return $default(_that.content,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String content,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _LastMessageInfo() when $default != null:
return $default(_that.content,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LastMessageInfo implements LastMessageInfo {
  const _LastMessageInfo({required this.content, required this.createdAt});
  factory _LastMessageInfo.fromJson(Map<String, dynamic> json) => _$LastMessageInfoFromJson(json);

@override final  String content;
@override final  DateTime createdAt;

/// Create a copy of LastMessageInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LastMessageInfoCopyWith<_LastMessageInfo> get copyWith => __$LastMessageInfoCopyWithImpl<_LastMessageInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LastMessageInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LastMessageInfo&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,createdAt);

@override
String toString() {
  return 'LastMessageInfo(content: $content, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$LastMessageInfoCopyWith<$Res> implements $LastMessageInfoCopyWith<$Res> {
  factory _$LastMessageInfoCopyWith(_LastMessageInfo value, $Res Function(_LastMessageInfo) _then) = __$LastMessageInfoCopyWithImpl;
@override @useResult
$Res call({
 String content, DateTime createdAt
});




}
/// @nodoc
class __$LastMessageInfoCopyWithImpl<$Res>
    implements _$LastMessageInfoCopyWith<$Res> {
  __$LastMessageInfoCopyWithImpl(this._self, this._then);

  final _LastMessageInfo _self;
  final $Res Function(_LastMessageInfo) _then;

/// Create a copy of LastMessageInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? createdAt = null,}) {
  return _then(_LastMessageInfo(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
