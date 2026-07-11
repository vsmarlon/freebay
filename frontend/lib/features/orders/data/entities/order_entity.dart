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
  completed,
  cancelled,
  disputed;

  static OrderStatus fromString(String value) => switch (value.toUpperCase()) {
    'PENDING' => OrderStatus.pending,
    'CONFIRMED' => OrderStatus.confirmed,
    'SHIPPED' => OrderStatus.shipped,
    'DELIVERED' => OrderStatus.delivered,
    'COMPLETED' => OrderStatus.completed,
    'CANCELLED' => OrderStatus.cancelled,
    'DISPUTED' => OrderStatus.disputed,
    _ => OrderStatus.pending,
  };

  String get label => switch (this) {
    OrderStatus.pending => 'Pendente',
    OrderStatus.confirmed => 'Confirmado',
    OrderStatus.shipped => 'Enviado',
    OrderStatus.delivered => 'Entregue',
    OrderStatus.completed => 'Concluído',
    OrderStatus.cancelled => 'Cancelado',
    OrderStatus.disputed => 'Em Disputa',
  };

  String toApiString() => name.toUpperCase();
}

enum EscrowStatus {
  held,
  released,
  refunded;

  static EscrowStatus fromString(String value) => switch (value.toUpperCase()) {
    'HELD' => EscrowStatus.held,
    'RELEASED' => EscrowStatus.released,
    'REFUNDED' => EscrowStatus.refunded,
    _ => EscrowStatus.held,
  };

  String get label => switch (this) {
    EscrowStatus.held => 'Em custódia',
    EscrowStatus.released => 'Liberado',
    EscrowStatus.refunded => 'Reembolsado',
  };

  String toApiString() => name.toUpperCase();
}

String _orderStatusToJson(OrderStatus s) => s.toApiString();
String _escrowStatusToJson(EscrowStatus s) => s.toApiString();

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
    @Default(0) int amount,
    @Default(0) int platformFee,
    @Default(0) int sellerAmount,
    @JsonKey(fromJson: OrderStatus.fromString, toJson: _orderStatusToJson)
    required OrderStatus status,
    @JsonKey(fromJson: EscrowStatus.fromString, toJson: _escrowStatusToJson)
    required EscrowStatus escrowStatus,
    required DateTime createdAt,
    DateTime? deliveryConfirmedAt,
    ProductEntity? product,
    OrderUserInfo? buyer,
    OrderUserInfo? seller,
  }) = _OrderEntity;

  factory OrderEntity.fromJson(Map<String, dynamic> json) =>
      _$OrderEntityFromJson(json);

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
