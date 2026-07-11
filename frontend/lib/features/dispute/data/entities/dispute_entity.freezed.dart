// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dispute_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DisputeEntity {

 String get id; String get orderId; String get openedById; String get reason;@JsonKey(fromJson: DisputeStatus.fromString, toJson: _disputeStatusToJson) DisputeStatus get status; String? get resolution; dynamic get buyerEvidence; dynamic get sellerEvidence; DateTime get createdAt; DateTime get expiresAt; DateTime? get resolvedAt; UserEntity? get openedBy;
/// Create a copy of DisputeEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DisputeEntityCopyWith<DisputeEntity> get copyWith => _$DisputeEntityCopyWithImpl<DisputeEntity>(this as DisputeEntity, _$identity);

  /// Serializes this DisputeEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DisputeEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.openedById, openedById) || other.openedById == openedById)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.status, status) || other.status == status)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&const DeepCollectionEquality().equals(other.buyerEvidence, buyerEvidence)&&const DeepCollectionEquality().equals(other.sellerEvidence, sellerEvidence)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.openedBy, openedBy) || other.openedBy == openedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,openedById,reason,status,resolution,const DeepCollectionEquality().hash(buyerEvidence),const DeepCollectionEquality().hash(sellerEvidence),createdAt,expiresAt,resolvedAt,openedBy);

@override
String toString() {
  return 'DisputeEntity(id: $id, orderId: $orderId, openedById: $openedById, reason: $reason, status: $status, resolution: $resolution, buyerEvidence: $buyerEvidence, sellerEvidence: $sellerEvidence, createdAt: $createdAt, expiresAt: $expiresAt, resolvedAt: $resolvedAt, openedBy: $openedBy)';
}


}

/// @nodoc
abstract mixin class $DisputeEntityCopyWith<$Res>  {
  factory $DisputeEntityCopyWith(DisputeEntity value, $Res Function(DisputeEntity) _then) = _$DisputeEntityCopyWithImpl;
@useResult
$Res call({
 String id, String orderId, String openedById, String reason,@JsonKey(fromJson: DisputeStatus.fromString, toJson: _disputeStatusToJson) DisputeStatus status, String? resolution, dynamic buyerEvidence, dynamic sellerEvidence, DateTime createdAt, DateTime expiresAt, DateTime? resolvedAt, UserEntity? openedBy
});


$UserEntityCopyWith<$Res>? get openedBy;

}
/// @nodoc
class _$DisputeEntityCopyWithImpl<$Res>
    implements $DisputeEntityCopyWith<$Res> {
  _$DisputeEntityCopyWithImpl(this._self, this._then);

  final DisputeEntity _self;
  final $Res Function(DisputeEntity) _then;

/// Create a copy of DisputeEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderId = null,Object? openedById = null,Object? reason = null,Object? status = null,Object? resolution = freezed,Object? buyerEvidence = freezed,Object? sellerEvidence = freezed,Object? createdAt = null,Object? expiresAt = null,Object? resolvedAt = freezed,Object? openedBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,openedById: null == openedById ? _self.openedById : openedById // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DisputeStatus,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as String?,buyerEvidence: freezed == buyerEvidence ? _self.buyerEvidence : buyerEvidence // ignore: cast_nullable_to_non_nullable
as dynamic,sellerEvidence: freezed == sellerEvidence ? _self.sellerEvidence : sellerEvidence // ignore: cast_nullable_to_non_nullable
as dynamic,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,openedBy: freezed == openedBy ? _self.openedBy : openedBy // ignore: cast_nullable_to_non_nullable
as UserEntity?,
  ));
}
/// Create a copy of DisputeEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserEntityCopyWith<$Res>? get openedBy {
    if (_self.openedBy == null) {
    return null;
  }

  return $UserEntityCopyWith<$Res>(_self.openedBy!, (value) {
    return _then(_self.copyWith(openedBy: value));
  });
}
}


