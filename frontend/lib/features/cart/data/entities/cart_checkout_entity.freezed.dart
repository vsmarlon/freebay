// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cart_checkout_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CartCheckoutItemEntity {

 String get orderId; String get productId; String get productTitle; int get quantity; int get amount; String get pixQrCode; String get pixImage; DateTime get expiresAt;
/// Create a copy of CartCheckoutItemEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartCheckoutItemEntityCopyWith<CartCheckoutItemEntity> get copyWith => _$CartCheckoutItemEntityCopyWithImpl<CartCheckoutItemEntity>(this as CartCheckoutItemEntity, _$identity);

  /// Serializes this CartCheckoutItemEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartCheckoutItemEntity&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productTitle, productTitle) || other.productTitle == productTitle)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.pixQrCode, pixQrCode) || other.pixQrCode == pixQrCode)&&(identical(other.pixImage, pixImage) || other.pixImage == pixImage)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,productId,productTitle,quantity,amount,pixQrCode,pixImage,expiresAt);

@override
String toString() {
  return 'CartCheckoutItemEntity(orderId: $orderId, productId: $productId, productTitle: $productTitle, quantity: $quantity, amount: $amount, pixQrCode: $pixQrCode, pixImage: $pixImage, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $CartCheckoutItemEntityCopyWith<$Res>  {
  factory $CartCheckoutItemEntityCopyWith(CartCheckoutItemEntity value, $Res Function(CartCheckoutItemEntity) _then) = _$CartCheckoutItemEntityCopyWithImpl;
@useResult
$Res call({
 String orderId, String productId, String productTitle, int quantity, int amount, String pixQrCode, String pixImage, DateTime expiresAt
});




}
/// @nodoc
class _$CartCheckoutItemEntityCopyWithImpl<$Res>
    implements $CartCheckoutItemEntityCopyWith<$Res> {
  _$CartCheckoutItemEntityCopyWithImpl(this._self, this._then);

  final CartCheckoutItemEntity _self;
  final $Res Function(CartCheckoutItemEntity) _then;

/// Create a copy of CartCheckoutItemEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? productId = null,Object? productTitle = null,Object? quantity = null,Object? amount = null,Object? pixQrCode = null,Object? pixImage = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productTitle: null == productTitle ? _self.productTitle : productTitle // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,pixQrCode: null == pixQrCode ? _self.pixQrCode : pixQrCode // ignore: cast_nullable_to_non_nullable
as String,pixImage: null == pixImage ? _self.pixImage : pixImage // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CartCheckoutItemEntity].
extension CartCheckoutItemEntityPatterns on CartCheckoutItemEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CartCheckoutItemEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CartCheckoutItemEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CartCheckoutItemEntity value)  $default,){
final _that = this;
switch (_that) {
case _CartCheckoutItemEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CartCheckoutItemEntity value)?  $default,){
final _that = this;
switch (_that) {
case _CartCheckoutItemEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String orderId,  String productId,  String productTitle,  int quantity,  int amount,  String pixQrCode,  String pixImage,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CartCheckoutItemEntity() when $default != null:
return $default(_that.orderId,_that.productId,_that.productTitle,_that.quantity,_that.amount,_that.pixQrCode,_that.pixImage,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String orderId,  String productId,  String productTitle,  int quantity,  int amount,  String pixQrCode,  String pixImage,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _CartCheckoutItemEntity():
return $default(_that.orderId,_that.productId,_that.productTitle,_that.quantity,_that.amount,_that.pixQrCode,_that.pixImage,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String orderId,  String productId,  String productTitle,  int quantity,  int amount,  String pixQrCode,  String pixImage,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _CartCheckoutItemEntity() when $default != null:
return $default(_that.orderId,_that.productId,_that.productTitle,_that.quantity,_that.amount,_that.pixQrCode,_that.pixImage,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CartCheckoutItemEntity implements CartCheckoutItemEntity {
  const _CartCheckoutItemEntity({required this.orderId, required this.productId, required this.productTitle, this.quantity = 1, this.amount = 0, this.pixQrCode = '', this.pixImage = '', required this.expiresAt});
  factory _CartCheckoutItemEntity.fromJson(Map<String, dynamic> json) => _$CartCheckoutItemEntityFromJson(json);

@override final  String orderId;
@override final  String productId;
@override final  String productTitle;
@override@JsonKey() final  int quantity;
@override@JsonKey() final  int amount;
@override@JsonKey() final  String pixQrCode;
@override@JsonKey() final  String pixImage;
@override final  DateTime expiresAt;

/// Create a copy of CartCheckoutItemEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CartCheckoutItemEntityCopyWith<_CartCheckoutItemEntity> get copyWith => __$CartCheckoutItemEntityCopyWithImpl<_CartCheckoutItemEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CartCheckoutItemEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CartCheckoutItemEntity&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productTitle, productTitle) || other.productTitle == productTitle)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.pixQrCode, pixQrCode) || other.pixQrCode == pixQrCode)&&(identical(other.pixImage, pixImage) || other.pixImage == pixImage)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,productId,productTitle,quantity,amount,pixQrCode,pixImage,expiresAt);

@override
String toString() {
  return 'CartCheckoutItemEntity(orderId: $orderId, productId: $productId, productTitle: $productTitle, quantity: $quantity, amount: $amount, pixQrCode: $pixQrCode, pixImage: $pixImage, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$CartCheckoutItemEntityCopyWith<$Res> implements $CartCheckoutItemEntityCopyWith<$Res> {
  factory _$CartCheckoutItemEntityCopyWith(_CartCheckoutItemEntity value, $Res Function(_CartCheckoutItemEntity) _then) = __$CartCheckoutItemEntityCopyWithImpl;
@override @useResult
$Res call({
 String orderId, String productId, String productTitle, int quantity, int amount, String pixQrCode, String pixImage, DateTime expiresAt
});




}
/// @nodoc
class __$CartCheckoutItemEntityCopyWithImpl<$Res>
    implements _$CartCheckoutItemEntityCopyWith<$Res> {
  __$CartCheckoutItemEntityCopyWithImpl(this._self, this._then);

  final _CartCheckoutItemEntity _self;
  final $Res Function(_CartCheckoutItemEntity) _then;

/// Create a copy of CartCheckoutItemEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? productId = null,Object? productTitle = null,Object? quantity = null,Object? amount = null,Object? pixQrCode = null,Object? pixImage = null,Object? expiresAt = null,}) {
  return _then(_CartCheckoutItemEntity(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productTitle: null == productTitle ? _self.productTitle : productTitle // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,pixQrCode: null == pixQrCode ? _self.pixQrCode : pixQrCode // ignore: cast_nullable_to_non_nullable
as String,pixImage: null == pixImage ? _self.pixImage : pixImage // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$CartCheckoutEntity {

 List<CartCheckoutItemEntity> get items; int get totalOrders; int get totalAmount;
/// Create a copy of CartCheckoutEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartCheckoutEntityCopyWith<CartCheckoutEntity> get copyWith => _$CartCheckoutEntityCopyWithImpl<CartCheckoutEntity>(this as CartCheckoutEntity, _$identity);

  /// Serializes this CartCheckoutEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartCheckoutEntity&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalOrders, totalOrders) || other.totalOrders == totalOrders)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),totalOrders,totalAmount);

@override
String toString() {
  return 'CartCheckoutEntity(items: $items, totalOrders: $totalOrders, totalAmount: $totalAmount)';
}


}

/// @nodoc
abstract mixin class $CartCheckoutEntityCopyWith<$Res>  {
  factory $CartCheckoutEntityCopyWith(CartCheckoutEntity value, $Res Function(CartCheckoutEntity) _then) = _$CartCheckoutEntityCopyWithImpl;
@useResult
$Res call({
 List<CartCheckoutItemEntity> items, int totalOrders, int totalAmount
});




}
/// @nodoc
class _$CartCheckoutEntityCopyWithImpl<$Res>
    implements $CartCheckoutEntityCopyWith<$Res> {
  _$CartCheckoutEntityCopyWithImpl(this._self, this._then);

  final CartCheckoutEntity _self;
  final $Res Function(CartCheckoutEntity) _then;

/// Create a copy of CartCheckoutEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? totalOrders = null,Object? totalAmount = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CartCheckoutItemEntity>,totalOrders: null == totalOrders ? _self.totalOrders : totalOrders // ignore: cast_nullable_to_non_nullable
as int,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CartCheckoutEntity].
extension CartCheckoutEntityPatterns on CartCheckoutEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CartCheckoutEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CartCheckoutEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CartCheckoutEntity value)  $default,){
final _that = this;
switch (_that) {
case _CartCheckoutEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CartCheckoutEntity value)?  $default,){
final _that = this;
switch (_that) {
case _CartCheckoutEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CartCheckoutItemEntity> items,  int totalOrders,  int totalAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CartCheckoutEntity() when $default != null:
return $default(_that.items,_that.totalOrders,_that.totalAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CartCheckoutItemEntity> items,  int totalOrders,  int totalAmount)  $default,) {final _that = this;
switch (_that) {
case _CartCheckoutEntity():
return $default(_that.items,_that.totalOrders,_that.totalAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CartCheckoutItemEntity> items,  int totalOrders,  int totalAmount)?  $default,) {final _that = this;
switch (_that) {
case _CartCheckoutEntity() when $default != null:
return $default(_that.items,_that.totalOrders,_that.totalAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CartCheckoutEntity implements CartCheckoutEntity {
  const _CartCheckoutEntity({required final  List<CartCheckoutItemEntity> items, this.totalOrders = 0, this.totalAmount = 0}): _items = items;
  factory _CartCheckoutEntity.fromJson(Map<String, dynamic> json) => _$CartCheckoutEntityFromJson(json);

 final  List<CartCheckoutItemEntity> _items;
@override List<CartCheckoutItemEntity> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int totalOrders;
@override@JsonKey() final  int totalAmount;

/// Create a copy of CartCheckoutEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CartCheckoutEntityCopyWith<_CartCheckoutEntity> get copyWith => __$CartCheckoutEntityCopyWithImpl<_CartCheckoutEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CartCheckoutEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CartCheckoutEntity&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalOrders, totalOrders) || other.totalOrders == totalOrders)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),totalOrders,totalAmount);

@override
String toString() {
  return 'CartCheckoutEntity(items: $items, totalOrders: $totalOrders, totalAmount: $totalAmount)';
}


}

/// @nodoc
abstract mixin class _$CartCheckoutEntityCopyWith<$Res> implements $CartCheckoutEntityCopyWith<$Res> {
  factory _$CartCheckoutEntityCopyWith(_CartCheckoutEntity value, $Res Function(_CartCheckoutEntity) _then) = __$CartCheckoutEntityCopyWithImpl;
@override @useResult
$Res call({
 List<CartCheckoutItemEntity> items, int totalOrders, int totalAmount
});




}
/// @nodoc
class __$CartCheckoutEntityCopyWithImpl<$Res>
    implements _$CartCheckoutEntityCopyWith<$Res> {
  __$CartCheckoutEntityCopyWithImpl(this._self, this._then);

  final _CartCheckoutEntity _self;
  final $Res Function(_CartCheckoutEntity) _then;

/// Create a copy of CartCheckoutEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? totalOrders = null,Object? totalAmount = null,}) {
  return _then(_CartCheckoutEntity(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CartCheckoutItemEntity>,totalOrders: null == totalOrders ? _self.totalOrders : totalOrders // ignore: cast_nullable_to_non_nullable
as int,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
