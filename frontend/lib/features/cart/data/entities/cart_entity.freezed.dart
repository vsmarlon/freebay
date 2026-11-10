// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cart_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CartEntity {

 List<CartItemEntity> get items; int get totalItems; int get totalPrice;
/// Create a copy of CartEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartEntityCopyWith<CartEntity> get copyWith => _$CartEntityCopyWithImpl<CartEntity>(this as CartEntity, _$identity);

  /// Serializes this CartEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartEntity&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.totalPrice, totalPrice) || other.totalPrice == totalPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),totalItems,totalPrice);

@override
String toString() {
  return 'CartEntity(items: $items, totalItems: $totalItems, totalPrice: $totalPrice)';
}


}

/// @nodoc
abstract mixin class $CartEntityCopyWith<$Res>  {
  factory $CartEntityCopyWith(CartEntity value, $Res Function(CartEntity) _then) = _$CartEntityCopyWithImpl;
@useResult
$Res call({
 List<CartItemEntity> items, int totalItems, int totalPrice
});




}
/// @nodoc
class _$CartEntityCopyWithImpl<$Res>
    implements $CartEntityCopyWith<$Res> {
  _$CartEntityCopyWithImpl(this._self, this._then);

  final CartEntity _self;
  final $Res Function(CartEntity) _then;

/// Create a copy of CartEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? totalItems = null,Object? totalPrice = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CartItemEntity>,totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,totalPrice: null == totalPrice ? _self.totalPrice : totalPrice // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CartEntity].
extension CartEntityPatterns on CartEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CartEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CartEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CartEntity value)  $default,){
final _that = this;
switch (_that) {
case _CartEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CartEntity value)?  $default,){
final _that = this;
switch (_that) {
case _CartEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CartItemEntity> items,  int totalItems,  int totalPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CartEntity() when $default != null:
return $default(_that.items,_that.totalItems,_that.totalPrice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CartItemEntity> items,  int totalItems,  int totalPrice)  $default,) {final _that = this;
switch (_that) {
case _CartEntity():
return $default(_that.items,_that.totalItems,_that.totalPrice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CartItemEntity> items,  int totalItems,  int totalPrice)?  $default,) {final _that = this;
switch (_that) {
case _CartEntity() when $default != null:
return $default(_that.items,_that.totalItems,_that.totalPrice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CartEntity implements CartEntity {
  const _CartEntity({final  List<CartItemEntity> items = const [], this.totalItems = 0, this.totalPrice = 0}): _items = items;
  factory _CartEntity.fromJson(Map<String, dynamic> json) => _$CartEntityFromJson(json);

 final  List<CartItemEntity> _items;
@override@JsonKey() List<CartItemEntity> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int totalItems;
@override@JsonKey() final  int totalPrice;

/// Create a copy of CartEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CartEntityCopyWith<_CartEntity> get copyWith => __$CartEntityCopyWithImpl<_CartEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CartEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CartEntity&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.totalPrice, totalPrice) || other.totalPrice == totalPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),totalItems,totalPrice);

@override
String toString() {
  return 'CartEntity(items: $items, totalItems: $totalItems, totalPrice: $totalPrice)';
}


}

/// @nodoc
abstract mixin class _$CartEntityCopyWith<$Res> implements $CartEntityCopyWith<$Res> {
  factory _$CartEntityCopyWith(_CartEntity value, $Res Function(_CartEntity) _then) = __$CartEntityCopyWithImpl;
@override @useResult
$Res call({
 List<CartItemEntity> items, int totalItems, int totalPrice
});




}
/// @nodoc
class __$CartEntityCopyWithImpl<$Res>
    implements _$CartEntityCopyWith<$Res> {
  __$CartEntityCopyWithImpl(this._self, this._then);

  final _CartEntity _self;
  final $Res Function(_CartEntity) _then;

/// Create a copy of CartEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? totalItems = null,Object? totalPrice = null,}) {
  return _then(_CartEntity(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CartItemEntity>,totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,totalPrice: null == totalPrice ? _self.totalPrice : totalPrice // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