/// Adds pattern-matching-related methods to [DisputeEntity].
extension DisputeEntityPatterns on DisputeEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DisputeEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DisputeEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DisputeEntity value)  $default,){
final _that = this;
switch (_that) {
case _DisputeEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DisputeEntity value)?  $default,){
final _that = this;
switch (_that) {
case _DisputeEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String orderId,  String openedById,  String reason, @JsonKey(fromJson: DisputeStatus.fromString, toJson: _disputeStatusToJson)  DisputeStatus status,  String? resolution,  dynamic buyerEvidence,  dynamic sellerEvidence,  DateTime createdAt,  DateTime expiresAt,  DateTime? resolvedAt,  UserEntity? openedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DisputeEntity() when $default != null:
return $default(_that.id,_that.orderId,_that.openedById,_that.reason,_that.status,_that.resolution,_that.buyerEvidence,_that.sellerEvidence,_that.createdAt,_that.expiresAt,_that.resolvedAt,_that.openedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String orderId,  String openedById,  String reason, @JsonKey(fromJson: DisputeStatus.fromString, toJson: _disputeStatusToJson)  DisputeStatus status,  String? resolution,  dynamic buyerEvidence,  dynamic sellerEvidence,  DateTime createdAt,  DateTime expiresAt,  DateTime? resolvedAt,  UserEntity? openedBy)  $default,) {final _that = this;
switch (_that) {
case _DisputeEntity():
return $default(_that.id,_that.orderId,_that.openedById,_that.reason,_that.status,_that.resolution,_that.buyerEvidence,_that.sellerEvidence,_that.createdAt,_that.expiresAt,_that.resolvedAt,_that.openedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String orderId,  String openedById,  String reason, @JsonKey(fromJson: DisputeStatus.fromString, toJson: _disputeStatusToJson)  DisputeStatus status,  String? resolution,  dynamic buyerEvidence,  dynamic sellerEvidence,  DateTime createdAt,  DateTime expiresAt,  DateTime? resolvedAt,  UserEntity? openedBy)?  $default,) {final _that = this;
switch (_that) {
case _DisputeEntity() when $default != null:
return $default(_that.id,_that.orderId,_that.openedById,_that.reason,_that.status,_that.resolution,_that.buyerEvidence,_that.sellerEvidence,_that.createdAt,_that.expiresAt,_that.resolvedAt,_that.openedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DisputeEntity extends DisputeEntity {
  const _DisputeEntity({required this.id, required this.orderId, required this.openedById, required this.reason, @JsonKey(fromJson: DisputeStatus.fromString, toJson: _disputeStatusToJson) required this.status, this.resolution, this.buyerEvidence, this.sellerEvidence, required this.createdAt, required this.expiresAt, this.resolvedAt, this.openedBy}): super._();
  factory _DisputeEntity.fromJson(Map<String, dynamic> json) => _$DisputeEntityFromJson(json);

@override final  String id;
@override final  String orderId;
@override final  String openedById;
@override final  String reason;
@override@JsonKey(fromJson: DisputeStatus.fromString, toJson: _disputeStatusToJson) final  DisputeStatus status;
@override final  String? resolution;
@override final  dynamic buyerEvidence;
@override final  dynamic sellerEvidence;
@override final  DateTime createdAt;
@override final  DateTime expiresAt;
@override final  DateTime? resolvedAt;
@override final  UserEntity? openedBy;

/// Create a copy of DisputeEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DisputeEntityCopyWith<_DisputeEntity> get copyWith => __$DisputeEntityCopyWithImpl<_DisputeEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DisputeEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DisputeEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.openedById, openedById) || other.openedById == openedById)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.status, status) || other.status == status)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&const DeepCollectionEquality().equals(other.buyerEvidence, buyerEvidence)&&const DeepCollectionEquality().equals(other.sellerEvidence, sellerEvidence)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.openedBy, openedBy) || other.openedBy == openedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,openedById,reason,status,resolution,const DeepCollectionEquality().hash(buyerEvidence),const DeepCollectionEquality().hash(sellerEvidence),createdAt,expiresAt,resolvedAt,openedBy);

@override
String toString() {
  return 'DisputeEntity(id: $id, orderId: $orderId, openedById: $openedById, reason: $reason, status: $status, resolution: $resolution, buyerEvidence: $buyerEvidence, sellerEvidence: $sellerEvidence, createdAt: $createdAt, expiresAt: $expiresAt, resolvedAt: $resolvedAt, openedBy: $openedBy)';
}


}

/// @nodoc
abstract mixin class _$DisputeEntityCopyWith<$Res> implements $DisputeEntityCopyWith<$Res> {
  factory _$DisputeEntityCopyWith(_DisputeEntity value, $Res Function(_DisputeEntity) _then) = __$DisputeEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String orderId, String openedById, String reason,@JsonKey(fromJson: DisputeStatus.fromString, toJson: _disputeStatusToJson) DisputeStatus status, String? resolution, dynamic buyerEvidence, dynamic sellerEvidence, DateTime createdAt, DateTime expiresAt, DateTime? resolvedAt, UserEntity? openedBy
});


@override $UserEntityCopyWith<$Res>? get openedBy;

}
/// @nodoc
class __$DisputeEntityCopyWithImpl<$Res>
    implements _$DisputeEntityCopyWith<$Res> {
  __$DisputeEntityCopyWithImpl(this._self, this._then);

  final _DisputeEntity _self;
  final $Res Function(_DisputeEntity) _then;

/// Create a copy of DisputeEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderId = null,Object? openedById = null,Object? reason = null,Object? status = null,Object? resolution = freezed,Object? buyerEvidence = freezed,Object? sellerEvidence = freezed,Object? createdAt = null,Object? expiresAt = null,Object? resolvedAt = freezed,Object? openedBy = freezed,}) {
  return _then(_DisputeEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,openedById: null == openedById ? _self.openedById : openedById // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DisputeStatus,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as String?,buyerEvidence: freezed == buyerEvidence ? _self.buyerEvidence : buyerEvidence // ignore: cast_nullable_to_non_nullable
as dynamic,sellerEvidence: freezed == sellerEvidence ? _self.sellerEvidence : sellerEvidence // ignore: cast_nullable_to_non_nullable
as dynamic,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,openedBy: freezed == openedBy ? _self.openedBy : openedBy // ignore: cast_nullable_to_non_nullable
as UserEntity?,
  ));
}

/// Create a copy of DisputeEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserEntityCopyWith<$Res>? get openedBy {
    if (_self.openedBy == null) {
    return null;
  }

  return $UserEntityCopyWith<$Res>(_self.openedBy!, (value) {
    return _then(_self.copyWith(openedBy: value));
  });
}
}

// dart format on
