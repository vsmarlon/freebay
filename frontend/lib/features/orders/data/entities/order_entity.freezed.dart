// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrderUserInfo {

 String get id; String? get displayName; String? get avatarUrl; bool get isVerified;
/// Create a copy of OrderUserInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderUserInfoCopyWith<OrderUserInfo> get copyWith => _$OrderUserInfoCopyWithImpl<OrderUserInfo>(this as OrderUserInfo, _$identity);

  /// Serializes this OrderUserInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderUserInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,avatarUrl,isVerified);

@override
String toString() {
  return 'OrderUserInfo(id: $id, displayName: $displayName, avatarUrl: $avatarUrl, isVerified: $isVerified)';
}


}

/// @nodoc
abstract mixin class $OrderUserInfoCopyWith<$Res>  {
  factory $OrderUserInfoCopyWith(OrderUserInfo value, $Res Function(OrderUserInfo) _then) = _$OrderUserInfoCopyWithImpl;
@useResult
$Res call({
 String id, String? displayName, String? avatarUrl, bool isVerified
});




}
/// @nodoc
class _$OrderUserInfoCopyWithImpl<$Res>
    implements $OrderUserInfoCopyWith<$Res> {
  _$OrderUserInfoCopyWithImpl(this._self, this._then);

  final OrderUserInfo _self;
  final $Res Function(OrderUserInfo) _then;

/// Create a copy of OrderUserInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = freezed,Object? avatarUrl = freezed,Object? isVerified = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderUserInfo].
extension OrderUserInfoPatterns on OrderUserInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderUserInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderUserInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderUserInfo value)  $default,){
final _that = this;
switch (_that) {
case _OrderUserInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderUserInfo value)?  $default,){
final _that = this;
switch (_that) {
case _OrderUserInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? displayName,  String? avatarUrl,  bool isVerified)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderUserInfo() when $default != null:
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.isVerified);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? displayName,  String? avatarUrl,  bool isVerified)  $default,) {final _that = this;
switch (_that) {
case _OrderUserInfo():
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.isVerified);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? displayName,  String? avatarUrl,  bool isVerified)?  $default,) {final _that = this;
switch (_that) {
case _OrderUserInfo() when $default != null:
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.isVerified);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderUserInfo extends OrderUserInfo {
  const _OrderUserInfo({required this.id, this.displayName, this.avatarUrl, this.isVerified = false}): super._();
  factory _OrderUserInfo.fromJson(Map<String, dynamic> json) => _$OrderUserInfoFromJson(json);

@override final  String id;
@override final  String? displayName;
@override final  String? avatarUrl;
@override@JsonKey() final  bool isVerified;

/// Create a copy of OrderUserInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderUserInfoCopyWith<_OrderUserInfo> get copyWith => __$OrderUserInfoCopyWithImpl<_OrderUserInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderUserInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderUserInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,avatarUrl,isVerified);

@override
String toString() {
  return 'OrderUserInfo(id: $id, displayName: $displayName, avatarUrl: $avatarUrl, isVerified: $isVerified)';
}


}

/// @nodoc
abstract mixin class _$OrderUserInfoCopyWith<$Res> implements $OrderUserInfoCopyWith<$Res> {
  factory _$OrderUserInfoCopyWith(_OrderUserInfo value, $Res Function(_OrderUserInfo) _then) = __$OrderUserInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, String? displayName, String? avatarUrl, bool isVerified
});




}
/// @nodoc
class __$OrderUserInfoCopyWithImpl<$Res>
    implements _$OrderUserInfoCopyWith<$Res> {
  __$OrderUserInfoCopyWithImpl(this._self, this._then);

  final _OrderUserInfo _self;
  final $Res Function(_OrderUserInfo) _then;

/// Create a copy of OrderUserInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = freezed,Object? avatarUrl = freezed,Object? isVerified = null,}) {
  return _then(_OrderUserInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$OrderEntity {

 String get id; String get buyerId; String get sellerId; String get productId; int get amount; int get platformFee; int get sellerAmount;@JsonKey(fromJson: _orderStatusFromJson) OrderStatus get status;@JsonKey(fromJson: _escrowStatusFromJson) EscrowStatus get escrowStatus; DateTime get createdAt; DateTime? get deliveryConfirmedAt; ProductEntity? get product; OrderUserInfo? get buyer; OrderUserInfo? get seller;
/// Create a copy of OrderEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderEntityCopyWith<OrderEntity> get copyWith => _$OrderEntityCopyWithImpl<OrderEntity>(this as OrderEntity, _$identity);

  /// Serializes this OrderEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.buyerId, buyerId) || other.buyerId == buyerId)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.platformFee, platformFee) || other.platformFee == platformFee)&&(identical(other.sellerAmount, sellerAmount) || other.sellerAmount == sellerAmount)&&(identical(other.status, status) || other.status == status)&&(identical(other.escrowStatus, escrowStatus) || other.escrowStatus == escrowStatus)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.deliveryConfirmedAt, deliveryConfirmedAt) || other.deliveryConfirmedAt == deliveryConfirmedAt)&&(identical(other.product, product) || other.product == product)&&(identical(other.buyer, buyer) || other.buyer == buyer)&&(identical(other.seller, seller) || other.seller == seller));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,buyerId,sellerId,productId,amount,platformFee,sellerAmount,status,escrowStatus,createdAt,deliveryConfirmedAt,product,buyer,seller);

@override
String toString() {
  return 'OrderEntity(id: $id, buyerId: $buyerId, sellerId: $sellerId, productId: $productId, amount: $amount, platformFee: $platformFee, sellerAmount: $sellerAmount, status: $status, escrowStatus: $escrowStatus, createdAt: $createdAt, deliveryConfirmedAt: $deliveryConfirmedAt, product: $product, buyer: $buyer, seller: $seller)';
}


}

/// @nodoc
abstract mixin class $OrderEntityCopyWith<$Res>  {
  factory $OrderEntityCopyWith(OrderEntity value, $Res Function(OrderEntity) _then) = _$OrderEntityCopyWithImpl;
@useResult
$Res call({
 String id, String buyerId, String sellerId, String productId, int amount, int platformFee, int sellerAmount,@JsonKey(fromJson: _orderStatusFromJson) OrderStatus status,@JsonKey(fromJson: _escrowStatusFromJson) EscrowStatus escrowStatus, DateTime createdAt, DateTime? deliveryConfirmedAt, ProductEntity? product, OrderUserInfo? buyer, OrderUserInfo? seller
});


$ProductEntityCopyWith<$Res>? get product;$OrderUserInfoCopyWith<$Res>? get buyer;$OrderUserInfoCopyWith<$Res>? get seller;

}
/// @nodoc
class _$OrderEntityCopyWithImpl<$Res>
    implements $OrderEntityCopyWith<$Res> {
  _$OrderEntityCopyWithImpl(this._self, this._then);

  final OrderEntity _self;
  final $Res Function(OrderEntity) _then;

/// Create a copy of OrderEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? buyerId = null,Object? sellerId = null,Object? productId = null,Object? amount = null,Object? platformFee = null,Object? sellerAmount = null,Object? status = null,Object? escrowStatus = null,Object? createdAt = null,Object? deliveryConfirmedAt = freezed,Object? product = freezed,Object? buyer = freezed,Object? seller = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buyerId: null == buyerId ? _self.buyerId : buyerId // ignore: cast_nullable_to_non_nullable
as String,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,platformFee: null == platformFee ? _self.platformFee : platformFee // ignore: cast_nullable_to_non_nullable
as int,sellerAmount: null == sellerAmount ? _self.sellerAmount : sellerAmount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,escrowStatus: null == escrowStatus ? _self.escrowStatus : escrowStatus // ignore: cast_nullable_to_non_nullable
as EscrowStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,deliveryConfirmedAt: freezed == deliveryConfirmedAt ? _self.deliveryConfirmedAt : deliveryConfirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,product: freezed == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as ProductEntity?,buyer: freezed == buyer ? _self.buyer : buyer // ignore: cast_nullable_to_non_nullable
as OrderUserInfo?,seller: freezed == seller ? _self.seller : seller // ignore: cast_nullable_to_non_nullable
as OrderUserInfo?,
  ));
}
/// Create a copy of OrderEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductEntityCopyWith<$Res>? get product {
    if (_self.product == null) {
    return null;
  }

  return $ProductEntityCopyWith<$Res>(_self.product!, (value) {
    return _then(_self.copyWith(product: value));
  });
}/// Create a copy of OrderEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderUserInfoCopyWith<$Res>? get buyer {
    if (_self.buyer == null) {
    return null;
  }

  return $OrderUserInfoCopyWith<$Res>(_self.buyer!, (value) {
    return _then(_self.copyWith(buyer: value));
  });
}/// Create a copy of OrderEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderUserInfoCopyWith<$Res>? get seller {
    if (_self.seller == null) {
    return null;
  }

  return $OrderUserInfoCopyWith<$Res>(_self.seller!, (value) {
    return _then(_self.copyWith(seller: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrderEntity].
extension OrderEntityPatterns on OrderEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderEntity value)  $default,){
final _that = this;
switch (_that) {
case _OrderEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderEntity value)?  $default,){
final _that = this;
switch (_that) {
case _OrderEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String buyerId,  String sellerId,  String productId,  int amount,  int platformFee,  int sellerAmount, @JsonKey(fromJson: _orderStatusFromJson)  OrderStatus status, @JsonKey(fromJson: _escrowStatusFromJson)  EscrowStatus escrowStatus,  DateTime createdAt,  DateTime? deliveryConfirmedAt,  ProductEntity? product,  OrderUserInfo? buyer,  OrderUserInfo? seller)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderEntity() when $default != null:
return $default(_that.id,_that.buyerId,_that.sellerId,_that.productId,_that.amount,_that.platformFee,_that.sellerAmount,_that.status,_that.escrowStatus,_that.createdAt,_that.deliveryConfirmedAt,_that.product,_that.buyer,_that.seller);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String buyerId,  String sellerId,  String productId,  int amount,  int platformFee,  int sellerAmount, @JsonKey(fromJson: _orderStatusFromJson)  OrderStatus status, @JsonKey(fromJson: _escrowStatusFromJson)  EscrowStatus escrowStatus,  DateTime createdAt,  DateTime? deliveryConfirmedAt,  ProductEntity? product,  OrderUserInfo? buyer,  OrderUserInfo? seller)  $default,) {final _that = this;
switch (_that) {
case _OrderEntity():
return $default(_that.id,_that.buyerId,_that.sellerId,_that.productId,_that.amount,_that.platformFee,_that.sellerAmount,_that.status,_that.escrowStatus,_that.createdAt,_that.deliveryConfirmedAt,_that.product,_that.buyer,_that.seller);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String buyerId,  String sellerId,  String productId,  int amount,  int platformFee,  int sellerAmount, @JsonKey(fromJson: _orderStatusFromJson)  OrderStatus status, @JsonKey(fromJson: _escrowStatusFromJson)  EscrowStatus escrowStatus,  DateTime createdAt,  DateTime? deliveryConfirmedAt,  ProductEntity? product,  OrderUserInfo? buyer,  OrderUserInfo? seller)?  $default,) {final _that = this;
switch (_that) {
case _OrderEntity() when $default != null:
return $default(_that.id,_that.buyerId,_that.sellerId,_that.productId,_that.amount,_that.platformFee,_that.sellerAmount,_that.status,_that.escrowStatus,_that.createdAt,_that.deliveryConfirmedAt,_that.product,_that.buyer,_that.seller);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderEntity extends OrderEntity {
  const _OrderEntity({required this.id, required this.buyerId, required this.sellerId, required this.productId, this.amount = 0, this.platformFee = 0, this.sellerAmount = 0, @JsonKey(fromJson: _orderStatusFromJson) required this.status, @JsonKey(fromJson: _escrowStatusFromJson) required this.escrowStatus, required this.createdAt, this.deliveryConfirmedAt, this.product, this.buyer, this.seller}): super._();
  factory _OrderEntity.fromJson(Map<String, dynamic> json) => _$OrderEntityFromJson(json);

@override final  String id;
@override final  String buyerId;
@override final  String sellerId;
@override final  String productId;
@override@JsonKey() final  int amount;
@override@JsonKey() final  int platformFee;
@override@JsonKey() final  int sellerAmount;
@override@JsonKey(fromJson: _orderStatusFromJson) final  OrderStatus status;
@override@JsonKey(fromJson: _escrowStatusFromJson) final  EscrowStatus escrowStatus;
@override final  DateTime createdAt;
@override final  DateTime? deliveryConfirmedAt;
@override final  ProductEntity? product;
@override final  OrderUserInfo? buyer;
@override final  OrderUserInfo? seller;

/// Create a copy of OrderEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderEntityCopyWith<_OrderEntity> get copyWith => __$OrderEntityCopyWithImpl<_OrderEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.buyerId, buyerId) || other.buyerId == buyerId)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.platformFee, platformFee) || other.platformFee == platformFee)&&(identical(other.sellerAmount, sellerAmount) || other.sellerAmount == sellerAmount)&&(identical(other.status, status) || other.status == status)&&(identical(other.escrowStatus, escrowStatus) || other.escrowStatus == escrowStatus)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.deliveryConfirmedAt, deliveryConfirmedAt) || other.deliveryConfirmedAt == deliveryConfirmedAt)&&(identical(other.product, product) || other.product == product)&&(identical(other.buyer, buyer) || other.buyer == buyer)&&(identical(other.seller, seller) || other.seller == seller));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,buyerId,sellerId,productId,amount,platformFee,sellerAmount,status,escrowStatus,createdAt,deliveryConfirmedAt,product,buyer,seller);

@override
String toString() {
  return 'OrderEntity(id: $id, buyerId: $buyerId, sellerId: $sellerId, productId: $productId, amount: $amount, platformFee: $platformFee, sellerAmount: $sellerAmount, status: $status, escrowStatus: $escrowStatus, createdAt: $createdAt, deliveryConfirmedAt: $deliveryConfirmedAt, product: $product, buyer: $buyer, seller: $seller)';
}


}

/// @nodoc
abstract mixin class _$OrderEntityCopyWith<$Res> implements $OrderEntityCopyWith<$Res> {
  factory _$OrderEntityCopyWith(_OrderEntity value, $Res Function(_OrderEntity) _then) = __$OrderEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String buyerId, String sellerId, String productId, int amount, int platformFee, int sellerAmount,@JsonKey(fromJson: _orderStatusFromJson) OrderStatus status,@JsonKey(fromJson: _escrowStatusFromJson) EscrowStatus escrowStatus, DateTime createdAt, DateTime? deliveryConfirmedAt, ProductEntity? product, OrderUserInfo? buyer, OrderUserInfo? seller
});


@override $ProductEntityCopyWith<$Res>? get product;@override $OrderUserInfoCopyWith<$Res>? get buyer;@override $OrderUserInfoCopyWith<$Res>? get seller;

}
/// @nodoc
class __$OrderEntityCopyWithImpl<$Res>
    implements _$OrderEntityCopyWith<$Res> {
  __$OrderEntityCopyWithImpl(this._self, this._then);

  final _OrderEntity _self;
  final $Res Function(_OrderEntity) _then;

/// Create a copy of OrderEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? buyerId = null,Object? sellerId = null,Object? productId = null,Object? amount = null,Object? platformFee = null,Object? sellerAmount = null,Object? status = null,Object? escrowStatus = null,Object? createdAt = null,Object? deliveryConfirmedAt = freezed,Object? product = freezed,Object? buyer = freezed,Object? seller = freezed,}) {
  return _then(_OrderEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,buyerId: null == buyerId ? _self.buyerId : buyerId // ignore: cast_nullable_to_non_nullable
as String,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,platformFee: null == platformFee ? _self.platformFee : platformFee // ignore: cast_nullable_to_non_nullable
as int,sellerAmount: null == sellerAmount ? _self.sellerAmount : sellerAmount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,escrowStatus: null == escrowStatus ? _self.escrowStatus : escrowStatus // ignore: cast_nullable_to_non_nullable
as EscrowStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,deliveryConfirmedAt: freezed == deliveryConfirmedAt ? _self.deliveryConfirmedAt : deliveryConfirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,product: freezed == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as ProductEntity?,buyer: freezed == buyer ? _self.buyer : buyer // ignore: cast_nullable_to_non_nullable
as OrderUserInfo?,seller: freezed == seller ? _self.seller : seller // ignore: cast_nullable_to_non_nullable
as OrderUserInfo?,
  ));
}

