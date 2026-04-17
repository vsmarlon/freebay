import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/data/services/order_service.dart';

final orderServiceProvider = Provider((ref) => OrderService());

class OrderDetailState {
  final bool isLoading;
  final OrderEntity? order;
  final CanReviewResponse? canReviewResponse;
  final String? error;
  final bool isPerformingAction;

  const OrderDetailState({
    this.isLoading = false,
    this.order,
    this.canReviewResponse,
    this.error,
    this.isPerformingAction = false,
  });

  OrderDetailState copyWith({
    bool? isLoading,
    OrderEntity? order,
    CanReviewResponse? canReviewResponse,
    String? error,
    bool? isPerformingAction,
  }) {
    return OrderDetailState(
      isLoading: isLoading ?? this.isLoading,
      order: order ?? this.order,
      canReviewResponse: canReviewResponse ?? this.canReviewResponse,
      error: error,
      isPerformingAction: isPerformingAction ?? this.isPerformingAction,
    );
  }

  bool get canReview => canReviewResponse?.canReview ?? false;
}

class OrderDetailNotifier extends StateNotifier<OrderDetailState> {
  final OrderService _service;
  final String orderId;

  OrderDetailNotifier(this._service, this.orderId)
      : super(const OrderDetailState());

  Future<void> loadOrder() async {
    state = state.copyWith(isLoading: true, error: null);

    final orderResult = await _service.getOrder(orderId);
    final canReviewResult = await _service.canReviewOrder(orderId);

    orderResult.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (order) {
        canReviewResult.fold(
          (_) => state = state.copyWith(
            isLoading: false,
            order: order,
            canReviewResponse: const CanReviewResponse(canReview: false),
          ),
          (canReview) => state = state.copyWith(
            isLoading: false,
            order: order,
            canReviewResponse: canReview,
          ),
        );
      },
    );
  }

  Future<bool> confirmDelivery() async {
    state = state.copyWith(isPerformingAction: true, error: null);

    final result = await _service.confirmDelivery(orderId);
    return result.fold(
      (failure) {
        state = state.copyWith(
          isPerformingAction: false,
          error: failure.message,
        );
        return false;
      },
      (updatedOrder) async {
        state = state.copyWith(
          isPerformingAction: false,
          order: updatedOrder,
        );
        // Reload to refresh canReviewResponse after status change
        await loadOrder();
        return true;
      },
    );
  }

  Future<bool> cancelOrder() async {
    state = state.copyWith(isPerformingAction: true, error: null);

    final result = await _service.cancelOrder(orderId);
    return result.fold(
      (failure) {
        state = state.copyWith(
          isPerformingAction: false,
          error: failure.message,
        );
        return false;
      },
      (updatedOrder) {
        state = state.copyWith(
          isPerformingAction: false,
          order: updatedOrder,
        );
        return true;
      },
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final orderDetailProvider = StateNotifierProvider.autoDispose
    .family<OrderDetailNotifier, OrderDetailState, String>((ref, orderId) {
  return OrderDetailNotifier(ref.watch(orderServiceProvider), orderId);
});

class PurchasesListState {
  final bool isLoading;
  final List<OrderEntity> orders;
  final int total;
  final String? error;
  final bool hasMore;

  const PurchasesListState({
    this.isLoading = false,
    this.orders = const [],
    this.total = 0,
    this.error,
    this.hasMore = true,
  });

  PurchasesListState copyWith({
    bool? isLoading,
    List<OrderEntity>? orders,
    int? total,
    String? error,
    bool? hasMore,
  }) {
    return PurchasesListState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      total: total ?? this.total,
      error: error,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class PurchasesListNotifier extends StateNotifier<PurchasesListState> {
  final OrderService _service;

  PurchasesListNotifier(this._service) : super(const PurchasesListState());

  Future<void> loadPurchases({bool refresh = false}) async {
    if (state.isLoading) return;

    final offset = refresh ? 0 : state.orders.length;
    state = state.copyWith(
      isLoading: true,
      error: null,
      orders: refresh ? [] : state.orders,
    );

    final result = await _service.getMyPurchases(offset: offset);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (response) => state = state.copyWith(
        isLoading: false,
        orders: refresh ? response.orders : [...state.orders, ...response.orders],
        total: response.total,
        hasMore: response.hasMore,
      ),
    );
  }

  Future<void> refresh() => loadPurchases(refresh: true);
}

final purchasesListProvider =
    StateNotifierProvider<PurchasesListNotifier, PurchasesListState>((ref) {
  return PurchasesListNotifier(ref.watch(orderServiceProvider));
});

class SalesListState {
  final bool isLoading;
  final List<OrderEntity> orders;
  final int total;
  final String? error;
  final bool hasMore;

  const SalesListState({
    this.isLoading = false,
    this.orders = const [],
    this.total = 0,
    this.error,
    this.hasMore = true,
  });

  SalesListState copyWith({
    bool? isLoading,
    List<OrderEntity>? orders,
    int? total,
    String? error,
    bool? hasMore,
  }) {
    return SalesListState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      total: total ?? this.total,
      error: error,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class SalesListNotifier extends StateNotifier<SalesListState> {
  final OrderService _service;

  SalesListNotifier(this._service) : super(const SalesListState());

  Future<void> loadSales({bool refresh = false}) async {
    if (state.isLoading) return;

    final offset = refresh ? 0 : state.orders.length;
    state = state.copyWith(
      isLoading: true,
      error: null,
      orders: refresh ? [] : state.orders,
    );

    final result = await _service.getMySales(offset: offset);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (response) => state = state.copyWith(
        isLoading: false,
        orders: refresh ? response.orders : [...state.orders, ...response.orders],
        total: response.total,
        hasMore: response.hasMore,
      ),
    );
  }

  Future<void> refresh() => loadSales(refresh: true);
}

final salesListProvider =
    StateNotifierProvider<SalesListNotifier, SalesListState>((ref) {
  return SalesListNotifier(ref.watch(orderServiceProvider));
});
