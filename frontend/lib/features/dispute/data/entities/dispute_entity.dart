import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dispute_entity.g.dart';

enum DisputeStatus {
  open,
  awaitingSeller,
  awaitingBuyer,
  resolved,
  cancelled;

  static DisputeStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'OPEN':
        return DisputeStatus.open;
      case 'AWAITING_SELLER':
        return DisputeStatus.awaitingSeller;
      case 'AWAITING_BUYER':
        return DisputeStatus.awaitingBuyer;
      case 'RESOLVED':
        return DisputeStatus.resolved;
      case 'CANCELLED':
        return DisputeStatus.cancelled;
      default:
        return DisputeStatus.open;
    }
  }

  String get label {
    switch (this) {
      case DisputeStatus.open:
        return 'Aberta';
      case DisputeStatus.awaitingSeller:
        return 'Aguardando vendedor';
      case DisputeStatus.awaitingBuyer:
        return 'Aguardando comprador';
      case DisputeStatus.resolved:
        return 'Resolvida';
      case DisputeStatus.cancelled:
        return 'Cancelada';
    }
  }

  String toApiString() => switch (this) {
        DisputeStatus.open => 'OPEN',
        DisputeStatus.awaitingSeller => 'AWAITING_SELLER',
        DisputeStatus.awaitingBuyer => 'AWAITING_BUYER',
        DisputeStatus.resolved => 'RESOLVED',
        DisputeStatus.cancelled => 'CANCELLED',
      };
}

String _disputeStatusToJson(DisputeStatus status) => status.toApiString();

@JsonSerializable()
class DisputeEntity extends Equatable {
  final String id;
  final String orderId;
  final String openedById;
  final String reason;
  @JsonKey(fromJson: DisputeStatus.fromString, toJson: _disputeStatusToJson)
  final DisputeStatus status;
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
    final normalized = Map<String, dynamic>.from(json);
    normalized['buyerEvidence'] = json['buyerEvidence']?.toString();
    normalized['sellerEvidence'] = json['sellerEvidence']?.toString();
    normalized['otherUserName'] = json['openedBy']?['displayName'] as String?;
    normalized['otherUserAvatar'] = json['openedBy']?['avatarUrl'] as String?;
    return _$DisputeEntityFromJson(normalized);
  }

  Map<String, dynamic> toJson() => _$DisputeEntityToJson(this);

  bool get isOpen =>
      status == DisputeStatus.open ||
      status == DisputeStatus.awaitingSeller ||
      status == DisputeStatus.awaitingBuyer;
  bool get isResolved => status == DisputeStatus.resolved;
  bool get isCancelled => status == DisputeStatus.cancelled;

  @override
  List<Object?> get props => [id, status];
}
