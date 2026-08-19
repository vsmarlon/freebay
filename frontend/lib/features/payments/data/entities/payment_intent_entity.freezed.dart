// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_intent_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaymentIntentEntity {

 String get orderId; String get paymentIntentClientSecret;
/// Create a copy of PaymentIntentEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentIntentEntityCopyWith<PaymentIntentEntity> get copyWith => _$PaymentIntentEntityCopyWithImpl<PaymentIntentEntity>(this as PaymentIntentEntity, _$identity);

  /// Serializes this PaymentIntentEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentIntentEntity&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.paymentIntentClientSecret, paymentIntentClientSecret) || other.paymentIntentClientSecret == paymentIntentClientSecret));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,paymentIntentClientSecret);

@override
String toString() {
  return 'PaymentIntentEntity(orderId: $orderId, paymentIntentClientSecret: $paymentIntentClientSecret)';
}


}

/// @nodoc
abstract mixin class $PaymentIntentEntityCopyWith<$Res>  {
  factory $PaymentIntentEntityCopyWith(PaymentIntentEntity value, $Res Function(PaymentIntentEntity) _then) = _$PaymentIntentEntityCopyWithImpl;
@useResult
$Res call({
 String orderId, String paymentIntentClientSecret
});




}
/// @nodoc
class _$PaymentIntentEntityCopyWithImpl<$Res>
    implements $PaymentIntentEntityCopyWith<$Res> {
  _$PaymentIntentEntityCopyWithImpl(this._self, this._then);

  final PaymentIntentEntity _self;
  final $Res Function(PaymentIntentEntity) _then;

/// Create a copy of PaymentIntentEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? paymentIntentClientSecret = null,}) {
  return _then(_self.copyWith(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,paymentIntentClientSecret: null == paymentIntentClientSecret ? _self.paymentIntentClientSecret : paymentIntentClientSecret // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentIntentEntity].
extension PaymentIntentEntityPatterns on PaymentIntentEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentIntentEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentIntentEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentIntentEntity value)  $default,){
final _that = this;
switch (_that) {
case _PaymentIntentEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentIntentEntity value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentIntentEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String orderId,  String paymentIntentClientSecret)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentIntentEntity() when $default != null:
return $default(_that.orderId,_that.paymentIntentClientSecret);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String orderId,  String paymentIntentClientSecret)  $default,) {final _that = this;
switch (_that) {
case _PaymentIntentEntity():
return $default(_that.orderId,_that.paymentIntentClientSecret);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String orderId,  String paymentIntentClientSecret)?  $default,) {final _that = this;
switch (_that) {
case _PaymentIntentEntity() when $default != null:
return $default(_that.orderId,_that.paymentIntentClientSecret);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentIntentEntity implements PaymentIntentEntity {
  const _PaymentIntentEntity({required this.orderId, required this.paymentIntentClientSecret});
  factory _PaymentIntentEntity.fromJson(Map<String, dynamic> json) => _$PaymentIntentEntityFromJson(json);

@override final  String orderId;
@override final  String paymentIntentClientSecret;

/// Create a copy of PaymentIntentEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentIntentEntityCopyWith<_PaymentIntentEntity> get copyWith => __$PaymentIntentEntityCopyWithImpl<_PaymentIntentEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentIntentEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentIntentEntity&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.paymentIntentClientSecret, paymentIntentClientSecret) || other.paymentIntentClientSecret == paymentIntentClientSecret));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,paymentIntentClientSecret);

@override
String toString() {
  return 'PaymentIntentEntity(orderId: $orderId, paymentIntentClientSecret: $paymentIntentClientSecret)';
}


}

/// @nodoc
abstract mixin class _$PaymentIntentEntityCopyWith<$Res> implements $PaymentIntentEntityCopyWith<$Res> {
  factory _$PaymentIntentEntityCopyWith(_PaymentIntentEntity value, $Res Function(_PaymentIntentEntity) _then) = __$PaymentIntentEntityCopyWithImpl;
@override @useResult
$Res call({
 String orderId, String paymentIntentClientSecret
});




}
/// @nodoc
class __$PaymentIntentEntityCopyWithImpl<$Res>
    implements _$PaymentIntentEntityCopyWith<$Res> {
  __$PaymentIntentEntityCopyWithImpl(this._self, this._then);

  final _PaymentIntentEntity _self;
  final $Res Function(_PaymentIntentEntity) _then;

/// Create a copy of PaymentIntentEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? paymentIntentClientSecret = null,}) {
  return _then(_PaymentIntentEntity(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,paymentIntentClientSecret: null == paymentIntentClientSecret ? _self.paymentIntentClientSecret : paymentIntentClientSecret // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
