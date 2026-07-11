// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrderInfo {

 String get status;
/// Create a copy of OrderInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderInfoCopyWith<OrderInfo> get copyWith => _$OrderInfoCopyWithImpl<OrderInfo>(this as OrderInfo, _$identity);

  /// Serializes this OrderInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderInfo&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'OrderInfo(status: $status)';
}


}

/// @nodoc
abstract mixin class $OrderInfoCopyWith<$Res>  {
  factory $OrderInfoCopyWith(OrderInfo value, $Res Function(OrderInfo) _then) = _$OrderInfoCopyWithImpl;
@useResult
$Res call({
 String status
});




}
/// @nodoc
class _$OrderInfoCopyWithImpl<$Res>
    implements $OrderInfoCopyWith<$Res> {
  _$OrderInfoCopyWithImpl(this._self, this._then);

  final OrderInfo _self;
  final $Res Function(OrderInfo) _then;

/// Create a copy of OrderInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderInfo].
extension OrderInfoPatterns on OrderInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderInfo value)  $default,){
final _that = this;
switch (_that) {
case _OrderInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderInfo value)?  $default,){
final _that = this;
switch (_that) {
case _OrderInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderInfo() when $default != null:
return $default(_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status)  $default,) {final _that = this;
switch (_that) {
case _OrderInfo():
return $default(_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status)?  $default,) {final _that = this;
switch (_that) {
case _OrderInfo() when $default != null:
return $default(_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderInfo implements OrderInfo {
  const _OrderInfo({required this.status});
  factory _OrderInfo.fromJson(Map<String, dynamic> json) => _$OrderInfoFromJson(json);

@override final  String status;

/// Create a copy of OrderInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderInfoCopyWith<_OrderInfo> get copyWith => __$OrderInfoCopyWithImpl<_OrderInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderInfo&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'OrderInfo(status: $status)';
}


}

/// @nodoc
abstract mixin class _$OrderInfoCopyWith<$Res> implements $OrderInfoCopyWith<$Res> {
  factory _$OrderInfoCopyWith(_OrderInfo value, $Res Function(_OrderInfo) _then) = __$OrderInfoCopyWithImpl;
@override @useResult
$Res call({
 String status
});




}
/// @nodoc
class __$OrderInfoCopyWithImpl<$Res>
    implements _$OrderInfoCopyWith<$Res> {
  __$OrderInfoCopyWithImpl(this._self, this._then);

  final _OrderInfo _self;
  final $Res Function(_OrderInfo) _then;

/// Create a copy of OrderInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,}) {
  return _then(_OrderInfo(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
