import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';

part 'order_entity.g.dart';

enum OrderStatus {
  pending,
  confirmed,
  shipped,
  delivered,
  completed,
  cancelled,
  disputed;

  static OrderStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return OrderStatus.pending;
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'SHIPPED':
        return OrderStatus.shipped;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'COMPLETED':
        return OrderStatus.completed;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'DISPUTED':
        return OrderStatus.disputed;
      default:
        return OrderStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pendente';
      case OrderStatus.confirmed:
        return 'Confirmado';
      case OrderStatus.shipped:
        return 'Enviado';
      case OrderStatus.delivered:
        return 'Entregue';
      case OrderStatus.completed:
        return 'Concluído';
      case OrderStatus.cancelled:
        return 'Cancelado';
      case OrderStatus.disputed:
        return 'Em Disputa';
    }
  }

  String toApiString() => name.toUpperCase();
}

enum EscrowStatus {
  held,
  released,
  refunded;

  static EscrowStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'HELD':
        return EscrowStatus.held;
      case 'RELEASED':
        return EscrowStatus.released;
      case 'REFUNDED':
        return EscrowStatus.refunded;
      default:
        return EscrowStatus.held;
    }
  }

  String get label {
    switch (this) {
      case EscrowStatus.held:
        return 'Em custódia';
      case EscrowStatus.released:
        return 'Liberado';
      case EscrowStatus.refunded:
        return 'Reembolsado';
    }
  }

  String toApiString() => name.toUpperCase();
}

@JsonSerializable()
class OrderUserInfo extends Equatable {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  @JsonKey(defaultValue: false)
  final bool isVerified;

  const OrderUserInfo({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.isVerified = false,
  });

  String get displayNameOrDefault => displayName ?? 'Usuário';

  factory OrderUserInfo.fromJson(Map<String, dynamic> json) =>
      _$OrderUserInfoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderUserInfoToJson(this);

  @override
  List<Object?> get props => [id, displayName, avatarUrl, isVerified];
}

@JsonSerializable()
class OrderEntity extends Equatable {
  final String id;
  final String buyerId;
  final String sellerId;
  final String productId;
  @JsonKey(defaultValue: 0)
  final int amount;
  @JsonKey(defaultValue: 0)
  final int platformFee;
  @JsonKey(defaultValue: 0)
  final int sellerAmount;
  @JsonKey(fromJson: OrderStatus.fromString, toJson: _orderStatusToJson)
  final OrderStatus status;
  @JsonKey(fromJson: EscrowStatus.fromString, toJson: _escrowStatusToJson)
  final EscrowStatus escrowStatus;
  final DateTime createdAt;
  final DateTime? deliveryConfirmedAt;
  final ProductEntity? product;
  final OrderUserInfo? buyer;
  final OrderUserInfo? seller;

  const OrderEntity({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.amount,
    required this.platformFee,
    required this.sellerAmount,
    required this.status,
    required this.escrowStatus,
    required this.createdAt,
    this.deliveryConfirmedAt,
    this.product,
    this.buyer,
    this.seller,
  });

  double get amountInReais => amount / 100;
  double get platformFeeInReais => platformFee / 100;
  double get sellerAmountInReais => sellerAmount / 100;

  String get formattedAmount => CurrencyUtils.formatCents(amount);
  String get formattedPlatformFee => CurrencyUtils.formatCents(platformFee);
  String get formattedSellerAmount => CurrencyUtils.formatCents(sellerAmount);

  String get shortId => id.length > 8 ? id.substring(0, 8) : id;

  factory OrderEntity.fromJson(Map<String, dynamic> json) =>
      _$OrderEntityFromJson(json);

  Map<String, dynamic> toJson() => _$OrderEntityToJson(this);

  @override
  List<Object?> get props => [
        id,
        buyerId,
        sellerId,
        productId,
        amount,
        platformFee,
        sellerAmount,
        status,
        escrowStatus,
        createdAt,
        deliveryConfirmedAt,
        product,
        buyer,
        seller,
      ];
}

String _orderStatusToJson(OrderStatus status) => status.toApiString();
String _escrowStatusToJson(EscrowStatus status) => status.toApiString();

@JsonSerializable()
class CanReviewResponse extends Equatable {
  @JsonKey(defaultValue: false)
  final bool canReview;
  final String? reviewType;
  final String? reason;

  const CanReviewResponse({
    required this.canReview,
    this.reviewType,
    this.reason,
  });

  factory CanReviewResponse.fromJson(Map<String, dynamic> json) =>
      _$CanReviewResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CanReviewResponseToJson(this);

  @override
  List<Object?> get props => [canReview, reviewType, reason];
}
