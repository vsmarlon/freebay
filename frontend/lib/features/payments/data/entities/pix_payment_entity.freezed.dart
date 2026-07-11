// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pix_payment_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PixPaymentEntity {

 String get orderId; String get pixQrCode; String get pixImage; DateTime get expiresAt;
/// Create a copy of PixPaymentEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PixPaymentEntityCopyWith<PixPaymentEntity> get copyWith => _$PixPaymentEntityCopyWithImpl<PixPaymentEntity>(this as PixPaymentEntity, _$identity);

  /// Serializes this PixPaymentEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PixPaymentEntity&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.pixQrCode, pixQrCode) || other.pixQrCode == pixQrCode)&&(identical(other.pixImage, pixImage) || other.pixImage == pixImage)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,pixQrCode,pixImage,expiresAt);

@override
String toString() {
  return 'PixPaymentEntity(orderId: $orderId, pixQrCode: $pixQrCode, pixImage: $pixImage, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $PixPaymentEntityCopyWith<$Res>  {
  factory $PixPaymentEntityCopyWith(PixPaymentEntity value, $Res Function(PixPaymentEntity) _then) = _$PixPaymentEntityCopyWithImpl;
@useResult
$Res call({
 String orderId, String pixQrCode, String pixImage, DateTime expiresAt
});




}
/// @nodoc
class _$PixPaymentEntityCopyWithImpl<$Res>
    implements $PixPaymentEntityCopyWith<$Res> {
  _$PixPaymentEntityCopyWithImpl(this._self, this._then);

  final PixPaymentEntity _self;
  final $Res Function(PixPaymentEntity) _then;

/// Create a copy of PixPaymentEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? pixQrCode = null,Object? pixImage = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,pixQrCode: null == pixQrCode ? _self.pixQrCode : pixQrCode // ignore: cast_nullable_to_non_nullable
as String,pixImage: null == pixImage ? _self.pixImage : pixImage // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PixPaymentEntity].
extension PixPaymentEntityPatterns on PixPaymentEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PixPaymentEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PixPaymentEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PixPaymentEntity value)  $default,){
final _that = this;
switch (_that) {
case _PixPaymentEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PixPaymentEntity value)?  $default,){
final _that = this;
switch (_that) {
case _PixPaymentEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String orderId,  String pixQrCode,  String pixImage,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PixPaymentEntity() when $default != null:
return $default(_that.orderId,_that.pixQrCode,_that.pixImage,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String orderId,  String pixQrCode,  String pixImage,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _PixPaymentEntity():
return $default(_that.orderId,_that.pixQrCode,_that.pixImage,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String orderId,  String pixQrCode,  String pixImage,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _PixPaymentEntity() when $default != null:
return $default(_that.orderId,_that.pixQrCode,_that.pixImage,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PixPaymentEntity implements PixPaymentEntity {
  const _PixPaymentEntity({required this.orderId, this.pixQrCode = '', this.pixImage = '', required this.expiresAt});
  factory _PixPaymentEntity.fromJson(Map<String, dynamic> json) => _$PixPaymentEntityFromJson(json);

@override final  String orderId;
@override@JsonKey() final  String pixQrCode;
@override@JsonKey() final  String pixImage;
@override final  DateTime expiresAt;

/// Create a copy of PixPaymentEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PixPaymentEntityCopyWith<_PixPaymentEntity> get copyWith => __$PixPaymentEntityCopyWithImpl<_PixPaymentEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PixPaymentEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PixPaymentEntity&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.pixQrCode, pixQrCode) || other.pixQrCode == pixQrCode)&&(identical(other.pixImage, pixImage) || other.pixImage == pixImage)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,pixQrCode,pixImage,expiresAt);

@override
String toString() {
  return 'PixPaymentEntity(orderId: $orderId, pixQrCode: $pixQrCode, pixImage: $pixImage, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$PixPaymentEntityCopyWith<$Res> implements $PixPaymentEntityCopyWith<$Res> {
  factory _$PixPaymentEntityCopyWith(_PixPaymentEntity value, $Res Function(_PixPaymentEntity) _then) = __$PixPaymentEntityCopyWithImpl;
@override @useResult
$Res call({
 String orderId, String pixQrCode, String pixImage, DateTime expiresAt
});




}
/// @nodoc
class __$PixPaymentEntityCopyWithImpl<$Res>
    implements _$PixPaymentEntityCopyWith<$Res> {
  __$PixPaymentEntityCopyWithImpl(this._self, this._then);

  final _PixPaymentEntity _self;
  final $Res Function(_PixPaymentEntity) _then;

/// Create a copy of PixPaymentEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? pixQrCode = null,Object? pixImage = null,Object? expiresAt = null,}) {
  return _then(_PixPaymentEntity(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,pixQrCode: null == pixQrCode ? _self.pixQrCode : pixQrCode // ignore: cast_nullable_to_non_nullable
as String,pixImage: null == pixImage ? _self.pixImage : pixImage // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
