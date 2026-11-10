// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProductEntity {

 String get id; String get title; String get description; int get price;@ProductConditionConverter() ProductCondition get condition;@ProductStatusConverter() ProductStatus get status; String get sellerId; String? get postId; UserEntity? get seller; List<ProductImageEntity>? get images; int get quantity; int get soldCount;
/// Create a copy of ProductEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductEntityCopyWith<ProductEntity> get copyWith => _$ProductEntityCopyWithImpl<ProductEntity>(this as ProductEntity, _$identity);

  /// Serializes this ProductEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.status, status) || other.status == status)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.seller, seller) || other.seller == seller)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.soldCount, soldCount) || other.soldCount == soldCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,price,condition,status,sellerId,postId,seller,const DeepCollectionEquality().hash(images),quantity,soldCount);

@override
String toString() {
  return 'ProductEntity(id: $id, title: $title, description: $description, price: $price, condition: $condition, status: $status, sellerId: $sellerId, postId: $postId, seller: $seller, images: $images, quantity: $quantity, soldCount: $soldCount)';
}


}

/// @nodoc
abstract mixin class $ProductEntityCopyWith<$Res>  {
  factory $ProductEntityCopyWith(ProductEntity value, $Res Function(ProductEntity) _then) = _$ProductEntityCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, int price,@ProductConditionConverter() ProductCondition condition,@ProductStatusConverter() ProductStatus status, String sellerId, String? postId, UserEntity? seller, List<ProductImageEntity>? images, int quantity, int soldCount
});


$UserEntityCopyWith<$Res>? get seller;

}
/// @nodoc
class _$ProductEntityCopyWithImpl<$Res>
    implements $ProductEntityCopyWith<$Res> {
  _$ProductEntityCopyWithImpl(this._self, this._then);

  final ProductEntity _self;
  final $Res Function(ProductEntity) _then;

/// Create a copy of ProductEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? price = null,Object? condition = null,Object? status = null,Object? sellerId = null,Object? postId = freezed,Object? seller = freezed,Object? images = freezed,Object? quantity = null,Object? soldCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as ProductCondition,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProductStatus,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,postId: freezed == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String?,seller: freezed == seller ? _self.seller : seller // ignore: cast_nullable_to_non_nullable
as UserEntity?,images: freezed == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<ProductImageEntity>?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,soldCount: null == soldCount ? _self.soldCount : soldCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ProductEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserEntityCopyWith<$Res>? get seller {
    if (_self.seller == null) {
    return null;
  }

  return $UserEntityCopyWith<$Res>(_self.seller!, (value) {
    return _then(_self.copyWith(seller: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProductEntity].
extension ProductEntityPatterns on ProductEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductEntity value)  $default,){
final _that = this;
switch (_that) {
case _ProductEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ProductEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  int price, @ProductConditionConverter()  ProductCondition condition, @ProductStatusConverter()  ProductStatus status,  String sellerId,  String? postId,  UserEntity? seller,  List<ProductImageEntity>? images,  int quantity,  int soldCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductEntity() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.price,_that.condition,_that.status,_that.sellerId,_that.postId,_that.seller,_that.images,_that.quantity,_that.soldCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  int price, @ProductConditionConverter()  ProductCondition condition, @ProductStatusConverter()  ProductStatus status,  String sellerId,  String? postId,  UserEntity? seller,  List<ProductImageEntity>? images,  int quantity,  int soldCount)  $default,) {final _that = this;
switch (_that) {
case _ProductEntity():
return $default(_that.id,_that.title,_that.description,_that.price,_that.condition,_that.status,_that.sellerId,_that.postId,_that.seller,_that.images,_that.quantity,_that.soldCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  int price, @ProductConditionConverter()  ProductCondition condition, @ProductStatusConverter()  ProductStatus status,  String sellerId,  String? postId,  UserEntity? seller,  List<ProductImageEntity>? images,  int quantity,  int soldCount)?  $default,) {final _that = this;
switch (_that) {
case _ProductEntity() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.price,_that.condition,_that.status,_that.sellerId,_that.postId,_that.seller,_that.images,_that.quantity,_that.soldCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductEntity extends ProductEntity {
  const _ProductEntity({required this.id, required this.title, this.description = '', this.price = 0, @ProductConditionConverter() this.condition = ProductCondition.isNew, @ProductStatusConverter() this.status = ProductStatus.active, required this.sellerId, this.postId, this.seller, final  List<ProductImageEntity>? images, this.quantity = 1, this.soldCount = 0}): _images = images,super._();
  factory _ProductEntity.fromJson(Map<String, dynamic> json) => _$ProductEntityFromJson(json);

@override final  String id;
@override final  String title;
@override@JsonKey() final  String description;
@override@JsonKey() final  int price;
@override@JsonKey()@ProductConditionConverter() final  ProductCondition condition;
@override@JsonKey()@ProductStatusConverter() final  ProductStatus status;
@override final  String sellerId;
@override final  String? postId;
@override final  UserEntity? seller;
 final  List<ProductImageEntity>? _images;
@override List<ProductImageEntity>? get images {
  final value = _images;
  if (value == null) return null;
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey() final  int quantity;
@override@JsonKey() final  int soldCount;

/// Create a copy of ProductEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductEntityCopyWith<_ProductEntity> get copyWith => __$ProductEntityCopyWithImpl<_ProductEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.status, status) || other.status == status)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.seller, seller) || other.seller == seller)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.soldCount, soldCount) || other.soldCount == soldCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,price,condition,status,sellerId,postId,seller,const DeepCollectionEquality().hash(_images),quantity,soldCount);

@override
String toString() {
  return 'ProductEntity(id: $id, title: $title, description: $description, price: $price, condition: $condition, status: $status, sellerId: $sellerId, postId: $postId, seller: $seller, images: $images, quantity: $quantity, soldCount: $soldCount)';
}


}

/// @nodoc
abstract mixin class _$ProductEntityCopyWith<$Res> implements $ProductEntityCopyWith<$Res> {
  factory _$ProductEntityCopyWith(_ProductEntity value, $Res Function(_ProductEntity) _then) = __$ProductEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, int price,@ProductConditionConverter() ProductCondition condition,@ProductStatusConverter() ProductStatus status, String sellerId, String? postId, UserEntity? seller, List<ProductImageEntity>? images, int quantity, int soldCount
});


@override $UserEntityCopyWith<$Res>? get seller;

}
/// @nodoc
class __$ProductEntityCopyWithImpl<$Res>
    implements _$ProductEntityCopyWith<$Res> {
  __$ProductEntityCopyWithImpl(this._self, this._then);

  final _ProductEntity _self;
  final $Res Function(_ProductEntity) _then;

/// Create a copy of ProductEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? price = null,Object? condition = null,Object? status = null,Object? sellerId = null,Object? postId = freezed,Object? seller = freezed,Object? images = freezed,Object? quantity = null,Object? soldCount = null,}) {
  return _then(_ProductEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as ProductCondition,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProductStatus,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,postId: freezed == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String?,seller: freezed == seller ? _self.seller : seller // ignore: cast_nullable_to_non_nullable
as UserEntity?,images: freezed == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<ProductImageEntity>?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,soldCount: null == soldCount ? _self.soldCount : soldCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ProductEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserEntityCopyWith<$Res>? get seller {
    if (_self.seller == null) {
    return null;
  }

  return $UserEntityCopyWith<$Res>(_self.seller!, (value) {
    return _then(_self.copyWith(seller: value));
  });
}
}

// dart format on
