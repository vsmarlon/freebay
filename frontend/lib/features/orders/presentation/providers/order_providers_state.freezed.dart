// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_providers_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderDetailState {

 bool get isLoading; OrderEntity? get order; CanReviewResponse? get canReviewResponse; String? get error; bool get isPerformingAction;
/// Create a copy of OrderDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderDetailStateCopyWith<OrderDetailState> get copyWith => _$OrderDetailStateCopyWithImpl<OrderDetailState>(this as OrderDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderDetailState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.order, order) || other.order == order)&&(identical(other.canReviewResponse, canReviewResponse) || other.canReviewResponse == canReviewResponse)&&(identical(other.error, error) || other.error == error)&&(identical(other.isPerformingAction, isPerformingAction) || other.isPerformingAction == isPerformingAction));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,order,canReviewResponse,error,isPerformingAction);

@override
String toString() {
  return 'OrderDetailState(isLoading: $isLoading, order: $order, canReviewResponse: $canReviewResponse, error: $error, isPerformingAction: $isPerformingAction)';
}


}

/// @nodoc
abstract mixin class $OrderDetailStateCopyWith<$Res>  {
  factory $OrderDetailStateCopyWith(OrderDetailState value, $Res Function(OrderDetailState) _then) = _$OrderDetailStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, OrderEntity? order, CanReviewResponse? canReviewResponse, String? error, bool isPerformingAction
});


