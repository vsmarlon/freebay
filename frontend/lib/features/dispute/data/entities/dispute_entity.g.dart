// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispute_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisputeEntity _$DisputeEntityFromJson(Map<String, dynamic> json) =>
    DisputeEntity(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      openedById: json['openedById'] as String,
      reason: json['reason'] as String,
      status: DisputeStatus.fromString(json['status'] as String),
      resolution: json['resolution'] as String?,
      buyerEvidence: json['buyerEvidence'] as String?,
      sellerEvidence: json['sellerEvidence'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
      otherUserName: json['otherUserName'] as String?,
      otherUserAvatar: json['otherUserAvatar'] as String?,
    );

Map<String, dynamic> _$DisputeEntityToJson(DisputeEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'openedById': instance.openedById,
      'reason': instance.reason,
      'status': _disputeStatusToJson(instance.status),
      'resolution': instance.resolution,
      'buyerEvidence': instance.buyerEvidence,
      'sellerEvidence': instance.sellerEvidence,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'resolvedAt': instance.resolvedAt?.toIso8601String(),
      'otherUserName': instance.otherUserName,
      'otherUserAvatar': instance.otherUserAvatar,
    };
