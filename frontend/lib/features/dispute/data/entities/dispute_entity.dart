import 'package:equatable/equatable.dart';

class DisputeEntity extends Equatable {
  final String id;
  final String orderId;
  final String openedById;
  final String reason;
  final String status;
  final String? resolution;
  final String? buyerEvidence;
  final String? sellerEvidence;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? resolvedAt;
  final String? otherUserName;
  final String? otherUserAvatar;

  const DisputeEntity({
    required this.id,
    required this.orderId,
    required this.openedById,
    required this.reason,
    required this.status,
    this.resolution,
    this.buyerEvidence,
    this.sellerEvidence,
    required this.createdAt,
    required this.expiresAt,
    this.resolvedAt,
    this.otherUserName,
    this.otherUserAvatar,
  });

  factory DisputeEntity.fromJson(Map<String, dynamic> json) {
    return DisputeEntity(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      openedById: json['openedById'] as String,
      reason: json['reason'] as String,
      status: json['status'] as String,
      resolution: json['resolution'] as String?,
      buyerEvidence: json['buyerEvidence']?.toString(),
      sellerEvidence: json['sellerEvidence']?.toString(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'] as String) : null,
      otherUserName: json['openedBy']?['displayName'] as String?,
      otherUserAvatar: json['openedBy']?['avatarUrl'] as String?,
    );
  }

  bool get isOpen => status == 'OPEN' || status == 'AWAITING_SELLER' || status == 'AWAITING_BUYER';
  bool get isResolved => status == 'RESOLVED';
  bool get isCancelled => status == 'CANCELLED';

  @override
  List<Object?> get props => [id, status];
}