$OrderEntityCopyWith<$Res>? get order;$CanReviewResponseCopyWith<$Res>? get canReviewResponse;

}
/// @nodoc
class _$OrderDetailStateCopyWithImpl<$Res>
    implements $OrderDetailStateCopyWith<$Res> {
  _$OrderDetailStateCopyWithImpl(this._self, this._then);

  final OrderDetailState _self;
  final $Res Function(OrderDetailState) _then;

/// Create a copy of OrderDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? order = freezed,Object? canReviewResponse = freezed,Object? error = freezed,Object? isPerformingAction = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as OrderEntity?,canReviewResponse: freezed == canReviewResponse ? _self.canReviewResponse : canReviewResponse // ignore: cast_nullable_to_non_nullable
as CanReviewResponse?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,isPerformingAction: null == isPerformingAction ? _self.isPerformingAction : isPerformingAction // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of OrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderEntityCopyWith<$Res>? get order {
    if (_self.order == null) {
    return null;
  }

  return $OrderEntityCopyWith<$Res>(_self.order!, (value) {
    return _then(_self.copyWith(order: value));
  });
}/// Create a copy of OrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CanReviewResponseCopyWith<$Res>? get canReviewResponse {
    if (_self.canReviewResponse == null) {
    return null;
  }

  return $CanReviewResponseCopyWith<$Res>(_self.canReviewResponse!, (value) {
    return _then(_self.copyWith(canReviewResponse: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrderDetailState].
extension OrderDetailStatePatterns on OrderDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderDetailState value)  $default,){
final _that = this;
switch (_that) {
case _OrderDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _OrderDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  OrderEntity? order,  CanReviewResponse? canReviewResponse,  String? error,  bool isPerformingAction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderDetailState() when $default != null:
return $default(_that.isLoading,_that.order,_that.canReviewResponse,_that.error,_that.isPerformingAction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  OrderEntity? order,  CanReviewResponse? canReviewResponse,  String? error,  bool isPerformingAction)  $default,) {final _that = this;
switch (_that) {
case _OrderDetailState():
return $default(_that.isLoading,_that.order,_that.canReviewResponse,_that.error,_that.isPerformingAction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  OrderEntity? order,  CanReviewResponse? canReviewResponse,  String? error,  bool isPerformingAction)?  $default,) {final _that = this;
switch (_that) {
case _OrderDetailState() when $default != null:
return $default(_that.isLoading,_that.order,_that.canReviewResponse,_that.error,_that.isPerformingAction);case _:
  return null;

}
}

}

/// @nodoc


class _OrderDetailState extends OrderDetailState {
  const _OrderDetailState({this.isLoading = false, this.order, this.canReviewResponse, this.error, this.isPerformingAction = false}): super._();
  

@override@JsonKey() final  bool isLoading;
@override final  OrderEntity? order;
@override final  CanReviewResponse? canReviewResponse;
@override final  String? error;
@override@JsonKey() final  bool isPerformingAction;

/// Create a copy of OrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderDetailStateCopyWith<_OrderDetailState> get copyWith => __$OrderDetailStateCopyWithImpl<_OrderDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderDetailState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.order, order) || other.order == order)&&(identical(other.canReviewResponse, canReviewResponse) || other.canReviewResponse == canReviewResponse)&&(identical(other.error, error) || other.error == error)&&(identical(other.isPerformingAction, isPerformingAction) || other.isPerformingAction == isPerformingAction));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,order,canReviewResponse,error,isPerformingAction);

@override
String toString() {
  return 'OrderDetailState(isLoading: $isLoading, order: $order, canReviewResponse: $canReviewResponse, error: $error, isPerformingAction: $isPerformingAction)';
}


}

/// @nodoc
abstract mixin class _$OrderDetailStateCopyWith<$Res> implements $OrderDetailStateCopyWith<$Res> {
  factory _$OrderDetailStateCopyWith(_OrderDetailState value, $Res Function(_OrderDetailState) _then) = __$OrderDetailStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, OrderEntity? order, CanReviewResponse? canReviewResponse, String? error, bool isPerformingAction
});


@override $OrderEntityCopyWith<$Res>? get order;@override $CanReviewResponseCopyWith<$Res>? get canReviewResponse;

}
/// @nodoc
class __$OrderDetailStateCopyWithImpl<$Res>
    implements _$OrderDetailStateCopyWith<$Res> {
  __$OrderDetailStateCopyWithImpl(this._self, this._then);

  final _OrderDetailState _self;
  final $Res Function(_OrderDetailState) _then;

/// Create a copy of OrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? order = freezed,Object? canReviewResponse = freezed,Object? error = freezed,Object? isPerformingAction = null,}) {
  return _then(_OrderDetailState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as OrderEntity?,canReviewResponse: freezed == canReviewResponse ? _self.canReviewResponse : canReviewResponse // ignore: cast_nullable_to_non_nullable
as CanReviewResponse?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,isPerformingAction: null == isPerformingAction ? _self.isPerformingAction : isPerformingAction // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of OrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderEntityCopyWith<$Res>? get order {
    if (_self.order == null) {
    return null;
  }

  return $OrderEntityCopyWith<$Res>(_self.order!, (value) {
    return _then(_self.copyWith(order: value));
  });
}/// Create a copy of OrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CanReviewResponseCopyWith<$Res>? get canReviewResponse {
    if (_self.canReviewResponse == null) {
    return null;
  }

  return $CanReviewResponseCopyWith<$Res>(_self.canReviewResponse!, (value) {
    return _then(_self.copyWith(canReviewResponse: value));
  });
}
}

