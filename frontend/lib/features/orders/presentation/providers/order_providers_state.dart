import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';

part 'order_providers_state.freezed.dart';

@freezed
abstract class OrderDetailState with _$OrderDetailState {
  const OrderDetailState._();

  const factory OrderDetailState({
    @Default(false) bool isLoading,
    OrderEntity? order,
    CanReviewResponse? canReviewResponse,
    String? error,
    @Default(false) bool isPerformingAction,
  }) = _OrderDetailState;

  bool get canReview => canReviewResponse?.canReview ?? false;
}

@freezed
abstract class PurchasesListState with _$PurchasesListState {
  const factory PurchasesListState({
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default([]) List<OrderEntity> orders,
    String? nextCursor,
    String? error,
    @Default(true) bool hasMore,
  }) = _PurchasesListState;
}

@freezed
abstract class SalesListState with _$SalesListState {
  const factory SalesListState({
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default([]) List<OrderEntity> orders,
    String? nextCursor,
    String? error,
    @Default(true) bool hasMore,
    OrderStatus? selectedStatus,
  }) = _SalesListState;
}