/// Create a copy of OrderEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductEntityCopyWith<$Res>? get product {
    if (_self.product == null) {
    return null;
  }

  return $ProductEntityCopyWith<$Res>(_self.product!, (value) {
    return _then(_self.copyWith(product: value));
  });
}/// Create a copy of OrderEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderUserInfoCopyWith<$Res>? get buyer {
    if (_self.buyer == null) {
    return null;
  }

  return $OrderUserInfoCopyWith<$Res>(_self.buyer!, (value) {
    return _then(_self.copyWith(buyer: value));
  });
}/// Create a copy of OrderEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderUserInfoCopyWith<$Res>? get seller {
    if (_self.seller == null) {
    return null;
  }

  return $OrderUserInfoCopyWith<$Res>(_self.seller!, (value) {
    return _then(_self.copyWith(seller: value));
  });
}
}


/// @nodoc
mixin _$CanReviewResponse {

 bool get canReview; String? get reviewType; String? get reason;
/// Create a copy of CanReviewResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CanReviewResponseCopyWith<CanReviewResponse> get copyWith => _$CanReviewResponseCopyWithImpl<CanReviewResponse>(this as CanReviewResponse, _$identity);

  /// Serializes this CanReviewResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CanReviewResponse&&(identical(other.canReview, canReview) || other.canReview == canReview)&&(identical(other.reviewType, reviewType) || other.reviewType == reviewType)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,canReview,reviewType,reason);

@override
String toString() {
  return 'CanReviewResponse(canReview: $canReview, reviewType: $reviewType, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $CanReviewResponseCopyWith<$Res>  {
  factory $CanReviewResponseCopyWith(CanReviewResponse value, $Res Function(CanReviewResponse) _then) = _$CanReviewResponseCopyWithImpl;
@useResult
$Res call({
 bool canReview, String? reviewType, String? reason
});




}
/// @nodoc
class _$CanReviewResponseCopyWithImpl<$Res>
    implements $CanReviewResponseCopyWith<$Res> {
  _$CanReviewResponseCopyWithImpl(this._self, this._then);

  final CanReviewResponse _self;
  final $Res Function(CanReviewResponse) _then;

/// Create a copy of CanReviewResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? canReview = null,Object? reviewType = freezed,Object? reason = freezed,}) {
  return _then(_self.copyWith(
canReview: null == canReview ? _self.canReview : canReview // ignore: cast_nullable_to_non_nullable
as bool,reviewType: freezed == reviewType ? _self.reviewType : reviewType // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CanReviewResponse].
extension CanReviewResponsePatterns on CanReviewResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CanReviewResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CanReviewResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CanReviewResponse value)  $default,){
final _that = this;
switch (_that) {
case _CanReviewResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CanReviewResponse value)?  $default,){
final _that = this;
switch (_that) {
case _CanReviewResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool canReview,  String? reviewType,  String? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CanReviewResponse() when $default != null:
return $default(_that.canReview,_that.reviewType,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool canReview,  String? reviewType,  String? reason)  $default,) {final _that = this;
switch (_that) {
case _CanReviewResponse():
return $default(_that.canReview,_that.reviewType,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool canReview,  String? reviewType,  String? reason)?  $default,) {final _that = this;
switch (_that) {
case _CanReviewResponse() when $default != null:
return $default(_that.canReview,_that.reviewType,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CanReviewResponse implements CanReviewResponse {
  const _CanReviewResponse({this.canReview = false, this.reviewType, this.reason});
  factory _CanReviewResponse.fromJson(Map<String, dynamic> json) => _$CanReviewResponseFromJson(json);

@override@JsonKey() final  bool canReview;
@override final  String? reviewType;
@override final  String? reason;

/// Create a copy of CanReviewResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CanReviewResponseCopyWith<_CanReviewResponse> get copyWith => __$CanReviewResponseCopyWithImpl<_CanReviewResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CanReviewResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CanReviewResponse&&(identical(other.canReview, canReview) || other.canReview == canReview)&&(identical(other.reviewType, reviewType) || other.reviewType == reviewType)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,canReview,reviewType,reason);

@override
String toString() {
  return 'CanReviewResponse(canReview: $canReview, reviewType: $reviewType, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$CanReviewResponseCopyWith<$Res> implements $CanReviewResponseCopyWith<$Res> {
  factory _$CanReviewResponseCopyWith(_CanReviewResponse value, $Res Function(_CanReviewResponse) _then) = __$CanReviewResponseCopyWithImpl;
@override @useResult
$Res call({
 bool canReview, String? reviewType, String? reason
});




}
/// @nodoc
class __$CanReviewResponseCopyWithImpl<$Res>
    implements _$CanReviewResponseCopyWith<$Res> {
  __$CanReviewResponseCopyWithImpl(this._self, this._then);

  final _CanReviewResponse _self;
  final $Res Function(_CanReviewResponse) _then;

/// Create a copy of CanReviewResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? canReview = null,Object? reviewType = freezed,Object? reason = freezed,}) {
  return _then(_CanReviewResponse(
canReview: null == canReview ? _self.canReview : canReview // ignore: cast_nullable_to_non_nullable
as bool,reviewType: freezed == reviewType ? _self.reviewType : reviewType // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
