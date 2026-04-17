import 'package:equatable/equatable.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';

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

  String toApiString() {
    return name.toUpperCase();
  }
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
}

class OrderUserInfo extends Equatable {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final bool isVerified;

  const OrderUserInfo({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.isVerified = false,
  });

  String get displayNameOrDefault => displayName ?? 'Usuário';

  factory OrderUserInfo.fromJson(Map<String, dynamic> json) {
    return OrderUserInfo(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, displayName, avatarUrl, isVerified];
}

class OrderEntity extends Equatable {
  final String id;
  final String buyerId;
  final String sellerId;
  final String productId;
  final int amount;
  final int platformFee;
  final int sellerAmount;
  final OrderStatus status;
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

  String get formattedAmount => 'R\$ ${amountInReais.toStringAsFixed(2)}';
  String get formattedPlatformFee =>
      'R\$ ${platformFeeInReais.toStringAsFixed(2)}';
  String get formattedSellerAmount =>
      'R\$ ${sellerAmountInReais.toStringAsFixed(2)}';

  String get shortId => id.length > 8 ? id.substring(0, 8) : id;

  factory OrderEntity.fromJson(Map<String, dynamic> json) {
    return OrderEntity(
      id: json['id'] as String,
      buyerId: json['buyerId'] as String,
      sellerId: json['sellerId'] as String,
      productId: json['productId'] as String,
      amount: json['amount'] as int? ?? 0,
      platformFee: json['platformFee'] as int? ?? 0,
      sellerAmount: json['sellerAmount'] as int? ?? 0,
      status: OrderStatus.fromString(json['status'] as String? ?? 'PENDING'),
      escrowStatus:
          EscrowStatus.fromString(json['escrowStatus'] as String? ?? 'HELD'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      deliveryConfirmedAt: json['deliveryConfirmedAt'] != null
          ? DateTime.parse(json['deliveryConfirmedAt'] as String)
          : null,
      product: json['product'] != null
          ? ProductEntity.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      buyer: json['buyer'] != null
          ? OrderUserInfo.fromJson(json['buyer'] as Map<String, dynamic>)
          : null,
      seller: json['seller'] != null
          ? OrderUserInfo.fromJson(json['seller'] as Map<String, dynamic>)
          : null,
    );
  }

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

class CanReviewResponse extends Equatable {
  final bool canReview;
  final String? reviewType;
  final String? reason;

  const CanReviewResponse({
    required this.canReview,
    this.reviewType,
    this.reason,
  });

  factory CanReviewResponse.fromJson(Map<String, dynamic> json) {
    return CanReviewResponse(
      canReview: json['canReview'] as bool? ?? false,
      reviewType: json['reviewType'] as String?,
      reason: json['reason'] as String?,
    );
  }

  @override
  List<Object?> get props => [canReview, reviewType, reason];
}
