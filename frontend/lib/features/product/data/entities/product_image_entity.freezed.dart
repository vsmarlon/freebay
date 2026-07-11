// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_image_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProductImageEntity {

 String get id; String get url; int get order; String get productId;
/// Create a copy of ProductImageEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductImageEntityCopyWith<ProductImageEntity> get copyWith => _$ProductImageEntityCopyWithImpl<ProductImageEntity>(this as ProductImageEntity, _$identity);

  /// Serializes this ProductImageEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductImageEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.order, order) || other.order == order)&&(identical(other.productId, productId) || other.productId == productId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,order,productId);

@override
String toString() {
  return 'ProductImageEntity(id: $id, url: $url, order: $order, productId: $productId)';
}


}

/// @nodoc
abstract mixin class $ProductImageEntityCopyWith<$Res>  {
  factory $ProductImageEntityCopyWith(ProductImageEntity value, $Res Function(ProductImageEntity) _then) = _$ProductImageEntityCopyWithImpl;
@useResult
$Res call({
 String id, String url, int order, String productId
});




}
/// @nodoc
class _$ProductImageEntityCopyWithImpl<$Res>
    implements $ProductImageEntityCopyWith<$Res> {
  _$ProductImageEntityCopyWithImpl(this._self, this._then);

  final ProductImageEntity _self;
  final $Res Function(ProductImageEntity) _then;

/// Create a copy of ProductImageEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? url = null,Object? order = null,Object? productId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductImageEntity].
extension ProductImageEntityPatterns on ProductImageEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductImageEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductImageEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductImageEntity value)  $default,){
final _that = this;
switch (_that) {
case _ProductImageEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductImageEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ProductImageEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String url,  int order,  String productId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductImageEntity() when $default != null:
return $default(_that.id,_that.url,_that.order,_that.productId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String url,  int order,  String productId)  $default,) {final _that = this;
switch (_that) {
case _ProductImageEntity():
return $default(_that.id,_that.url,_that.order,_that.productId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String url,  int order,  String productId)?  $default,) {final _that = this;
switch (_that) {
case _ProductImageEntity() when $default != null:
return $default(_that.id,_that.url,_that.order,_that.productId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductImageEntity implements ProductImageEntity {
  const _ProductImageEntity({required this.id, required this.url, this.order = 0, required this.productId});
  factory _ProductImageEntity.fromJson(Map<String, dynamic> json) => _$ProductImageEntityFromJson(json);

@override final  String id;
@override final  String url;
@override@JsonKey() final  int order;
@override final  String productId;

/// Create a copy of ProductImageEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductImageEntityCopyWith<_ProductImageEntity> get copyWith => __$ProductImageEntityCopyWithImpl<_ProductImageEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductImageEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductImageEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.order, order) || other.order == order)&&(identical(other.productId, productId) || other.productId == productId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,order,productId);

@override
String toString() {
  return 'ProductImageEntity(id: $id, url: $url, order: $order, productId: $productId)';
}


}

/// @nodoc
abstract mixin class _$ProductImageEntityCopyWith<$Res> implements $ProductImageEntityCopyWith<$Res> {
  factory _$ProductImageEntityCopyWith(_ProductImageEntity value, $Res Function(_ProductImageEntity) _then) = __$ProductImageEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String url, int order, String productId
});




}
/// @nodoc
class __$ProductImageEntityCopyWithImpl<$Res>
    implements _$ProductImageEntityCopyWith<$Res> {
  __$ProductImageEntityCopyWithImpl(this._self, this._then);

  final _ProductImageEntity _self;
  final $Res Function(_ProductImageEntity) _then;

/// Create a copy of ProductImageEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? url = null,Object? order = null,Object? productId = null,}) {
  return _then(_ProductImageEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