/// @nodoc
mixin _$PurchasesListState {

 bool get isLoading; List<OrderEntity> get orders; int get total; String? get error; bool get hasMore;
/// Create a copy of PurchasesListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchasesListStateCopyWith<PurchasesListState> get copyWith => _$PurchasesListStateCopyWithImpl<PurchasesListState>(this as PurchasesListState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchasesListState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other.orders, orders)&&(identical(other.total, total) || other.total == total)&&(identical(other.error, error) || other.error == error)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(orders),total,error,hasMore);

@override
String toString() {
  return 'PurchasesListState(isLoading: $isLoading, orders: $orders, total: $total, error: $error, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class $PurchasesListStateCopyWith<$Res>  {
  factory $PurchasesListStateCopyWith(PurchasesListState value, $Res Function(PurchasesListState) _then) = _$PurchasesListStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, List<OrderEntity> orders, int total, String? error, bool hasMore
});




}
/// @nodoc
class _$PurchasesListStateCopyWithImpl<$Res>
    implements $PurchasesListStateCopyWith<$Res> {
  _$PurchasesListStateCopyWithImpl(this._self, this._then);

  final PurchasesListState _self;
  final $Res Function(PurchasesListState) _then;

/// Create a copy of PurchasesListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? orders = null,Object? total = null,Object? error = freezed,Object? hasMore = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as List<OrderEntity>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PurchasesListState].
extension PurchasesListStatePatterns on PurchasesListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PurchasesListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PurchasesListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PurchasesListState value)  $default,){
final _that = this;
switch (_that) {
case _PurchasesListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PurchasesListState value)?  $default,){
final _that = this;
switch (_that) {
case _PurchasesListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  List<OrderEntity> orders,  int total,  String? error,  bool hasMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PurchasesListState() when $default != null:
return $default(_that.isLoading,_that.orders,_that.total,_that.error,_that.hasMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  List<OrderEntity> orders,  int total,  String? error,  bool hasMore)  $default,) {final _that = this;
switch (_that) {
case _PurchasesListState():
return $default(_that.isLoading,_that.orders,_that.total,_that.error,_that.hasMore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  List<OrderEntity> orders,  int total,  String? error,  bool hasMore)?  $default,) {final _that = this;
switch (_that) {
case _PurchasesListState() when $default != null:
return $default(_that.isLoading,_that.orders,_that.total,_that.error,_that.hasMore);case _:
  return null;

}
}

}

/// @nodoc


class _PurchasesListState implements PurchasesListState {
  const _PurchasesListState({this.isLoading = false, final  List<OrderEntity> orders = const [], this.total = 0, this.error, this.hasMore = true}): _orders = orders;
  

@override@JsonKey() final  bool isLoading;
 final  List<OrderEntity> _orders;
@override@JsonKey() List<OrderEntity> get orders {
  if (_orders is EqualUnmodifiableListView) return _orders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orders);
}

@override@JsonKey() final  int total;
@override final  String? error;
@override@JsonKey() final  bool hasMore;

/// Create a copy of PurchasesListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchasesListStateCopyWith<_PurchasesListState> get copyWith => __$PurchasesListStateCopyWithImpl<_PurchasesListState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchasesListState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other._orders, _orders)&&(identical(other.total, total) || other.total == total)&&(identical(other.error, error) || other.error == error)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(_orders),total,error,hasMore);

@override
String toString() {
  return 'PurchasesListState(isLoading: $isLoading, orders: $orders, total: $total, error: $error, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class _$PurchasesListStateCopyWith<$Res> implements $PurchasesListStateCopyWith<$Res> {
  factory _$PurchasesListStateCopyWith(_PurchasesListState value, $Res Function(_PurchasesListState) _then) = __$PurchasesListStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, List<OrderEntity> orders, int total, String? error, bool hasMore
});




}
/// @nodoc
class __$PurchasesListStateCopyWithImpl<$Res>
    implements _$PurchasesListStateCopyWith<$Res> {
  __$PurchasesListStateCopyWithImpl(this._self, this._then);

  final _PurchasesListState _self;
  final $Res Function(_PurchasesListState) _then;

/// Create a copy of PurchasesListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? orders = null,Object? total = null,Object? error = freezed,Object? hasMore = null,}) {
  return _then(_PurchasesListState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,orders: null == orders ? _self._orders : orders // ignore: cast_nullable_to_non_nullable
as List<OrderEntity>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$SalesListState {

 bool get isLoading; List<OrderEntity> get orders; int get total; String? get error; bool get hasMore;
/// Create a copy of SalesListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SalesListStateCopyWith<SalesListState> get copyWith => _$SalesListStateCopyWithImpl<SalesListState>(this as SalesListState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SalesListState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other.orders, orders)&&(identical(other.total, total) || other.total == total)&&(identical(other.error, error) || other.error == error)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(orders),total,error,hasMore);

@override
String toString() {
  return 'SalesListState(isLoading: $isLoading, orders: $orders, total: $total, error: $error, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class $SalesListStateCopyWith<$Res>  {
  factory $SalesListStateCopyWith(SalesListState value, $Res Function(SalesListState) _then) = _$SalesListStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, List<OrderEntity> orders, int total, String? error, bool hasMore
});




}
/// @nodoc
class _$SalesListStateCopyWithImpl<$Res>
    implements $SalesListStateCopyWith<$Res> {
  _$SalesListStateCopyWithImpl(this._self, this._then);

  final SalesListState _self;
  final $Res Function(SalesListState) _then;

/// Create a copy of SalesListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? orders = null,Object? total = null,Object? error = freezed,Object? hasMore = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as List<OrderEntity>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SalesListState].
extension SalesListStatePatterns on SalesListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SalesListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SalesListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SalesListState value)  $default,){
final _that = this;
switch (_that) {
case _SalesListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SalesListState value)?  $default,){
final _that = this;
switch (_that) {
case _SalesListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  List<OrderEntity> orders,  int total,  String? error,  bool hasMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SalesListState() when $default != null:
return $default(_that.isLoading,_that.orders,_that.total,_that.error,_that.hasMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  List<OrderEntity> orders,  int total,  String? error,  bool hasMore)  $default,) {final _that = this;
switch (_that) {
case _SalesListState():
return $default(_that.isLoading,_that.orders,_that.total,_that.error,_that.hasMore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  List<OrderEntity> orders,  int total,  String? error,  bool hasMore)?  $default,) {final _that = this;
switch (_that) {
case _SalesListState() when $default != null:
return $default(_that.isLoading,_that.orders,_that.total,_that.error,_that.hasMore);case _:
  return null;

}
}

}

/// @nodoc


class _SalesListState implements SalesListState {
  const _SalesListState({this.isLoading = false, final  List<OrderEntity> orders = const [], this.total = 0, this.error, this.hasMore = true}): _orders = orders;
  

@override@JsonKey() final  bool isLoading;
 final  List<OrderEntity> _orders;
@override@JsonKey() List<OrderEntity> get orders {
  if (_orders is EqualUnmodifiableListView) return _orders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orders);
}

@override@JsonKey() final  int total;
@override final  String? error;
@override@JsonKey() final  bool hasMore;

/// Create a copy of SalesListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SalesListStateCopyWith<_SalesListState> get copyWith => __$SalesListStateCopyWithImpl<_SalesListState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SalesListState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other._orders, _orders)&&(identical(other.total, total) || other.total == total)&&(identical(other.error, error) || other.error == error)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(_orders),total,error,hasMore);

@override
String toString() {
  return 'SalesListState(isLoading: $isLoading, orders: $orders, total: $total, error: $error, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class _$SalesListStateCopyWith<$Res> implements $SalesListStateCopyWith<$Res> {
  factory _$SalesListStateCopyWith(_SalesListState value, $Res Function(_SalesListState) _then) = __$SalesListStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, List<OrderEntity> orders, int total, String? error, bool hasMore
});




}
/// @nodoc
class __$SalesListStateCopyWithImpl<$Res>
    implements _$SalesListStateCopyWith<$Res> {
  __$SalesListStateCopyWithImpl(this._self, this._then);

  final _SalesListState _self;
  final $Res Function(_SalesListState) _then;

/// Create a copy of SalesListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? orders = null,Object? total = null,Object? error = freezed,Object? hasMore = null,}) {
  return _then(_SalesListState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,orders: null == orders ? _self._orders : orders // ignore: cast_nullable_to_non_nullable
as List<OrderEntity>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
