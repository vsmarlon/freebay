import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

part 'dispute_entity.freezed.dart';
part 'dispute_entity.g.dart';

enum DisputeStatus {
  open,
  awaitingSeller,
  awaitingBuyer,
  resolved,
  cancelled;

  static DisputeStatus fromString(String value) =>
      switch (value.toUpperCase()) {
        'OPEN' => DisputeStatus.open,
        'AWAITING_SELLER' => DisputeStatus.awaitingSeller,
        'AWAITING_BUYER' => DisputeStatus.awaitingBuyer,
        'RESOLVED' => DisputeStatus.resolved,
        'CANCELLED' => DisputeStatus.cancelled,
        _ => DisputeStatus.open,
      };

  String get label => switch (this) {
    DisputeStatus.open => 'Aberta',
    DisputeStatus.awaitingSeller => 'Aguardando vendedor',
    DisputeStatus.awaitingBuyer => 'Aguardando comprador',
    DisputeStatus.resolved => 'Resolvida',
    DisputeStatus.cancelled => 'Cancelada',
  };

  String toApiString() => switch (this) {
    DisputeStatus.open => 'OPEN',
    DisputeStatus.awaitingSeller => 'AWAITING_SELLER',
    DisputeStatus.awaitingBuyer => 'AWAITING_BUYER',
    DisputeStatus.resolved => 'RESOLVED',
    DisputeStatus.cancelled => 'CANCELLED',
  };
}

String _disputeStatusToJson(DisputeStatus status) => status.toApiString();

@freezed
abstract class DisputeEntity with _$DisputeEntity {
  const DisputeEntity._();

  const factory DisputeEntity({
    required String id,
    required String orderId,
    required String openedById,
    required String reason,
    @JsonKey(fromJson: DisputeStatus.fromString, toJson: _disputeStatusToJson)
    required DisputeStatus status,
    String? resolution,
    dynamic buyerEvidence,
    dynamic sellerEvidence,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? resolvedAt,
    UserEntity? openedBy,
  }) = _DisputeEntity;

  factory DisputeEntity.fromJson(Map<String, dynamic> json) =>
      _$DisputeEntityFromJson(json);

  bool get isOpen =>
      status == DisputeStatus.open ||
      status == DisputeStatus.awaitingSeller ||
      status == DisputeStatus.awaitingBuyer;
  bool get isResolved => status == DisputeStatus.resolved;
  bool get isCancelled => status == DisputeStatus.cancelled;

  String? get otherUserName => openedBy?.displayName;
  String? get otherUserAvatar => openedBy?.avatarUrl;
}
