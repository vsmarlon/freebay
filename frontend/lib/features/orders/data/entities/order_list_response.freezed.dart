// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_list_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrderListResponse {

 List<OrderEntity> get orders; int get total; int get limit; int get offset;
/// Create a copy of OrderListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderListResponseCopyWith<OrderListResponse> get copyWith => _$OrderListResponseCopyWithImpl<OrderListResponse>(this as OrderListResponse, _$identity);

  /// Serializes this OrderListResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderListResponse&&const DeepCollectionEquality().equals(other.orders, orders)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.offset, offset) || other.offset == offset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(orders),total,limit,offset);

@override
String toString() {
  return 'OrderListResponse(orders: $orders, total: $total, limit: $limit, offset: $offset)';
}


}

/// @nodoc
abstract mixin class $OrderListResponseCopyWith<$Res>  {
  factory $OrderListResponseCopyWith(OrderListResponse value, $Res Function(OrderListResponse) _then) = _$OrderListResponseCopyWithImpl;
@useResult
$Res call({
 List<OrderEntity> orders, int total, int limit, int offset
});




}
/// @nodoc
class _$OrderListResponseCopyWithImpl<$Res>
    implements $OrderListResponseCopyWith<$Res> {
  _$OrderListResponseCopyWithImpl(this._self, this._then);

  final OrderListResponse _self;
  final $Res Function(OrderListResponse) _then;

/// Create a copy of OrderListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orders = null,Object? total = null,Object? limit = null,Object? offset = null,}) {
  return _then(_self.copyWith(
orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as List<OrderEntity>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderListResponse].
extension OrderListResponsePatterns on OrderListResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderListResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderListResponse value)  $default,){
final _that = this;
switch (_that) {
case _OrderListResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _OrderListResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<OrderEntity> orders,  int total,  int limit,  int offset)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderListResponse() when $default != null:
return $default(_that.orders,_that.total,_that.limit,_that.offset);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<OrderEntity> orders,  int total,  int limit,  int offset)  $default,) {final _that = this;
switch (_that) {
case _OrderListResponse():
return $default(_that.orders,_that.total,_that.limit,_that.offset);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<OrderEntity> orders,  int total,  int limit,  int offset)?  $default,) {final _that = this;
switch (_that) {
case _OrderListResponse() when $default != null:
return $default(_that.orders,_that.total,_that.limit,_that.offset);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderListResponse extends OrderListResponse {
  const _OrderListResponse({final  List<OrderEntity> orders = const [], this.total = 0, this.limit = 10, this.offset = 0}): _orders = orders,super._();
  factory _OrderListResponse.fromJson(Map<String, dynamic> json) => _$OrderListResponseFromJson(json);

 final  List<OrderEntity> _orders;
@override@JsonKey() List<OrderEntity> get orders {
  if (_orders is EqualUnmodifiableListView) return _orders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orders);
}

@override@JsonKey() final  int total;
@override@JsonKey() final  int limit;
@override@JsonKey() final  int offset;

/// Create a copy of OrderListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderListResponseCopyWith<_OrderListResponse> get copyWith => __$OrderListResponseCopyWithImpl<_OrderListResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderListResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderListResponse&&const DeepCollectionEquality().equals(other._orders, _orders)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.offset, offset) || other.offset == offset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_orders),total,limit,offset);

@override
String toString() {
  return 'OrderListResponse(orders: $orders, total: $total, limit: $limit, offset: $offset)';
}


}

/// @nodoc
abstract mixin class _$OrderListResponseCopyWith<$Res> implements $OrderListResponseCopyWith<$Res> {
  factory _$OrderListResponseCopyWith(_OrderListResponse value, $Res Function(_OrderListResponse) _then) = __$OrderListResponseCopyWithImpl;
@override @useResult
$Res call({
 List<OrderEntity> orders, int total, int limit, int offset
});




}
/// @nodoc
class __$OrderListResponseCopyWithImpl<$Res>
    implements _$OrderListResponseCopyWith<$Res> {
  __$OrderListResponseCopyWithImpl(this._self, this._then);

  final _OrderListResponse _self;
  final $Res Function(_OrderListResponse) _then;

/// Create a copy of OrderListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orders = null,Object? total = null,Object? limit = null,Object? offset = null,}) {
  return _then(_OrderListResponse(
orders: null == orders ? _self._orders : orders // ignore: cast_nullable_to_non_nullable
as List<OrderEntity>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
