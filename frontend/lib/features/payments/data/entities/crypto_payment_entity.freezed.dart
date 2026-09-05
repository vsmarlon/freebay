// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'crypto_payment_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CryptoPaymentEntity {

 String get orderId; String get currency; String get address; String? get paymentId; String get uriQrCode; String get amountAtomic; String get amountHuman; DateTime get expiresAt;
/// Create a copy of CryptoPaymentEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CryptoPaymentEntityCopyWith<CryptoPaymentEntity> get copyWith => _$CryptoPaymentEntityCopyWithImpl<CryptoPaymentEntity>(this as CryptoPaymentEntity, _$identity);

  /// Serializes this CryptoPaymentEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CryptoPaymentEntity&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.address, address) || other.address == address)&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.uriQrCode, uriQrCode) || other.uriQrCode == uriQrCode)&&(identical(other.amountAtomic, amountAtomic) || other.amountAtomic == amountAtomic)&&(identical(other.amountHuman, amountHuman) || other.amountHuman == amountHuman)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,currency,address,paymentId,uriQrCode,amountAtomic,amountHuman,expiresAt);

@override
String toString() {
  return 'CryptoPaymentEntity(orderId: $orderId, currency: $currency, address: $address, paymentId: $paymentId, uriQrCode: $uriQrCode, amountAtomic: $amountAtomic, amountHuman: $amountHuman, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $CryptoPaymentEntityCopyWith<$Res>  {
  factory $CryptoPaymentEntityCopyWith(CryptoPaymentEntity value, $Res Function(CryptoPaymentEntity) _then) = _$CryptoPaymentEntityCopyWithImpl;
@useResult
$Res call({
 String orderId, String currency, String address, String? paymentId, String uriQrCode, String amountAtomic, String amountHuman, DateTime expiresAt
});




}
/// @nodoc
class _$CryptoPaymentEntityCopyWithImpl<$Res>
    implements $CryptoPaymentEntityCopyWith<$Res> {
  _$CryptoPaymentEntityCopyWithImpl(this._self, this._then);

  final CryptoPaymentEntity _self;
  final $Res Function(CryptoPaymentEntity) _then;

/// Create a copy of CryptoPaymentEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? currency = null,Object? address = null,Object? paymentId = freezed,Object? uriQrCode = null,Object? amountAtomic = null,Object? amountHuman = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,paymentId: freezed == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String?,uriQrCode: null == uriQrCode ? _self.uriQrCode : uriQrCode // ignore: cast_nullable_to_non_nullable
as String,amountAtomic: null == amountAtomic ? _self.amountAtomic : amountAtomic // ignore: cast_nullable_to_non_nullable
as String,amountHuman: null == amountHuman ? _self.amountHuman : amountHuman // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CryptoPaymentEntity].
extension CryptoPaymentEntityPatterns on CryptoPaymentEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CryptoPaymentEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CryptoPaymentEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CryptoPaymentEntity value)  $default,){
final _that = this;
switch (_that) {
case _CryptoPaymentEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CryptoPaymentEntity value)?  $default,){
final _that = this;
switch (_that) {
case _CryptoPaymentEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String orderId,  String currency,  String address,  String? paymentId,  String uriQrCode,  String amountAtomic,  String amountHuman,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CryptoPaymentEntity() when $default != null:
return $default(_that.orderId,_that.currency,_that.address,_that.paymentId,_that.uriQrCode,_that.amountAtomic,_that.amountHuman,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String orderId,  String currency,  String address,  String? paymentId,  String uriQrCode,  String amountAtomic,  String amountHuman,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _CryptoPaymentEntity():
return $default(_that.orderId,_that.currency,_that.address,_that.paymentId,_that.uriQrCode,_that.amountAtomic,_that.amountHuman,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String orderId,  String currency,  String address,  String? paymentId,  String uriQrCode,  String amountAtomic,  String amountHuman,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _CryptoPaymentEntity() when $default != null:
return $default(_that.orderId,_that.currency,_that.address,_that.paymentId,_that.uriQrCode,_that.amountAtomic,_that.amountHuman,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CryptoPaymentEntity implements CryptoPaymentEntity {
  const _CryptoPaymentEntity({required this.orderId, this.currency = 'XMR', required this.address, this.paymentId, required this.uriQrCode, required this.amountAtomic, required this.amountHuman, required this.expiresAt});
  factory _CryptoPaymentEntity.fromJson(Map<String, dynamic> json) => _$CryptoPaymentEntityFromJson(json);

@override final  String orderId;
@override@JsonKey() final  String currency;
@override final  String address;
@override final  String? paymentId;
@override final  String uriQrCode;
@override final  String amountAtomic;
@override final  String amountHuman;
@override final  DateTime expiresAt;

/// Create a copy of CryptoPaymentEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CryptoPaymentEntityCopyWith<_CryptoPaymentEntity> get copyWith => __$CryptoPaymentEntityCopyWithImpl<_CryptoPaymentEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CryptoPaymentEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CryptoPaymentEntity&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.address, address) || other.address == address)&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.uriQrCode, uriQrCode) || other.uriQrCode == uriQrCode)&&(identical(other.amountAtomic, amountAtomic) || other.amountAtomic == amountAtomic)&&(identical(other.amountHuman, amountHuman) || other.amountHuman == amountHuman)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,currency,address,paymentId,uriQrCode,amountAtomic,amountHuman,expiresAt);

@override
String toString() {
  return 'CryptoPaymentEntity(orderId: $orderId, currency: $currency, address: $address, paymentId: $paymentId, uriQrCode: $uriQrCode, amountAtomic: $amountAtomic, amountHuman: $amountHuman, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$CryptoPaymentEntityCopyWith<$Res> implements $CryptoPaymentEntityCopyWith<$Res> {
  factory _$CryptoPaymentEntityCopyWith(_CryptoPaymentEntity value, $Res Function(_CryptoPaymentEntity) _then) = __$CryptoPaymentEntityCopyWithImpl;
@override @useResult
$Res call({
 String orderId, String currency, String address, String? paymentId, String uriQrCode, String amountAtomic, String amountHuman, DateTime expiresAt
});




}
/// @nodoc
class __$CryptoPaymentEntityCopyWithImpl<$Res>
    implements _$CryptoPaymentEntityCopyWith<$Res> {
  __$CryptoPaymentEntityCopyWithImpl(this._self, this._then);

  final _CryptoPaymentEntity _self;
  final $Res Function(_CryptoPaymentEntity) _then;

/// Create a copy of CryptoPaymentEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? currency = null,Object? address = null,Object? paymentId = freezed,Object? uriQrCode = null,Object? amountAtomic = null,Object? amountHuman = null,Object? expiresAt = null,}) {
  return _then(_CryptoPaymentEntity(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,paymentId: freezed == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String?,uriQrCode: null == uriQrCode ? _self.uriQrCode : uriQrCode // ignore: cast_nullable_to_non_nullable
as String,amountAtomic: null == amountAtomic ? _self.amountAtomic : amountAtomic // ignore: cast_nullable_to_non_nullable
as String,amountHuman: null == amountHuman ? _self.amountHuman : amountHuman // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
