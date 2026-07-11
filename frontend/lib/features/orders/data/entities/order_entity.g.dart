// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrderUserInfo _$OrderUserInfoFromJson(Map<String, dynamic> json) =>
    _OrderUserInfo(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );

Map<String, dynamic> _$OrderUserInfoToJson(_OrderUserInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'isVerified': instance.isVerified,
    };

_OrderEntity _$OrderEntityFromJson(Map<String, dynamic> json) => _OrderEntity(
  id: json['id'] as String,
  buyerId: json['buyerId'] as String,
  sellerId: json['sellerId'] as String,
  productId: json['productId'] as String,
  amount: (json['amount'] as num?)?.toInt() ?? 0,
  platformFee: (json['platformFee'] as num?)?.toInt() ?? 0,
  sellerAmount: (json['sellerAmount'] as num?)?.toInt() ?? 0,
  status: OrderStatus.fromString(json['status'] as String),
  escrowStatus: EscrowStatus.fromString(json['escrowStatus'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  deliveryConfirmedAt: json['deliveryConfirmedAt'] == null
      ? null
      : DateTime.parse(json['deliveryConfirmedAt'] as String),
  product: json['product'] == null
      ? null
      : ProductEntity.fromJson(json['product'] as Map<String, dynamic>),
  buyer: json['buyer'] == null
      ? null
      : OrderUserInfo.fromJson(json['buyer'] as Map<String, dynamic>),
  seller: json['seller'] == null
      ? null
      : OrderUserInfo.fromJson(json['seller'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OrderEntityToJson(_OrderEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'buyerId': instance.buyerId,
      'sellerId': instance.sellerId,
      'productId': instance.productId,
      'amount': instance.amount,
      'platformFee': instance.platformFee,
      'sellerAmount': instance.sellerAmount,
      'status': _orderStatusToJson(instance.status),
      'escrowStatus': _escrowStatusToJson(instance.escrowStatus),
      'createdAt': instance.createdAt.toIso8601String(),
      'deliveryConfirmedAt': instance.deliveryConfirmedAt?.toIso8601String(),
      'product': instance.product,
      'buyer': instance.buyer,
      'seller': instance.seller,
    };

_CanReviewResponse _$CanReviewResponseFromJson(Map<String, dynamic> json) =>
    _CanReviewResponse(
      canReview: json['canReview'] as bool? ?? false,
      reviewType: json['reviewType'] as String?,
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$CanReviewResponseToJson(_CanReviewResponse instance) =>
    <String, dynamic>{
      'canReview': instance.canReview,
      'reviewType': instance.reviewType,
      'reason': instance.reason,
    };
