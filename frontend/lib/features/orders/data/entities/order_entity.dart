import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';

part 'order_entity.freezed.dart';
part 'order_entity.g.dart';

enum OrderStatus {
  pending,
  confirmed,
  shipped,
  delivered,
  disputed,
  refundPending,
  completed,
  cancelled,
  unknown;

  String get label => switch (this) {
    OrderStatus.pending => 'Pendente',
    OrderStatus.confirmed => 'Confirmado',
    OrderStatus.shipped => 'Entrega em mãos',
    OrderStatus.delivered => 'Entregue',
    OrderStatus.disputed => 'Em Disputa',
    OrderStatus.refundPending => 'Reembolso pendente',
    OrderStatus.completed => 'Concluído',
    OrderStatus.cancelled => 'Cancelado',
    OrderStatus.unknown => 'Desconhecido',
  };

  String toApiString() => switch (this) {
    OrderStatus.pending => 'PENDING',
    OrderStatus.confirmed => 'CONFIRMED',
    OrderStatus.shipped => 'SHIPPED',
    OrderStatus.delivered => 'DELIVERED',
    OrderStatus.disputed => 'DISPUTED',
    OrderStatus.refundPending => 'REFUND_PENDING',
    OrderStatus.completed => 'COMPLETED',
    OrderStatus.cancelled => 'CANCELLED',
    OrderStatus.unknown => 'UNKNOWN',
  };
}

OrderStatus _orderStatusFromJson(String value) => switch (value.toUpperCase()) {
  'PENDING' => OrderStatus.pending,
  'CONFIRMED' => OrderStatus.confirmed,
  'SHIPPED' => OrderStatus.shipped,
  'DELIVERED' => OrderStatus.delivered,
  'DISPUTED' => OrderStatus.disputed,
  'REFUND_PENDING' => OrderStatus.refundPending,
  'COMPLETED' => OrderStatus.completed,
  'CANCELLED' => OrderStatus.cancelled,
  _ => OrderStatus.unknown,
};

enum EscrowStatus {
  held,
  released,
  refunded,
  unknown;

  String get label => switch (this) {
    EscrowStatus.held => 'Em custódia',
    EscrowStatus.released => 'Liberado',
    EscrowStatus.refunded => 'Reembolsado',
    EscrowStatus.unknown => 'Desconhecido',
  };

  String toApiString() => switch (this) {
    EscrowStatus.held => 'HELD',
    EscrowStatus.released => 'RELEASED',
    EscrowStatus.refunded => 'REFUNDED',
    EscrowStatus.unknown => 'UNKNOWN',
  };
}

EscrowStatus _escrowStatusFromJson(String value) =>
    switch (value.toUpperCase()) {
      'HELD' => EscrowStatus.held,
      'RELEASED' => EscrowStatus.released,
      'REFUNDED' => EscrowStatus.refunded,
      _ => EscrowStatus.unknown,
    };

@freezed
abstract class OrderUserInfo with _$OrderUserInfo {
  const OrderUserInfo._();

  const factory OrderUserInfo({
    required String id,
    String? displayName,
    String? avatarUrl,
    @Default(false) bool isVerified,
  }) = _OrderUserInfo;

  factory OrderUserInfo.fromJson(Map<String, dynamic> json) =>
      _$OrderUserInfoFromJson(json);

  String get displayNameOrDefault => displayName ?? 'Usuário';
}

@freezed
abstract class OrderEntity with _$OrderEntity {
  const OrderEntity._();

  const factory OrderEntity({
    required String id,
    required String buyerId,
    required String sellerId,
    required String productId,
    required int amount,
    required int platformFee,
    required int sellerAmount,
    @JsonKey(fromJson: _orderStatusFromJson) required OrderStatus status,
    @JsonKey(fromJson: _escrowStatusFromJson)
    required EscrowStatus escrowStatus,
    required DateTime createdAt,
    DateTime? deliveryConfirmedAt,
    ProductEntity? product,
    OrderUserInfo? buyer,
    OrderUserInfo? seller,
    @Default(<String>[]) List<String> allowedActions,
  }) = _OrderEntity;

  factory OrderEntity.fromJson(Map<String, dynamic> json) =>
      _$OrderEntityFromJson(json);

  bool can(String action) => allowedActions.contains(action);

  double get amountInReais => amount / 100;
  double get platformFeeInReais => platformFee / 100;
  double get sellerAmountInReais => sellerAmount / 100;
  String get formattedAmount => CurrencyUtils.formatCents(amount);
  String get formattedPlatformFee => CurrencyUtils.formatCents(platformFee);
  String get formattedSellerAmount => CurrencyUtils.formatCents(sellerAmount);
  String get shortId => id.length > 8 ? id.substring(0, 8) : id;
}

@freezed
abstract class CanReviewResponse with _$CanReviewResponse {
  const factory CanReviewResponse({
    @Default(false) bool canReview,
    String? reviewType,
    String? reason,
  }) = _CanReviewResponse;

  factory CanReviewResponse.fromJson(Map<String, dynamic> json) =>
      _$CanReviewResponseFromJson(json);
}
