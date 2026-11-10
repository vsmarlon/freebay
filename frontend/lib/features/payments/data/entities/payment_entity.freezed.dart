// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaymentEntity {

 String get orderId; String get stripeSessionId; String get checkoutUrl; DateTime get expiresAt;
/// Create a copy of PaymentEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentEntityCopyWith<PaymentEntity> get copyWith => _$PaymentEntityCopyWithImpl<PaymentEntity>(this as PaymentEntity, _$identity);

  /// Serializes this PaymentEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentEntity&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.stripeSessionId, stripeSessionId) || other.stripeSessionId == stripeSessionId)&&(identical(other.checkoutUrl, checkoutUrl) || other.checkoutUrl == checkoutUrl)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,stripeSessionId,checkoutUrl,expiresAt);

@override
String toString() {
  return 'PaymentEntity(orderId: $orderId, stripeSessionId: $stripeSessionId, checkoutUrl: $checkoutUrl, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $PaymentEntityCopyWith<$Res>  {
  factory $PaymentEntityCopyWith(PaymentEntity value, $Res Function(PaymentEntity) _then) = _$PaymentEntityCopyWithImpl;
@useResult
$Res call({
 String orderId, String stripeSessionId, String checkoutUrl, DateTime expiresAt
});




}
/// @nodoc
class _$PaymentEntityCopyWithImpl<$Res>
    implements $PaymentEntityCopyWith<$Res> {
  _$PaymentEntityCopyWithImpl(this._self, this._then);

  final PaymentEntity _self;
  final $Res Function(PaymentEntity) _then;

/// Create a copy of PaymentEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? stripeSessionId = null,Object? checkoutUrl = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,stripeSessionId: null == stripeSessionId ? _self.stripeSessionId : stripeSessionId // ignore: cast_nullable_to_non_nullable
as String,checkoutUrl: null == checkoutUrl ? _self.checkoutUrl : checkoutUrl // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentEntity].
extension PaymentEntityPatterns on PaymentEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentEntity value)  $default,){
final _that = this;
switch (_that) {
case _PaymentEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentEntity value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String orderId,  String stripeSessionId,  String checkoutUrl,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentEntity() when $default != null:
return $default(_that.orderId,_that.stripeSessionId,_that.checkoutUrl,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String orderId,  String stripeSessionId,  String checkoutUrl,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _PaymentEntity():
return $default(_that.orderId,_that.stripeSessionId,_that.checkoutUrl,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String orderId,  String stripeSessionId,  String checkoutUrl,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _PaymentEntity() when $default != null:
return $default(_that.orderId,_that.stripeSessionId,_that.checkoutUrl,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentEntity implements PaymentEntity {
  const _PaymentEntity({required this.orderId, required this.stripeSessionId, required this.checkoutUrl, required this.expiresAt});
  factory _PaymentEntity.fromJson(Map<String, dynamic> json) => _$PaymentEntityFromJson(json);

@override final  String orderId;
@override final  String stripeSessionId;
@override final  String checkoutUrl;
@override final  DateTime expiresAt;

/// Create a copy of PaymentEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentEntityCopyWith<_PaymentEntity> get copyWith => __$PaymentEntityCopyWithImpl<_PaymentEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentEntity&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.stripeSessionId, stripeSessionId) || other.stripeSessionId == stripeSessionId)&&(identical(other.checkoutUrl, checkoutUrl) || other.checkoutUrl == checkoutUrl)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,stripeSessionId,checkoutUrl,expiresAt);

@override
String toString() {
  return 'PaymentEntity(orderId: $orderId, stripeSessionId: $stripeSessionId, checkoutUrl: $checkoutUrl, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$PaymentEntityCopyWith<$Res> implements $PaymentEntityCopyWith<$Res> {
  factory _$PaymentEntityCopyWith(_PaymentEntity value, $Res Function(_PaymentEntity) _then) = __$PaymentEntityCopyWithImpl;
@override @useResult
$Res call({
 String orderId, String stripeSessionId, String checkoutUrl, DateTime expiresAt
});




}
/// @nodoc
class __$PaymentEntityCopyWithImpl<$Res>
    implements _$PaymentEntityCopyWith<$Res> {
  __$PaymentEntityCopyWithImpl(this._self, this._then);

  final _PaymentEntity _self;
  final $Res Function(_PaymentEntity) _then;

/// Create a copy of PaymentEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? stripeSessionId = null,Object? checkoutUrl = null,Object? expiresAt = null,}) {
  return _then(_PaymentEntity(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,stripeSessionId: null == stripeSessionId ? _self.stripeSessionId : stripeSessionId // ignore: cast_nullable_to_non_nullable
as String,checkoutUrl: null == checkoutUrl ? _self.checkoutUrl : checkoutUrl // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
