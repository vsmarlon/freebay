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

OrderStatus _orderStatusFromJson(String value) => OrderStatus.values.firstWhere(
  (e) => e.name == value.toLowerCase(),
  orElse: () => OrderStatus.pending,
);

enum EscrowStatus {
  held,
  released,
  refunded;

  String get label => switch (this) {
    EscrowStatus.held => 'Em custódia',
    EscrowStatus.released => 'Liberado',
    EscrowStatus.refunded => 'Reembolsado',
  };

  String toApiString() => name.toUpperCase();
}

EscrowStatus _escrowStatusFromJson(String value) =>
    EscrowStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => EscrowStatus.held,
    );

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
    @JsonKey(fromJson: _orderStatusFromJson) required OrderStatus status,
    @JsonKey(fromJson: _escrowStatusFromJson)
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
